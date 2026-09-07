//! Typed settings: read current values from config/*.lua, apply changes
//! both live (via `hyprctl eval`, which runs Lua directly against the
//! running compositor) and persisted (patched into the same .lua file the
//! value came from), using the exact same Lua value syntax for both so
//! they can never drift apart.

use crate::{config_writer, hyprctl};
use anyhow::Result;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Kind {
    Bool,
    Int,
    Float,
    Str,
    ChoiceStr,
    ChoiceInt,
}

#[derive(Debug, Clone, PartialEq)]
pub enum Value {
    Bool(bool),
    Int(i64),
    Float(f64),
    Str(String),
}

impl Value {
    pub fn as_bool(&self) -> bool {
        matches!(self, Value::Bool(true))
    }
    pub fn as_f64(&self) -> f64 {
        match self {
            Value::Int(n) => *n as f64,
            Value::Float(f) => *f,
            _ => 0.0,
        }
    }
    pub fn as_str(&self) -> &str {
        match self {
            Value::Str(s) => s.as_str(),
            _ => "",
        }
    }
}

fn lua_to_py(raw: &str, kind: Kind) -> Value {
    let raw = raw.trim().trim_end_matches(',').trim();
    match kind {
        Kind::Bool => Value::Bool(raw == "true"),
        Kind::Str | Kind::ChoiceStr => {
            let s = if raw.len() >= 2 && raw.starts_with('"') && raw.ends_with('"') {
                raw[1..raw.len() - 1].to_string()
            } else {
                raw.to_string()
            };
            Value::Str(s)
        }
        Kind::ChoiceInt => {
            let n = raw.parse::<f64>().unwrap_or(0.0) as i64;
            Value::Str(n.to_string())
        }
        Kind::Int => Value::Int(raw.parse::<f64>().unwrap_or(0.0) as i64),
        Kind::Float => Value::Float(raw.parse::<f64>().unwrap_or(0.0)),
    }
}

fn py_to_lua(value: &Value, kind: Kind) -> String {
    match kind {
        Kind::Bool => if value.as_bool() { "true" } else { "false" }.to_string(),
        Kind::Str | Kind::ChoiceStr => format!("\"{}\"", value.as_str()),
        Kind::ChoiceInt => value.as_str().parse::<i64>().unwrap_or(0).to_string(),
        Kind::Int => (value.as_f64() as i64).to_string(),
        Kind::Float => {
            let f = value.as_f64();
            if f.fract() == 0.0 {
                format!("{f:.1}")
            } else {
                format!("{f}")
            }
        }
    }
}

fn wrap_eval(path: &[&str], key: &str, lua_value: &str) -> String {
    let mut inner = format!("{key} = {lua_value}");
    for name in path.iter().rev() {
        inner = format!("{name} = {{ {inner} }}");
    }
    format!("hl.config({{ {inner} }})")
}

#[derive(Debug, Clone)]
pub struct SettingSpec {
    /// Stable identifier; not shown in the UI but kept for future use
    /// (search-by-key, config export/diffing).
    #[allow(dead_code)]
    pub key: &'static str,
    pub label: &'static str,
    pub file: &'static str,
    pub lua_path: &'static [&'static str],
    pub lua_key: &'static str,
    pub kind: Kind,
    pub subtitle: &'static str,
    pub min: f64,
    pub max: f64,
    pub step: f64,
    pub digits: usize,
    pub choices: &'static [&'static str],
    pub is_color: bool,
}

impl SettingSpec {
    pub const fn new(
        key: &'static str,
        label: &'static str,
        file: &'static str,
        lua_path: &'static [&'static str],
        lua_key: &'static str,
        kind: Kind,
    ) -> Self {
        SettingSpec {
            key,
            label,
            file,
            lua_path,
            lua_key,
            kind,
            subtitle: "",
            min: 0.0,
            max: 100.0,
            step: 1.0,
            digits: 0,
            choices: &[],
            is_color: false,
        }
    }

    pub const fn subtitle(mut self, s: &'static str) -> Self {
        self.subtitle = s;
        self
    }
    pub const fn range(mut self, min: f64, max: f64, step: f64) -> Self {
        self.min = min;
        self.max = max;
        self.step = step;
        self
    }
    pub const fn digits(mut self, d: usize) -> Self {
        self.digits = d;
        self
    }
    pub const fn choices(mut self, c: &'static [&'static str]) -> Self {
        self.choices = c;
        self
    }
    pub const fn color(mut self) -> Self {
        self.is_color = true;
        self
    }

    pub fn get(&self) -> Result<Value> {
        let raw = config_writer::read_key(self.file, self.lua_path, self.lua_key)?;
        Ok(lua_to_py(&raw, self.kind))
    }

    pub fn set(&self, value: &Value) -> Result<()> {
        let lua_value = py_to_lua(value, self.kind);
        let eval_code = wrap_eval(self.lua_path, self.lua_key, &lua_value);
        hyprctl::eval_lua(&eval_code)?;
        config_writer::patch_file(self.file, self.lua_path, self.lua_key, &lua_value)?;
        Ok(())
    }

    /// Cycle a choice_str/choice_int spec's value by `delta` positions.
    pub fn cycle_choice(&self, current: &str, delta: i32) -> Option<String> {
        let idx = self.choices.iter().position(|c| *c == current)? as i32;
        let len = self.choices.len() as i32;
        let next = ((idx + delta) % len + len) % len;
        Some(self.choices[next as usize].to_string())
    }
}

use Kind::*;

pub fn appearance_gaps_borders() -> Vec<SettingSpec> {
    vec![
        SettingSpec::new("gaps_in", "Inner gaps", "decorations.lua", &["general"], "gaps_in", Int).range(0.0, 40.0, 1.0),
        SettingSpec::new("gaps_out", "Outer gaps", "decorations.lua", &["general"], "gaps_out", Int).range(0.0, 60.0, 1.0),
        SettingSpec::new("border_size", "Border size", "decorations.lua", &["general"], "border_size", Int).range(0.0, 20.0, 1.0),
        SettingSpec::new("resize_on_border", "Resize by dragging borders", "decorations.lua", &["general"], "resize_on_border", Bool)
            .subtitle("Click and drag on a window's border or gap to resize it"),
        SettingSpec::new("allow_tearing", "Allow tearing", "decorations.lua", &["general"], "allow_tearing", Bool)
            .subtitle("See wiki.hypr.land/Configuring/Tearing before enabling"),
        SettingSpec::new("layout", "Tiling layout", "decorations.lua", &["general"], "layout", ChoiceStr)
            .choices(&["dwindle", "master"]),
    ]
}

pub fn appearance_corners_opacity() -> Vec<SettingSpec> {
    vec![
        SettingSpec::new("rounding", "Corner rounding", "decorations.lua", &["decoration"], "rounding", Int).range(0.0, 40.0, 1.0),
        SettingSpec::new("rounding_power", "Rounding power", "decorations.lua", &["decoration"], "rounding_power", Float)
            .range(1.0, 10.0, 0.1)
            .digits(2)
            .subtitle("Higher = more square-ish rounded corners"),
        SettingSpec::new("active_opacity", "Active window opacity", "decorations.lua", &["decoration"], "active_opacity", Float)
            .range(0.0, 1.0, 0.01)
            .digits(2),
        SettingSpec::new("inactive_opacity", "Inactive window opacity", "decorations.lua", &["decoration"], "inactive_opacity", Float)
            .range(0.0, 1.0, 0.01)
            .digits(2),
    ]
}

pub fn appearance_colors() -> Vec<SettingSpec> {
    vec![
        SettingSpec::new("inactive_border", "Inactive border color", "decorations.lua", &["general", "col"], "inactive_border", Str)
            .subtitle("rgba(RRGGBBAA) or rgb(RRGGBB)")
            .color(),
    ]
}

pub fn appearance_shadow() -> Vec<SettingSpec> {
    vec![
        SettingSpec::new("shadow_enabled", "Enable shadows", "decorations.lua", &["decoration", "shadow"], "enabled", Bool),
        SettingSpec::new("shadow_range", "Shadow range", "decorations.lua", &["decoration", "shadow"], "range", Int).range(0.0, 50.0, 1.0),
        SettingSpec::new("shadow_render_power", "Shadow render power", "decorations.lua", &["decoration", "shadow"], "render_power", Int)
            .range(1.0, 4.0, 1.0),
        SettingSpec::new("shadow_color", "Shadow color", "decorations.lua", &["decoration", "shadow"], "color", Str).color(),
    ]
}

pub fn appearance_blur() -> Vec<SettingSpec> {
    vec![
        SettingSpec::new("blur_enabled", "Enable blur", "decorations.lua", &["decoration", "blur"], "enabled", Bool),
        SettingSpec::new("blur_size", "Blur size", "decorations.lua", &["decoration", "blur"], "size", Int).range(1.0, 20.0, 1.0),
        SettingSpec::new("blur_passes", "Blur passes", "decorations.lua", &["decoration", "blur"], "passes", Int).range(1.0, 10.0, 1.0),
        SettingSpec::new("blur_vibrancy", "Vibrancy", "decorations.lua", &["decoration", "blur"], "vibrancy", Float)
            .range(0.0, 1.0, 0.01)
            .digits(4),
    ]
}

pub fn input_keyboard() -> Vec<SettingSpec> {
    vec![
        SettingSpec::new("kb_layout", "Keyboard layout", "inputs.lua", &["input"], "kb_layout", Str).subtitle("e.g. us, gb, de"),
        SettingSpec::new("kb_variant", "Keyboard variant", "inputs.lua", &["input"], "kb_variant", Str),
        SettingSpec::new("kb_model", "Keyboard model", "inputs.lua", &["input"], "kb_model", Str),
        SettingSpec::new("kb_options", "Keyboard options", "inputs.lua", &["input"], "kb_options", Str).subtitle("e.g. caps:ctrl_modifier"),
        SettingSpec::new("kb_rules", "Keyboard rules", "inputs.lua", &["input"], "kb_rules", Str),
    ]
}

pub fn input_mouse() -> Vec<SettingSpec> {
    vec![
        SettingSpec::new("sensitivity", "Pointer sensitivity", "inputs.lua", &["input"], "sensitivity", Float)
            .range(-1.0, 1.0, 0.05)
            .digits(2),
        SettingSpec::new("accel_profile", "Acceleration profile", "inputs.lua", &["input"], "accel_profile", ChoiceStr)
            .choices(&["flat", "adaptive"]),
        SettingSpec::new("follow_mouse", "Focus follows mouse", "inputs.lua", &["input"], "follow_mouse", ChoiceInt)
            .choices(&["0", "1", "2", "3"])
            .subtitle("0=disabled, 1=always, 2=only on hover, 3=on hover unless changed by keyboard"),
    ]
}

pub fn input_touchpad() -> Vec<SettingSpec> {
    vec![SettingSpec::new(
        "natural_scroll",
        "Natural scrolling",
        "inputs.lua",
        &["input", "touchpad"],
        "natural_scroll",
        Bool,
    )]
}

pub fn layout_misc() -> Vec<SettingSpec> {
    vec![
        SettingSpec::new("preserve_split", "Preserve split (dwindle)", "misc.lua", &["dwindle"], "preserve_split", Bool),
        SettingSpec::new("new_status", "New window status (master)", "misc.lua", &["master"], "new_status", ChoiceStr)
            .choices(&["master", "slave"]),
        SettingSpec::new("force_default_wallpaper", "Default wallpaper", "misc.lua", &["misc"], "force_default_wallpaper", ChoiceInt)
            .choices(&["-1", "0", "1"])
            .subtitle("-1=random, 0/1=force a specific built-in wallpaper"),
        SettingSpec::new("disable_hyprland_logo", "Disable Hyprland logo background", "misc.lua", &["misc"], "disable_hyprland_logo", Bool),
        SettingSpec::new("zoom_rigid", "Rigid cursor zoom", "decorations.lua", &["cursor"], "zoom_rigid", Bool)
            .subtitle("Keep cursor centered while zoomed (moving the mouse pans the view)"),
        SettingSpec::new("force_zero_scaling", "Force zero XWayland scaling", "decorations.lua", &["xwayland"], "force_zero_scaling", Bool),
    ]
}
