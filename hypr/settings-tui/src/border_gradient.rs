//! Read/write general.col.active_border, the one setting that's a braced
//! Lua table (`{ colors = { "rgba(...)", ... }, angle = N }`) rather than a
//! scalar, so it needs its own get/set instead of a generic SettingSpec.

use crate::config_writer;
use crate::hyprctl;
use anyhow::Result;
use regex::Regex;

const FILE: &str = "decorations.lua";
const PATH: &[&str] = &["general", "col"];
const KEY: &str = "active_border";

#[derive(Debug, Clone)]
pub struct BorderGradient {
    pub colors: Vec<String>,
    pub angle: i64,
}

pub fn get_active_border() -> Result<BorderGradient> {
    let raw = config_writer::read_key(FILE, PATH, KEY)?;
    let color_re = Regex::new(r#""([^"]+)""#).unwrap();
    let colors: Vec<String> = color_re.captures_iter(&raw).map(|c| c[1].to_string()).collect();
    let angle_re = Regex::new(r"angle\s*=\s*(\d+)").unwrap();
    let angle = angle_re.captures(&raw).and_then(|c| c[1].parse().ok()).unwrap_or(0);
    Ok(BorderGradient {
        colors: if colors.is_empty() { vec!["rgba(ffffffff)".to_string()] } else { colors },
        angle,
    })
}

fn lua_value(g: &BorderGradient) -> String {
    let colors = g.colors.iter().map(|c| format!("\"{c}\"")).collect::<Vec<_>>().join(", ");
    format!("{{ colors = {{ {colors} }}, angle = {} }}", g.angle)
}

pub fn set_active_border(g: &BorderGradient) -> Result<()> {
    let value = lua_value(g);
    hyprctl::eval_lua(&format!("hl.config({{ general = {{ col = {{ {KEY} = {value} }} }} }})"))?;
    config_writer::patch_file(FILE, PATH, KEY, &value)
}
