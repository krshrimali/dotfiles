"""Read/write individual `hl.animation({...})` calls in config/animations.lua.

Each call requires its full field set on every update (Hyprland's `hl.animation`
Lua binding rejects a partial table — "missing required field") so writes here
always resupply enabled/speed/bezier/style together, merged with whatever was
already there.
"""
from __future__ import annotations

import re
from dataclasses import dataclass

from . import config_writer, hyprctl, store

ANIMATIONS_FILE = "animations.lua"

ANIMATIONS_ENABLED = store.SettingSpec(
    "animations_enabled", "Enable animations", ANIMATIONS_FILE, ["animations"], "enabled", "bool"
)

# Display order + friendly labels for the leaves this config actually sets.
LEAVES = [
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
]


@dataclass
class AnimationLeaf:
    leaf: str
    label: str
    enabled: bool
    speed: float
    bezier: str
    style: str = ""


def _field(call_text: str, name: str):
    m = re.search(rf'\b{name}\s*=\s*("(?:[^"\\]|\\.)*"|[\w.]+)', call_text)
    if not m:
        return None
    v = m.group(1)
    return v[1:-1] if v.startswith('"') else v


def parse_animations() -> list[AnimationLeaf]:
    path = config_writer.CONFIG_DIR / ANIMATIONS_FILE
    text = path.read_text()
    out = []
    labels = dict(LEAVES)
    for m in re.finditer(r'hl\.animation\(\{\s*leaf\s*=\s*"([^"]+)"', text):
        leaf = m.group(1)
        open_paren = text.index("(", m.start())
        depth, i = 0, open_paren
        while i < len(text):
            if text[i] == "(":
                depth += 1
            elif text[i] == ")":
                depth -= 1
                if depth == 0:
                    break
            i += 1
        call = text[m.start() : i + 1]
        out.append(
            AnimationLeaf(
                leaf=leaf,
                label=labels.get(leaf, leaf),
                enabled=_field(call, "enabled") == "true",
                speed=float(_field(call, "speed") or 0),
                bezier=_field(call, "bezier") or "",
                style=_field(call, "style") or "",
            )
        )
    order = {leaf: i for i, (leaf, _) in enumerate(LEAVES)}
    out.sort(key=lambda a: order.get(a.leaf, 999))
    return out


def _eval_call(a: AnimationLeaf) -> str:
    parts = [
        f'leaf = "{a.leaf}"',
        f"enabled = {'true' if a.enabled else 'false'}",
        f"speed = {a.speed}",
        f'bezier = "{a.bezier}"',
    ]
    if a.style:
        parts.append(f'style = "{a.style}"')
    return "hl.animation({ " + ", ".join(parts) + " })"


def set_animation(a: AnimationLeaf) -> None:
    hyprctl.eval_lua(_eval_call(a))
    kwargs = {"enabled": "true" if a.enabled else "false", "speed": a.speed}
    config_writer.set_animation(ANIMATIONS_FILE, a.leaf, **kwargs)
