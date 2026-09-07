//! Read/write individual `hl.animation({...})` calls in config/animations.lua.
//!
//! Each call requires its full field set on every update (Hyprland's
//! `hl.animation` Lua binding rejects a partial table — "missing required
//! field") so writes here always resupply enabled/speed/bezier/style
//! together, merged with whatever was already there.

use crate::config_writer::{self, config_dir, find_close};
use crate::hyprctl;
use crate::store::{SettingSpec, Kind};
use anyhow::Result;
use regex::Regex;
use std::fs;

pub const ANIMATIONS_FILE: &str = "animations.lua";

pub fn animations_enabled_spec() -> SettingSpec {
    SettingSpec::new("animations_enabled", "Enable animations", ANIMATIONS_FILE, &["animations"], "enabled", Kind::Bool)
}

const LEAVES: &[(&str, &str)] = &[
    ("global", "Global"),
    ("border", "Border"),
    ("windows", "Windows"),
    ("windowsIn", "Windows in"),
    ("windowsOut", "Windows out"),
    ("fadeIn", "Fade in"),
    ("fadeOut", "Fade out"),
    ("fade", "Fade"),
    ("layers", "Layers"),
    ("layersIn", "Layers in"),
    ("layersOut", "Layers out"),
    ("fadeLayersIn", "Fade layers in"),
    ("fadeLayersOut", "Fade layers out"),
    ("workspaces", "Workspaces"),
    ("workspacesIn", "Workspaces in"),
    ("workspacesOut", "Workspaces out"),
    ("zoomFactor", "Zoom factor"),
];

#[derive(Debug, Clone)]
pub struct AnimationLeaf {
    pub leaf: String,
    pub label: String,
    pub enabled: bool,
    pub speed: f64,
    pub bezier: String,
    pub style: String,
}

fn field(call: &str, name: &str) -> Option<String> {
    let pattern = format!(r#"\b{}\s*=\s*("(?:[^"\\]|\\.)*"|[\w.]+)"#, name);
    let re = Regex::new(&pattern).ok()?;
    let m = re.captures(call)?;
    let v = m.get(1)?.as_str();
    Some(if v.starts_with('"') { v[1..v.len() - 1].to_string() } else { v.to_string() })
}

pub fn parse_animations() -> Result<Vec<AnimationLeaf>> {
    let path = config_dir().join(ANIMATIONS_FILE);
    let text = fs::read_to_string(&path)?;
    let labels: std::collections::HashMap<&str, &str> = LEAVES.iter().copied().collect();

    let mut out = Vec::new();
    let re = Regex::new(r#"hl\.animation\(\{\s*leaf\s*=\s*"([^"]+)""#)?;
    for m in re.captures_iter(&text) {
        let whole = m.get(0).unwrap();
        let leaf = m.get(1).unwrap().as_str().to_string();
        let open_paren = whole.start() + text[whole.start()..].find('(').unwrap();
        let close = find_close(&text, open_paren)?;
        let call = &text[whole.start()..=close];
        out.push(AnimationLeaf {
            label: labels.get(leaf.as_str()).copied().unwrap_or(&leaf).to_string(),
            enabled: field(call, "enabled").as_deref() == Some("true"),
            speed: field(call, "speed").and_then(|s| s.parse().ok()).unwrap_or(0.0),
            bezier: field(call, "bezier").unwrap_or_default(),
            style: field(call, "style").unwrap_or_default(),
            leaf,
        });
    }
    let order: std::collections::HashMap<&str, usize> = LEAVES.iter().enumerate().map(|(i, (l, _))| (*l, i)).collect();
    out.sort_by_key(|a| order.get(a.leaf.as_str()).copied().unwrap_or(999));
    Ok(out)
}

fn eval_call(a: &AnimationLeaf) -> String {
    let mut parts = vec![
        format!("leaf = \"{}\"", a.leaf),
        format!("enabled = {}", if a.enabled { "true" } else { "false" }),
        format!("speed = {}", a.speed),
        format!("bezier = \"{}\"", a.bezier),
    ];
    if !a.style.is_empty() {
        parts.push(format!("style = \"{}\"", a.style));
    }
    format!("hl.animation({{ {} }})", parts.join(", "))
}

pub fn set_animation(a: &AnimationLeaf) -> Result<()> {
    hyprctl::eval_lua(&eval_call(a))?;
    config_writer::set_animation_fields(
        ANIMATIONS_FILE,
        &a.leaf,
        &[("enabled", if a.enabled { "true".to_string() } else { "false".to_string() }), ("speed", a.speed.to_string())],
    )
}
