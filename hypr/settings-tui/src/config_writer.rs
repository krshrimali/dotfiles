//! Targeted, comment-preserving edits to the config/*.lua files.
//!
//! We deliberately don't write a full Lua parser. Every file this module
//! touches consists of simple `key = value` assignments inside `name = { ... }`
//! tables (optionally nested), or single-line `hl.animation({ ... })` calls.
//! We locate the relevant block or call with a balanced-bracket scan and
//! substitute just the value, leaving comments and formatting elsewhere in
//! the file untouched.
//!
//! The scan skips over `--` line comments and quoted strings so a stray
//! bracket-like character inside either (e.g. an apostrophe in a comment)
//! can't desync the depth count.

use anyhow::{bail, Context, Result};
use regex::Regex;
use std::fs;
use std::path::{Path, PathBuf};

pub fn config_dir() -> PathBuf {
    dirs_home().join(".config/hypr/config")
}

fn dirs_home() -> PathBuf {
    std::env::var_os("HOME").map(PathBuf::from).expect("HOME not set")
}

fn backup(path: &Path) -> Result<()> {
    let mut bak = path.as_os_str().to_owned();
    bak.push(".bak");
    let bak = PathBuf::from(bak);
    if !bak.exists() {
        fs::copy(path, &bak)?;
    }
    Ok(())
}

/// Scan forward from `open_idx` (which must point at an opening bracket)
/// and return the byte index of its matching closing bracket, skipping
/// `--` line comments and quoted strings.
pub(crate) fn find_close(text: &str, open_idx: usize) -> Result<usize> {
    let chars: Vec<(usize, char)> = text.char_indices().collect();
    let start = chars
        .iter()
        .position(|&(i, _)| i == open_idx)
        .context("open index is not on a char boundary")?;

    let mut depth: i32 = 0;
    let mut in_str: Option<char> = None;
    let mut idx = start;
    while idx < chars.len() {
        let (byte_i, c) = chars[idx];
        if let Some(q) = in_str {
            if c == '\\' {
                idx += 2;
                continue;
            }
            if c == q {
                in_str = None;
            }
        } else if c == '-' && chars.get(idx + 1).map(|&(_, c2)| c2) == Some('-') {
            while idx < chars.len() && chars[idx].1 != '\n' {
                idx += 1;
            }
            continue;
        } else if c == '"' || c == '\'' {
            in_str = Some(c);
        } else if c == '(' || c == '[' || c == '{' {
            depth += 1;
        } else if c == ')' || c == ']' || c == '}' {
            depth -= 1;
            if depth == 0 {
                return Ok(byte_i);
            }
        }
        idx += 1;
    }
    bail!("unbalanced brackets")
}

/// Find `name = { ... }` in `text` and return (index of '{', index of '}').
fn find_block(text: &str, name: &str) -> Result<(usize, usize)> {
    let pattern = format!(r"\b{}\s*=\s*\{{", regex::escape(name));
    let re = Regex::new(&pattern)?;
    let m = re.find(text).with_context(|| format!("block {name:?} not found"))?;
    let open_idx = m.end() - 1;
    let close_idx = find_close(text, open_idx)?;
    Ok((open_idx, close_idx))
}

/// Narrow `text` down to the nested table described by `path`, returning
/// (index of its '{', index of its '}'), both absolute offsets into `text`.
fn block_span(text: &str, path: &[&str]) -> Result<(usize, usize)> {
    let mut span = (0usize, text.len());
    for name in path {
        let seg = &text[span.0..span.1];
        let (open_idx, close_idx) = find_block(seg, name)?;
        span = (span.0 + open_idx, span.0 + close_idx);
    }
    Ok(span)
}

/// Return the raw (unparsed) Lua source of `key`'s value inside `path`.
pub fn get_key(text: &str, path: &[&str], key: &str) -> Result<String> {
    let (open_idx, close_idx) = block_span(text, path)?;
    let block = &text[open_idx..close_idx];
    let pattern = format!(r"\b{}\s*=\s*", regex::escape(key));
    let re = Regex::new(&pattern)?;
    let m = re
        .find(block)
        .with_context(|| format!("key {key:?} not found in block {path:?}"))?;
    let val_start = m.end();
    if block[val_start..].starts_with('{') {
        let close = find_close(block, val_start)?;
        Ok(block[val_start..=close].to_string())
    } else {
        let rest = &block[val_start..];
        let end_rel = rest.find(['\n', ',']).unwrap_or(rest.len());
        Ok(rest[..end_rel].to_string())
    }
}

/// Set `key = value` inside the nested table described by `path`. `value`
/// is literal Lua source (already quoted if it's meant to be a string).
pub fn set_key(text: &str, path: &[&str], key: &str, value: &str) -> Result<String> {
    let (open_idx, close_idx) = block_span(text, path)?;
    let block = &text[open_idx..close_idx];
    let pattern = format!(r"\b{}\s*=\s*", regex::escape(key));
    let re = Regex::new(&pattern)?;
    let m = re
        .find(block)
        .with_context(|| format!("key {key:?} not found in block {path:?}"))?;
    let val_start = m.end();
    let val_end = if block[val_start..].starts_with('{') {
        find_close(block, val_start)? + 1
    } else {
        let rest = &block[val_start..];
        val_start + rest.find(['\n', ',']).unwrap_or(rest.len())
    };

    let mut new_block = String::with_capacity(block.len() + value.len());
    new_block.push_str(&block[..m.start()]);
    new_block.push_str(key);
    new_block.push_str(" = ");
    new_block.push_str(value);
    new_block.push_str(&block[val_end..]);

    let mut result = String::with_capacity(text.len() + value.len());
    result.push_str(&text[..open_idx]);
    result.push_str(&new_block);
    result.push_str(&text[close_idx..]);
    Ok(result)
}

pub fn read_key(filename: &str, path: &[&str], key: &str) -> Result<String> {
    let text = fs::read_to_string(config_dir().join(filename))?;
    get_key(&text, path, key)
}

pub fn patch_file(filename: &str, path: &[&str], key: &str, value: &str) -> Result<()> {
    let file_path = config_dir().join(filename);
    let text = fs::read_to_string(&file_path)?;
    let new_text = set_key(&text, path, key, value)?;
    if new_text != text {
        backup(&file_path)?;
        fs::write(&file_path, new_text)?;
    }
    Ok(())
}

/// Patch a single field inside a specific `hl.animation({ leaf = "<leaf>", ... })`
/// call. Every field this touches (enabled/speed) must be resupplied together
/// by the caller — Hyprland's Lua binding rejects a partial table.
pub fn set_animation_fields(filename: &str, leaf: &str, fields: &[(&str, String)]) -> Result<()> {
    let file_path = config_dir().join(filename);
    let text = fs::read_to_string(&file_path)?;

    let pattern = format!(r#"hl\.animation\(\{{\s*leaf\s*=\s*"{}""#, regex::escape(leaf));
    let re = Regex::new(&pattern)?;
    let m = re
        .find(&text)
        .with_context(|| format!("animation {leaf:?} not found"))?;
    let open_paren = text[m.start()..].find('(').unwrap() + m.start();
    let call_end = find_close(&text, open_paren)? + 1;
    let mut call = text[m.start()..call_end].to_string();

    for (key, value) in fields {
        let pat = format!(r"(\b{}\s*=\s*)[^,}}]+", regex::escape(key));
        let re = Regex::new(&pat)?;
        if re.is_match(&call) {
            call = re.replace(&call, |caps: &regex::Captures| format!("{}{}", &caps[1], value)).into_owned();
        } else {
            let trimmed = call.trim_end();
            let without_close = &trimmed[..trimmed.len() - 2];
            call = format!("{} , {} = {} }})", without_close.trim_end(), key, value);
        }
    }

    if call != text[m.start()..call_end] {
        let mut new_text = String::with_capacity(text.len());
        new_text.push_str(&text[..m.start()]);
        new_text.push_str(&call);
        new_text.push_str(&text[call_end..]);
        backup(&file_path)?;
        fs::write(&file_path, new_text)?;
    }
    Ok(())
}
