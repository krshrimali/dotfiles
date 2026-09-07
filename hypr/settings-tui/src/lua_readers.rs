//! Best-effort, read-only extraction of human-readable info from the
//! config/*.lua source files, for the browse-only pages (keybinds,
//! autostart, window rules, workspace assignments).
//!
//! These are NOT a Lua parser — just regex/bracket-depth scans tuned to
//! the specific patterns this config actually uses (hl.bind, hl.exec_cmd,
//! hl.window_rule, hl.layer_rule, workspaceRange). Good enough to browse
//! and search; not guaranteed to handle arbitrary rewrites of these files.

use crate::config_writer::{config_dir, find_close};
use anyhow::Result;
use regex::Regex;
use std::collections::HashMap;
use std::fs;

#[derive(Debug, Clone)]
pub struct Keybind {
    pub combo: String,
    pub action: String,
    pub opts: String,
    pub submap: String,
    pub comment: String,
}

#[derive(Debug, Clone)]
pub struct AutostartEntry {
    pub command: String,
    pub comment: String,
}

#[derive(Debug, Clone)]
pub struct WindowRule {
    pub kind: String,
    pub name: String,
    pub raw: String,
    pub comment: String,
}

#[derive(Debug, Clone)]
pub struct WorkspaceRange {
    pub start: u32,
    pub end: u32,
    pub monitor: String,
}

fn known_vars() -> HashMap<String, String> {
    let mut out = HashMap::from([
        ("TERMINAL".to_string(), "~/.config/hypr/scripts/launch-terminal.sh".to_string()),
        ("FILE_MANAGER".to_string(), "dolphin".to_string()),
        ("MENU".to_string(), "hyprlauncher".to_string()),
        ("BROWSER".to_string(), "google-chrome-stable".to_string()),
        ("MAIN_MOD".to_string(), "SUPER".to_string()),
    ]);
    if let Ok(text) = fs::read_to_string(config_dir().join("variables.lua")) {
        let re = Regex::new(r#"(?m)^(\w+)\s*=\s*"([^"]*)""#).unwrap();
        for cap in re.captures_iter(&text) {
            out.insert(cap[1].to_string(), cap[2].to_string());
        }
    }
    out
}

/// Split `interior` on top-level occurrences of `sep`, respecting nested
/// brackets and quoted strings.
fn split_top_level(interior: &str, sep: char) -> Vec<String> {
    let mut parts = Vec::new();
    let mut depth = 0i32;
    let mut buf = String::new();
    let mut in_str: Option<char> = None;
    let mut chars = interior.chars();
    while let Some(c) = chars.next() {
        if let Some(q) = in_str {
            buf.push(c);
            if c == '\\' {
                if let Some(next) = chars.next() {
                    buf.push(next);
                }
            } else if c == q {
                in_str = None;
            }
            continue;
        }
        match c {
            '"' | '\'' => {
                in_str = Some(c);
                buf.push(c);
            }
            '(' | '[' | '{' => {
                depth += 1;
                buf.push(c);
            }
            ')' | ']' | '}' => {
                depth -= 1;
                buf.push(c);
            }
            c2 if c2 == sep && depth == 0 => {
                parts.push(buf.trim().to_string());
                buf.clear();
            }
            _ => buf.push(c),
        }
    }
    if !buf.trim().is_empty() || !parts.is_empty() {
        parts.push(buf.trim().to_string());
    }
    parts
}

fn humanize_combo(expr: &str) -> String {
    let s = expr.trim().replace("mainMod", "SUPER");
    let re = Regex::new(r#""([^"]*)""#).unwrap();
    let strings: Vec<&str> = re.captures_iter(&s).map(|c| c.get(1).unwrap().as_str()).collect();
    if !strings.is_empty() {
        if s.contains("SUPER") && !s.trim_start().starts_with('"') {
            format!("SUPER{}", strings.concat())
        } else {
            strings.concat()
        }
    } else {
        s
    }
    .trim()
    .to_string()
}

fn humanize_action(expr: &str, vars: &HashMap<String, String>) -> String {
    let mut s = expr.trim().to_string();
    if let Some(stripped) = s.strip_prefix("hl.dsp.") {
        s = stripped.to_string();
    }
    for (var, val) in vars {
        let pat = format!(r"\b{}\b", regex::escape(var));
        if let Ok(re) = Regex::new(&pat) {
            s = re.replace_all(&s, val.as_str()).into_owned();
        }
    }
    s.split_whitespace().collect::<Vec<_>>().join(" ")
}

fn line_starts(text: &str) -> Vec<usize> {
    let mut starts = vec![0usize];
    for (i, c) in text.char_indices() {
        if c == '\n' {
            starts.push(i + 1);
        }
    }
    starts
}

fn line_of(starts: &[usize], byte_idx: usize) -> usize {
    match starts.binary_search(&byte_idx) {
        Ok(i) => i,
        Err(i) => i.saturating_sub(1),
    }
}

fn leading_comments(lines: &[&str], stmt_line: usize) -> String {
    let mut out = Vec::new();
    let mut i = stmt_line as isize - 1;
    while i >= 0 {
        let line = lines[i as usize].trim();
        if let Some(rest) = line.strip_prefix("--") {
            out.insert(0, rest.trim().to_string());
            i -= 1;
        } else {
            break;
        }
    }
    out.join(" ")
}

pub fn parse_keybinds() -> Result<Vec<Keybind>> {
    let path = config_dir().join("binds.lua");
    if !path.exists() {
        return Ok(vec![]);
    }
    let text = fs::read_to_string(&path)?;
    let vars = known_vars();
    let lines: Vec<&str> = text.lines().collect();
    let starts = line_starts(&text);

    let mut consumed: Vec<(usize, usize)> = Vec::new();
    let mut results: Vec<Keybind> = Vec::new();
    let in_consumed = |idx: usize, consumed: &[(usize, usize)]| consumed.iter().any(|&(s, e)| s <= idx && idx < e);

    let bind_call_re = Regex::new(r"hl\.bind\(").unwrap();

    // Submap blocks: hl.define_submap("name", "reset", function() ... end)
    let submap_re = Regex::new(r#"hl\.define_submap\(\s*"([^"]+)""#).unwrap();
    for m in submap_re.captures_iter(&text) {
        let whole = m.get(0).unwrap();
        let name = m.get(1).unwrap().as_str().to_string();
        let paren_idx = whole.start() + text[whole.start()..].find('(').unwrap();
        let close = find_close(&text, paren_idx)?;
        let block_start = whole.start();
        let block_end = close + 1;
        consumed.push((block_start, block_end));
        let block = &text[block_start..block_end];

        for bm in bind_call_re.find_iter(block) {
            let open_idx = bm.end() - 1;
            let close_idx = find_close(block, open_idx)?;
            let interior = &block[open_idx + 1..close_idx];
            let args = split_top_level(interior, ',');
            if args.len() < 2 {
                continue;
            }
            results.push(Keybind {
                combo: humanize_combo(&args[0]),
                action: humanize_action(&args[1], &vars),
                opts: args.get(2).cloned().unwrap_or_default(),
                submap: name.clone(),
                comment: String::new(),
            });
        }
    }

    // The one generated for-loop (workspace switch/move 1-10)
    let loop_re = Regex::new(r"(?s)for i = 1, 10 do\b.*?\nend\b").unwrap();
    if let Some(m) = loop_re.find(&text) {
        consumed.push((m.start(), m.end()));
        results.push(Keybind {
            combo: "SUPER + [0-9]".to_string(),
            action: "~/.config/hypr/scripts/workspace.sh switch <1-10> (generated loop)".to_string(),
            opts: String::new(),
            submap: String::new(),
            comment: "Switch workspaces per focused monitor, i3-style".to_string(),
        });
        results.push(Keybind {
            combo: "SUPER + SHIFT + [0-9]".to_string(),
            action: "~/.config/hypr/scripts/workspace.sh move <1-10> (generated loop)".to_string(),
            opts: String::new(),
            submap: String::new(),
            comment: "Move active window to a workspace".to_string(),
        });
    }

    // Top-level hl.bind(...) calls not already consumed by a submap/loop
    for m in bind_call_re.find_iter(&text) {
        if in_consumed(m.start(), &consumed) {
            continue;
        }
        let open_idx = m.end() - 1;
        let close_idx = find_close(&text, open_idx)?;
        let interior = &text[open_idx + 1..close_idx];
        let args = split_top_level(interior, ',');
        if args.len() < 2 {
            continue;
        }
        let comment = leading_comments(&lines, line_of(&starts, m.start()));
        results.push(Keybind {
            combo: humanize_combo(&args[0]),
            action: humanize_action(&args[1], &vars),
            opts: args.get(2).cloned().unwrap_or_default(),
            submap: String::new(),
            comment,
        });
    }

    Ok(results)
}

pub fn parse_autostart() -> Result<Vec<AutostartEntry>> {
    let path = config_dir().join("autostart.lua");
    if !path.exists() {
        return Ok(vec![]);
    }
    let text = fs::read_to_string(&path)?;
    let re = Regex::new(r#"hl\.exec_cmd\(\s*"((?:[^"\\]|\\.)*)"\s*\)"#).unwrap();
    let mut entries = Vec::new();
    let mut comment_buf: Vec<String> = Vec::new();
    for raw_line in text.lines() {
        let line = raw_line.trim();
        if let Some(rest) = line.strip_prefix("--") {
            comment_buf.push(rest.trim().to_string());
            continue;
        }
        if line.is_empty() {
            comment_buf.clear();
            continue;
        }
        if let Some(cap) = re.captures(line) {
            entries.push(AutostartEntry {
                command: cap[1].to_string(),
                comment: comment_buf.join(" "),
            });
            comment_buf.clear();
        }
    }
    Ok(entries)
}

pub fn parse_window_rules() -> Result<Vec<WindowRule>> {
    let path = config_dir().join("windowrules.lua");
    if !path.exists() {
        return Ok(vec![]);
    }
    let text = fs::read_to_string(&path)?;
    let lines: Vec<&str> = text.lines().collect();
    let starts = line_starts(&text);

    let mut results = Vec::new();
    let rule_re = Regex::new(r"hl\.(window_rule|layer_rule)\(").unwrap();
    for m in rule_re.captures_iter(&text) {
        let whole = m.get(0).unwrap();
        let kind = m.get(1).unwrap().as_str().to_string();
        let open_idx = whole.end() - 1;
        let close_idx = find_close(&text, open_idx)?;
        let raw = text[whole.start()..=close_idx].to_string();
        let name = Regex::new(r#"name\s*=\s*"([^"]+)""#)
            .unwrap()
            .captures(&raw)
            .map(|c| c[1].to_string())
            .unwrap_or_else(|| "(unnamed)".to_string());
        let comment = leading_comments(&lines, line_of(&starts, whole.start()));
        results.push(WindowRule { kind, name, raw, comment });
    }

    let on_re = Regex::new(r#"hl\.on\(\s*"([^"]+)""#).unwrap();
    for m in on_re.captures_iter(&text) {
        let whole = m.get(0).unwrap();
        let event = m.get(1).unwrap().as_str().to_string();
        let paren_idx = whole.start() + text[whole.start()..].find('(').unwrap();
        let close_idx = find_close(&text, paren_idx)?;
        let raw = text[whole.start()..=close_idx].to_string();
        let comment = leading_comments(&lines, line_of(&starts, whole.start()));
        results.push(WindowRule {
            kind: "dynamic".to_string(),
            name: event,
            raw,
            comment,
        });
    }

    results.sort_by_key(|r| text.find(&r.raw[..r.raw.len().min(30)]).unwrap_or(0));
    Ok(results)
}

pub fn parse_workspace_ranges() -> Result<Vec<WorkspaceRange>> {
    let path = config_dir().join("workspaces.lua");
    if !path.exists() {
        return Ok(vec![]);
    }
    let text = fs::read_to_string(&path)?;
    let re = Regex::new(r#"workspaceRange\((\d+),\s*(\d+),\s*"([^"]+)"\)"#).unwrap();
    Ok(re
        .captures_iter(&text)
        .map(|c| WorkspaceRange {
            start: c[1].parse().unwrap_or(0),
            end: c[2].parse().unwrap_or(0),
            monitor: c[3].to_string(),
        })
        .collect())
}

pub fn parse_workspace_rules_raw() -> Result<Vec<String>> {
    let path = config_dir().join("workspaces.lua");
    if !path.exists() {
        return Ok(vec![]);
    }
    let text = fs::read_to_string(&path)?;
    let re = Regex::new(r"hl\.workspace_rule\(").unwrap();
    let mut out = Vec::new();
    for m in re.find_iter(&text) {
        let open_idx = m.end() - 1;
        let close_idx = find_close(&text, open_idx)?;
        out.push(text[m.start()..=close_idx].to_string());
    }
    Ok(out)
}
