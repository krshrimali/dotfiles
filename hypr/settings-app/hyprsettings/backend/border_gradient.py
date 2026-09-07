"""Read/write general.col.active_border, the one setting that's a braced
Lua table (`{ colors = { "rgba(...)", ... }, angle = N }`) rather than a
scalar, so it needs its own get/set instead of a generic SettingSpec.
"""
from __future__ import annotations

import re
from dataclasses import dataclass

from . import config_writer, hyprctl

FILE = "decorations.lua"
PATH = ["general", "col"]
KEY = "active_border"


@dataclass
class BorderGradient:
    colors: list[str]
    angle: int = 0


def get_active_border() -> BorderGradient:
    raw = config_writer.read_key(FILE, PATH, KEY)
    colors = re.findall(r'"([^"]+)"', raw)
    angle_m = re.search(r"angle\s*=\s*(\d+)", raw)
    return BorderGradient(colors=colors or ["rgba(ffffffff)"], angle=int(angle_m.group(1)) if angle_m else 0)


def _lua_value(g: BorderGradient) -> str:
    colors = ", ".join(f'"{c}"' for c in g.colors)
    return f"{{ colors = {{ {colors} }}, angle = {g.angle} }}"


def set_active_border(g: BorderGradient) -> None:
    value = _lua_value(g)
    hyprctl.eval_lua(f"hl.config({{ general = {{ col = {{ {KEY} = {value} }} }} }})")
    config_writer.patch_file(FILE, PATH, KEY, value)
