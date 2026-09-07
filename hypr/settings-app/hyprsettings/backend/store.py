"""Typed settings: read current values from config/*.lua, apply changes both
live (via `hyprctl eval`, which runs Lua directly against the running
compositor) and persisted (patched into the same .lua file the value came
from), using the exact same Lua value syntax for both so they can never
drift apart.
"""
from __future__ import annotations

from dataclasses import dataclass, field

from . import config_writer, hyprctl


def lua_to_py(raw: str, kind: str):
    """`choice_str`/`choice_int` both surface as a plain Python str (for
    matching against a combo box's string choices) even though the
    underlying Lua literal differs — quoted string vs. bare int."""
    raw = raw.strip().rstrip(",").strip()
    if kind == "bool":
        return raw == "true"
    if kind in ("str", "choice_str"):
        if raw.startswith('"') and raw.endswith('"'):
            return raw[1:-1]
        return raw
    if kind == "choice_int":
        return str(int(float(raw)))
    if kind == "int":
        return int(float(raw))
    if kind == "float":
        return float(raw)
    return raw


def py_to_lua(value, kind: str) -> str:
    if kind == "bool":
        return "true" if value else "false"
    if kind in ("str", "choice_str"):
        return f'"{value}"'
    if kind == "choice_int":
        return str(int(value))
    return str(value)


@dataclass
class SettingSpec:
    key: str
    label: str
    file: str
    lua_path: list[str]
    lua_key: str
    kind: str  # "int" | "float" | "bool" | "str" | "choice"
    subtitle: str = ""
    min: float = 0
    max: float = 100
    step: float = 1
    digits: int = 0
    choices: list[str] = field(default_factory=list)
    is_color: bool = False

    def get(self):
        raw = config_writer.read_key(self.file, self.lua_path, self.lua_key)
        return lua_to_py(raw, self.kind)

    def set(self, value) -> None:
        lua_value = py_to_lua(value, self.kind)
        eval_code = _wrap_eval(self.lua_path, self.lua_key, lua_value)
        hyprctl.eval_lua(eval_code)
        config_writer.patch_file(self.file, self.lua_path, self.lua_key, lua_value)


def _wrap_eval(path: list[str], key: str, lua_value: str) -> str:
    inner = f"{key} = {lua_value}"
    for name in reversed(path):
        inner = f"{name} = {{ {inner} }}"
    return f"hl.config({{ {inner} }})"


# ---------------------------------------------------------------------------
# Appearance (config/decorations.lua)
# ---------------------------------------------------------------------------

APPEARANCE_GAPS_BORDERS = [
    SettingSpec("gaps_in", "Inner gaps", "decorations.lua", ["general"], "gaps_in", "int", min=0, max=40),
    SettingSpec("gaps_out", "Outer gaps", "decorations.lua", ["general"], "gaps_out", "int", min=0, max=60),
    SettingSpec("border_size", "Border size", "decorations.lua", ["general"], "border_size", "int", min=0, max=20),
    SettingSpec(
        "resize_on_border", "Resize by dragging borders", "decorations.lua", ["general"],
        "resize_on_border", "bool",
        subtitle="Click and drag on a window's border or gap to resize it",
    ),
    SettingSpec(
        "allow_tearing", "Allow tearing", "decorations.lua", ["general"], "allow_tearing", "bool",
        subtitle="See wiki.hypr.land/Configuring/Tearing before enabling",
    ),
    SettingSpec(
        "layout", "Tiling layout", "decorations.lua", ["general"], "layout", "choice_str",
        choices=["dwindle", "master"],
    ),
]

APPEARANCE_CORNERS_OPACITY = [
    SettingSpec("rounding", "Corner rounding", "decorations.lua", ["decoration"], "rounding", "int", min=0, max=40),
    SettingSpec(
        "rounding_power", "Rounding power", "decorations.lua", ["decoration"], "rounding_power", "float",
        min=1, max=10, step=0.1, digits=2,
        subtitle="Higher = more square-ish rounded corners",
    ),
    SettingSpec(
        "active_opacity", "Active window opacity", "decorations.lua", ["decoration"], "active_opacity", "float",
        min=0, max=1, step=0.01, digits=2,
    ),
    SettingSpec(
        "inactive_opacity", "Inactive window opacity", "decorations.lua", ["decoration"], "inactive_opacity", "float",
        min=0, max=1, step=0.01, digits=2,
    ),
]

APPEARANCE_SHADOW = [
    SettingSpec("shadow_enabled", "Enable shadows", "decorations.lua", ["decoration", "shadow"], "enabled", "bool"),
    SettingSpec("shadow_range", "Shadow range", "decorations.lua", ["decoration", "shadow"], "range", "int", min=0, max=50),
    SettingSpec(
        "shadow_render_power", "Shadow render power", "decorations.lua", ["decoration", "shadow"],
        "render_power", "int", min=1, max=4,
    ),
    SettingSpec("shadow_color", "Shadow color", "decorations.lua", ["decoration", "shadow"], "color", "str", is_color=True),
]

APPEARANCE_COLORS = [
    SettingSpec(
        "inactive_border", "Inactive border color", "decorations.lua", ["general", "col"], "inactive_border", "str",
        subtitle="rgba(RRGGBBAA) or rgb(RRGGBB)", is_color=True,
    ),
]

APPEARANCE_BLUR = [
    SettingSpec("blur_enabled", "Enable blur", "decorations.lua", ["decoration", "blur"], "enabled", "bool"),
    SettingSpec("blur_size", "Blur size", "decorations.lua", ["decoration", "blur"], "size", "int", min=1, max=20),
    SettingSpec("blur_passes", "Blur passes", "decorations.lua", ["decoration", "blur"], "passes", "int", min=1, max=10),
    SettingSpec(
        "blur_vibrancy", "Vibrancy", "decorations.lua", ["decoration", "blur"], "vibrancy", "float",
        min=0, max=1, step=0.01, digits=4,
    ),
]

# ---------------------------------------------------------------------------
# Input (config/inputs.lua)
# ---------------------------------------------------------------------------

INPUT_KEYBOARD = [
    SettingSpec("kb_layout", "Keyboard layout", "inputs.lua", ["input"], "kb_layout", "str", subtitle="e.g. us, gb, de"),
    SettingSpec("kb_variant", "Keyboard variant", "inputs.lua", ["input"], "kb_variant", "str"),
    SettingSpec("kb_model", "Keyboard model", "inputs.lua", ["input"], "kb_model", "str"),
    SettingSpec("kb_options", "Keyboard options", "inputs.lua", ["input"], "kb_options", "str", subtitle="e.g. caps:ctrl_modifier"),
    SettingSpec("kb_rules", "Keyboard rules", "inputs.lua", ["input"], "kb_rules", "str"),
]

INPUT_MOUSE = [
    SettingSpec(
        "sensitivity", "Pointer sensitivity", "inputs.lua", ["input"], "sensitivity", "float",
        min=-1, max=1, step=0.05, digits=2,
    ),
    SettingSpec(
        "accel_profile", "Acceleration profile", "inputs.lua", ["input"], "accel_profile", "choice_str",
        choices=["flat", "adaptive"],
    ),
    SettingSpec(
        "follow_mouse", "Focus follows mouse", "inputs.lua", ["input"], "follow_mouse", "choice_int",
        choices=["0", "1", "2", "3"],
        subtitle="0=disabled, 1=always, 2=only on hover, 3=on hover unless changed by keyboard",
    ),
]

INPUT_TOUCHPAD = [
    SettingSpec(
        "natural_scroll", "Natural scrolling", "inputs.lua", ["input", "touchpad"], "natural_scroll", "bool",
    ),
]

# ---------------------------------------------------------------------------
# Layout & misc (config/decorations.lua + config/misc.lua)
# ---------------------------------------------------------------------------

LAYOUT_MISC = [
    SettingSpec("preserve_split", "Preserve split (dwindle)", "misc.lua", ["dwindle"], "preserve_split", "bool"),
    SettingSpec(
        "new_status", "New window status (master)", "misc.lua", ["master"], "new_status", "choice_str",
        choices=["master", "slave"],
    ),
    SettingSpec(
        "force_default_wallpaper", "Default wallpaper", "misc.lua", ["misc"], "force_default_wallpaper", "choice_int",
        choices=["-1", "0", "1"], subtitle="-1=random, 0/1=force a specific built-in wallpaper",
    ),
    SettingSpec("disable_hyprland_logo", "Disable Hyprland logo background", "misc.lua", ["misc"], "disable_hyprland_logo", "bool"),
    SettingSpec(
        "zoom_rigid", "Rigid cursor zoom", "decorations.lua", ["cursor"], "zoom_rigid", "bool",
        subtitle="Keep cursor centered while zoomed (moving the mouse pans the view)",
    ),
    SettingSpec(
        "force_zero_scaling", "Force zero XWayland scaling", "decorations.lua", ["xwayland"], "force_zero_scaling", "bool",
    ),
]
