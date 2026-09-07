"""Thin wrapper around `hyprctl` for live queries and live-apply.

Persistence to config files is handled separately in config_writer.py —
this module only ever talks to the running compositor.
"""
from __future__ import annotations

import json
import subprocess


class HyprctlError(RuntimeError):
    pass


def _run(args: list[str]) -> str:
    try:
        result = subprocess.run(
            ["hyprctl", *args], capture_output=True, text=True, timeout=5, check=False
        )
    except FileNotFoundError as exc:
        raise HyprctlError("hyprctl not found — is Hyprland running?") from exc
    except subprocess.TimeoutExpired as exc:
        raise HyprctlError("hyprctl timed out") from exc
    if result.returncode != 0:
        raise HyprctlError(result.stderr.strip() or f"hyprctl {' '.join(args)} failed")
    return result.stdout


def query_json(*args: str):
    """Run `hyprctl -j <args>` and return parsed JSON."""
    out = _run(["-j", *args])
    try:
        return json.loads(out)
    except json.JSONDecodeError as exc:
        raise HyprctlError(f"bad JSON from hyprctl {' '.join(args)}: {exc}") from exc


def get_option(path: str):
    """Run `hyprctl getoption <path> -j` and return the scalar value."""
    data = query_json("getoption", path)
    for key in ("int", "float", "str", "bool", "css", "gradient", "vec2"):
        if key in data:
            return data[key]
    return None


def eval_lua(code: str) -> None:
    """Apply config changes live via `hyprctl eval <lua>`.

    This Hyprland instance runs the native Lua config (hyprland.lua), which
    disables the legacy `hyprctl keyword` path ("keyword can't work with
    non-legacy parsers"). `eval` runs the same `hl.config(...)` /
    `hl.animation(...)` calls the config files use, live, against the
    running compositor.
    """
    _run(["eval", code])


def dispatch(*args: str) -> None:
    _run(["dispatch", *args])


def monitors() -> list[dict]:
    return query_json("monitors", "all")


def reload() -> None:
    """Ask Hyprland to reload its config from disk."""
    _run(["reload"])
