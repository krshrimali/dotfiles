"""Best-effort, read-only extraction of human-readable info from the
config/*.lua source files, for the browse-only pages (keybinds, autostart,
window rules, workspace assignments).

These are NOT a Lua parser — just regex/bracket-depth scans tuned to the
specific patterns this config actually uses (hl.bind, hl.exec_cmd,
hl.window_rule, hl.layer_rule, workspaceRange). Good enough to browse and
search; not guaranteed to handle arbitrary rewrites of these files.
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path

CONFIG_DIR = Path.home() / ".config" / "hypr" / "config"

KNOWN_VARS = {
    "TERMINAL": "~/.config/hypr/scripts/launch-terminal.sh",
    "FILE_MANAGER": "dolphin",
    "MENU": "hyprlauncher",
    "BROWSER": "google-chrome-stable",
    "MAIN_MOD": "SUPER",
}


def _load_known_vars() -> dict[str, str]:
    variables_path = CONFIG_DIR / "variables.lua"
    if not variables_path.exists():
        return dict(KNOWN_VARS)
    text = variables_path.read_text()
    out = dict(KNOWN_VARS)
    for m in re.finditer(r'^(\w+)\s*=\s*"([^"]*)"', text, re.MULTILINE):
        out[m.group(1)] = m.group(2)
    return out


def _find_close(text: str, open_idx: int) -> int:
    """Given the index of an opening bracket, return the index of its match."""
    depth = 0
    i = open_idx
    in_str: str | None = None
    while i < len(text):
        c = text[i]
        if in_str:
            if c == "\\":
                i += 2
                continue
            if c == in_str:
                in_str = None
        elif c == "-" and text[i : i + 2] == "--":
            nl = text.find("\n", i)
            i = len(text) if nl == -1 else nl
            continue
        elif c in "\"'":
            in_str = c
        elif c in "([{":
            depth += 1
        elif c in ")]}":
            depth -= 1
            if depth == 0:
                return i
        i += 1
    raise ValueError("unbalanced brackets")


def _split_top_level(interior: str, sep: str = ",") -> list[str]:
    parts, depth, buf, in_str = [], 0, [], None
    i = 0
    while i < len(interior):
        c = interior[i]
        if in_str:
            buf.append(c)
            if c == "\\":
                i += 1
                if i < len(interior):
                    buf.append(interior[i])
            elif c == in_str:
                in_str = None
            i += 1
            continue
        if c in "\"'":
            in_str = c
            buf.append(c)
        elif c in "([{":
            depth += 1
            buf.append(c)
        elif c in ")]}":
            depth -= 1
            buf.append(c)
        elif c == sep and depth == 0:
            parts.append("".join(buf))
            buf = []
        else:
            buf.append(c)
        i += 1
    if buf:
        parts.append("".join(buf))
    return [p.strip() for p in parts]


def _humanize_combo(expr: str, known_vars: dict[str, str]) -> str:
    s = expr.strip().replace("mainMod", "SUPER")
    strings = re.findall(r'"([^"]*)"', s)
    if strings:
        combo = ("SUPER" if "SUPER" in s and not s.strip().startswith('"') else "") + "".join(strings)
    else:
        combo = s
    return combo.strip()


def _humanize_action(expr: str, known_vars: dict[str, str]) -> str:
    s = expr.strip()
    s = re.sub(r"^hl\.dsp\.", "", s)
    for var, val in known_vars.items():
        s = re.sub(rf"\b{var}\b", val, s)
    return " ".join(s.split())


@dataclass
class Keybind:
    combo: str
    action: str
    opts: str = ""
    submap: str = ""
    comment: str = ""


@dataclass
class AutostartEntry:
    command: str
    comment: str = ""


@dataclass
class WindowRule:
    kind: str  # "window_rule" | "layer_rule" | "dynamic"
    name: str
    raw: str
    comment: str = ""


@dataclass
class WorkspaceRange:
    start: int
    end: int
    monitor: str


def _leading_comments(lines: list[str], stmt_line_idx: int) -> str:
    comment_lines: list[str] = []
    i = stmt_line_idx - 1
    while i >= 0:
        line = lines[i].strip()
        if line.startswith("--"):
            comment_lines.insert(0, line.lstrip("- ").strip())
            i -= 1
        else:
            break
    return " ".join(comment_lines)


def parse_keybinds() -> list[Keybind]:
    path = CONFIG_DIR / "binds.lua"
    if not path.exists():
        return []
    text = path.read_text()
    known_vars = _load_known_vars()
    lines = text.splitlines()
    line_starts = []
    pos = 0
    for line in lines:
        line_starts.append(pos)
        pos += len(line) + 1

    def line_of(idx: int) -> int:
        lo, hi = 0, len(line_starts) - 1
        while lo < hi:
            mid = (lo + hi + 1) // 2
            if line_starts[mid] <= idx:
                lo = mid
            else:
                hi = mid - 1
        return lo

    consumed: list[tuple[int, int]] = []
    results: list[Keybind] = []

    def in_consumed(idx: int) -> bool:
        return any(s <= idx < e for s, e in consumed)

    # Submap blocks: hl.define_submap("name", "reset", function() ... end)
    for m in re.finditer(r'hl\.define_submap\(\s*"([^"]+)"', text):
        name = m.group(1)
        paren = text.index("(", m.start())
        close = _find_close(text, paren)
        # extend to the trailing `end)` of the wrapping call
        end_paren_line_end = text.index(")", close) if text[close] != ")" else close
        block_start, block_end = m.start(), close + 2
        consumed.append((block_start, block_end))
        block = text[block_start:block_end]
        for bm in re.finditer(r"hl\.bind\(", block):
            call_start = bm.start()
            open_idx = bm.end() - 1
            close_idx = _find_close(block, open_idx)
            interior = block[open_idx + 1 : close_idx]
            args = _split_top_level(interior)
            if len(args) < 2:
                continue
            combo = _humanize_combo(args[0], known_vars)
            action = _humanize_action(args[1], known_vars)
            opts = args[2] if len(args) > 2 else ""
            results.append(Keybind(combo=combo, action=action, opts=opts, submap=name))

    # The one generated for-loop (workspace switch/move 1-10)
    loop_m = re.search(r"for i = 1, 10 do\b.*?\nend\b", text, re.DOTALL)
    if loop_m:
        consumed.append((loop_m.start(), loop_m.end()))
        results.append(
            Keybind(
                combo="SUPER + [0-9]",
                action="~/.config/hypr/scripts/workspace.sh switch <1-10> (generated loop)",
                submap="",
                comment="Switch workspaces per focused monitor, i3-style",
            )
        )
        results.append(
            Keybind(
                combo="SUPER + SHIFT + [0-9]",
                action="~/.config/hypr/scripts/workspace.sh move <1-10> (generated loop)",
                submap="",
                comment="Move active window to a workspace",
            )
        )

    # Top-level hl.bind(...) calls not already consumed by a submap/loop
    for m in re.finditer(r"hl\.bind\(", text):
        if in_consumed(m.start()):
            continue
        open_idx = m.end() - 1
        close_idx = _find_close(text, open_idx)
        interior = text[open_idx + 1 : close_idx]
        args = _split_top_level(interior)
        if len(args) < 2:
            continue
        combo = _humanize_combo(args[0], known_vars)
        action = _humanize_action(args[1], known_vars)
        opts = args[2] if len(args) > 2 else ""
        comment = _leading_comments(lines, line_of(m.start()))
        results.append(Keybind(combo=combo, action=action, opts=opts, comment=comment))

    return results


def parse_autostart() -> list[AutostartEntry]:
    path = CONFIG_DIR / "autostart.lua"
    if not path.exists():
        return []
    lines = path.read_text().splitlines()
    entries: list[AutostartEntry] = []
    comment_buf: list[str] = []
    for line in lines:
        stripped = line.strip()
        if stripped.startswith("--"):
            comment_buf.append(stripped.lstrip("- ").strip())
            continue
        if not stripped:
            comment_buf = []
            continue
        m = re.search(r'hl\.exec_cmd\(\s*"((?:[^"\\]|\\.)*)"\s*\)', line)
        if m:
            entries.append(AutostartEntry(command=m.group(1), comment=" ".join(comment_buf)))
            comment_buf = []
    return entries


def parse_window_rules() -> list[WindowRule]:
    path = CONFIG_DIR / "windowrules.lua"
    if not path.exists():
        return []
    text = path.read_text()
    lines = text.splitlines()
    line_starts = []
    pos = 0
    for line in lines:
        line_starts.append(pos)
        pos += len(line) + 1

    def line_of(idx: int) -> int:
        lo, hi = 0, len(line_starts) - 1
        while lo < hi:
            mid = (lo + hi + 1) // 2
            if line_starts[mid] <= idx:
                lo = mid
            else:
                hi = mid - 1
        return lo

    results: list[WindowRule] = []
    for m in re.finditer(r"hl\.(window_rule|layer_rule)\(", text):
        kind = m.group(1)
        open_idx = m.end() - 1
        close_idx = _find_close(text, open_idx)
        raw = text[m.start() : close_idx + 1]
        name_m = re.search(r'name\s*=\s*"([^"]+)"', raw)
        name = name_m.group(1) if name_m else "(unnamed)"
        comment = _leading_comments(lines, line_of(m.start()))
        results.append(WindowRule(kind=kind, name=name, raw=raw, comment=comment))

    for m in re.finditer(r'hl\.on\(\s*"([^"]+)"', text):
        open_idx = text.index("(", m.start())
        close_idx = _find_close(text, open_idx)
        raw = text[m.start() : close_idx + 1]
        comment = _leading_comments(lines, line_of(m.start()))
        results.append(WindowRule(kind="dynamic", name=m.group(1), raw=raw, comment=comment))

    results.sort(key=lambda r: text.index(r.raw[:30]))
    return results


def parse_workspace_ranges() -> list[WorkspaceRange]:
    path = CONFIG_DIR / "workspaces.lua"
    if not path.exists():
        return []
    text = path.read_text()
    out = []
    for m in re.finditer(r'workspaceRange\((\d+),\s*(\d+),\s*"([^"]+)"\)', text):
        out.append(WorkspaceRange(start=int(m.group(1)), end=int(m.group(2)), monitor=m.group(3)))
    return out


def parse_workspace_rules_raw() -> list[str]:
    path = CONFIG_DIR / "workspaces.lua"
    if not path.exists():
        return []
    text = path.read_text()
    out = []
    for m in re.finditer(r"hl\.workspace_rule\(", text):
        open_idx = m.end() - 1
        close_idx = _find_close(text, open_idx)
        out.append(text[m.start() : close_idx + 1])
    return out
