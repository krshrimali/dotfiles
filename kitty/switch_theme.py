"""
Kitty theme switcher kitten.

Usage (from kitty.conf map):
    map ctrl+alt+u kitten switch_theme.py dark next
    map ctrl+alt+l kitten switch_theme.py light next
    map ctrl+alt+shift+u kitten switch_theme.py dark prev
    map ctrl+alt+shift+l kitten switch_theme.py light prev
"""

import json
import os

from kitty.constants import config_dir
KITTY_CONFIG_DIR = config_dir
THEMES_DIR = os.path.join(KITTY_CONFIG_DIR, "themes")
STATE_FILE = os.path.join(KITTY_CONFIG_DIR, ".theme_state.json")
CURRENT_THEME_CONF = os.path.join(KITTY_CONFIG_DIR, "current_theme.conf")


def hex_to_luminance(hex_color: str) -> float:
    """Compute relative luminance (0..1) from a hex color string."""
    h = hex_color.lstrip("#")
    if len(h) != 6:
        return 0.0
    r, g, b = int(h[0:2], 16) / 255, int(h[2:4], 16) / 255, int(h[4:6], 16) / 255

    def linearize(c: float) -> float:
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

    return 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b)


def get_background(theme_path: str) -> str | None:
    """Extract the background color from a kitty theme conf file."""
    with open(theme_path) as f:
        for line in f:
            stripped = line.strip()
            if not stripped or stripped.startswith(("#", ";")):
                continue
            parts = stripped.split()
            if len(parts) >= 2 and parts[0] == "background":
                val = parts[1]
                if val.startswith("#"):
                    return val
    return None


def is_dark(theme_path: str) -> bool:
    """Return True if the theme has a dark background (luminance < 0.3)."""
    bg = get_background(theme_path)
    if bg:
        return hex_to_luminance(bg) < 0.3
    return True  # default to dark if unreadable


def get_themes(want_dark: bool) -> list[dict]:
    """Return sorted list of theme dicts matching the dark/light filter."""
    if not os.path.isdir(THEMES_DIR):
        return []
    themes = []
    for fname in sorted(os.listdir(THEMES_DIR)):
        if not fname.endswith(".conf"):
            continue
        path = os.path.join(THEMES_DIR, fname)
        if is_dark(path) == want_dark:
            themes.append({"name": fname[:-5], "path": path})
    return themes


def load_state() -> dict:
    if os.path.exists(STATE_FILE):
        try:
            with open(STATE_FILE) as f:
                return json.load(f)
        except Exception:
            pass
    return {}


def save_state(state: dict) -> None:
    with open(STATE_FILE, "w") as f:
        json.dump(state, f, indent=2)


def apply_theme(theme: dict) -> None:
    """Write the theme to current_theme.conf for persistence across restarts."""
    with open(theme["path"]) as f:
        content = f.read()
    header = f"# Current theme: {theme['name']}\n# Managed by switch_theme.py — do not edit manually\n\n"
    with open(CURRENT_THEME_CONF, "w") as f:
        f.write(header + content)


def main(args: list[str]) -> str:
    # main() must exist; no UI needed — all work done in handle_result
    return ""


from kittens.tui.handler import result_handler  # noqa: E402


@result_handler(no_ui=True)
def handle_result(args: list[str], result: str, target_window_id: int, boss) -> None:
    """
    args[0] = 'dark' | 'light'
    args[1] = 'next' | 'prev'
    """
    # args[0] is the script name (e.g. 'switch_theme.py'), actual args start at 1
    mode = args[1] if len(args) > 1 else "dark"
    direction = args[2] if len(args) > 2 else "next"
    want_dark = mode == "dark"

    themes = get_themes(want_dark)
    if not themes:
        return  # no themes found for this category

    state = load_state()
    state_key = f"current_{mode}"
    current_name = state.get(state_key)

    # Find position of current theme in the filtered list
    current_idx = next(
        (i for i, t in enumerate(themes) if t["name"] == current_name), -1
    )

    if direction == "next":
        next_idx = (current_idx + 1) % len(themes)
    else:
        next_idx = (current_idx - 1) % len(themes)

    theme = themes[next_idx]

    # Apply colors immediately to all windows (and update configured defaults)
    boss.call_remote_control(
        boss.active_window,
        ("set-colors", "--all", "--configured", theme["path"]),
    )

    # Persist for next kitty startup via the include file
    apply_theme(theme)

    # Update state
    state[state_key] = theme["name"]
    save_state(state)
