"""Targeted, comment-preserving edits to the config/*.lua files.

We deliberately don't write a full Lua parser. Every file this module
touches consists of simple `key = value` assignments inside `name = { ... }`
tables (optionally nested), or single-line `hl.animation({ ... })` calls.
We locate the relevant block or call with a balanced-brace scan and
substitute just the value, leaving comments and formatting elsewhere in
the file untouched.
"""
from __future__ import annotations

import re
import shutil
from pathlib import Path

CONFIG_DIR = Path.home() / ".config" / "hypr" / "config"


def _backup(path: Path) -> None:
    bak = path.with_suffix(path.suffix + ".bak")
    if not bak.exists():
        shutil.copy2(path, bak)


def _find_block(text: str, name: str, start: int = 0) -> tuple[int, int]:
    """Return (open_brace_idx, close_brace_idx) for `name = { ... }` in text."""
    m = re.compile(rf"\b{re.escape(name)}\s*=\s*\{{").search(text, start)
    if not m:
        raise ValueError(f"block {name!r} not found")
    open_idx = m.end() - 1
    depth = 0
    i = open_idx
    while i < len(text):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                return open_idx, i
        i += 1
    raise ValueError(f"unbalanced braces for block {name!r}")


def _block_span(text: str, path: list[str]) -> tuple[int, int]:
    span = (0, len(text))
    for name in path:
        seg = text[span[0]:span[1]]
        open_idx, close_idx = _find_block(seg, name)
        span = (span[0] + open_idx, span[0] + close_idx)
    return span


def set_key(text: str, path: list[str], key: str, value: str) -> str:
    """Set `key = value` inside the nested table described by `path`.

    `value` is the literal Lua source to substitute in (already quoted if
    it's a string). Handles both scalar values and `{ ... }` table values.
    """
    open_idx, close_idx = _block_span(text, path)
    block = text[open_idx:close_idx]
    m = re.search(rf"\b{re.escape(key)}\s*=\s*", block)
    if not m:
        raise ValueError(f"key {key!r} not found in block {'/'.join(path)}")
    val_start = m.end()
    if block[val_start] == "{":
        depth = 0
        i = val_start
        while i < len(block):
            if block[i] == "{":
                depth += 1
            elif block[i] == "}":
                depth -= 1
                if depth == 0:
                    i += 1
                    break
            i += 1
        val_end = i
    else:
        vm = re.compile(r"[^\n,]+").match(block, val_start)
        val_end = vm.end()
    new_block = block[: m.start()] + f"{key} = {value}" + block[val_end:]
    return text[:open_idx] + new_block + text[close_idx:]


def get_key(text: str, path: list[str], key: str) -> str:
    """Return the raw (unparsed) Lua source of `key`'s value inside `path`."""
    open_idx, close_idx = _block_span(text, path)
    block = text[open_idx:close_idx]
    m = re.search(rf"\b{re.escape(key)}\s*=\s*", block)
    if not m:
        raise ValueError(f"key {key!r} not found in block {'/'.join(path)}")
    val_start = m.end()
    if block[val_start] == "{":
        depth = 0
        i = val_start
        while i < len(block):
            if block[i] == "{":
                depth += 1
            elif block[i] == "}":
                depth -= 1
                if depth == 0:
                    i += 1
                    break
            i += 1
        return block[val_start:i]
    vm = re.compile(r"[^\n,]+").match(block, val_start)
    return block[val_start : vm.end()]


def read_key(filename: str, path: list[str], key: str) -> str:
    file_path = CONFIG_DIR / filename
    return get_key(file_path.read_text(), path, key)


def patch_file(filename: str, path: list[str], key: str, value: str) -> None:
    file_path = CONFIG_DIR / filename
    text = file_path.read_text()
    new_text = set_key(text, path, key, value)
    if new_text != text:
        _backup(file_path)
        file_path.write_text(new_text)


def set_animation(filename: str, leaf: str, **kwargs: str) -> None:
    file_path = CONFIG_DIR / filename
    text = file_path.read_text()
    m = re.search(rf'hl\.animation\(\{{\s*leaf\s*=\s*"{re.escape(leaf)}"', text)
    if not m:
        raise ValueError(f"animation {leaf!r} not found")
    open_paren = text.index("(", m.start())
    depth = 0
    i = open_paren
    while i < len(text):
        if text[i] == "(":
            depth += 1
        elif text[i] == ")":
            depth -= 1
            if depth == 0:
                break
        i += 1
    call_end = i + 1
    call = text[m.start() : call_end]
    new_call = call
    for key, value in kwargs.items():
        pattern = re.compile(rf"(\b{re.escape(key)}\s*=\s*)[^,}}]+")
        if pattern.search(new_call):
            new_call = pattern.sub(lambda mm: mm.group(1) + str(value), new_call, count=1)
        else:
            # key not present (e.g. optional `style`) — insert before closing `})`
            new_call = new_call[:-2].rstrip() + f", {key} = {value} }})"
    if new_call != call:
        new_text = text[: m.start()] + new_call + text[call_end:]
        _backup(file_path)
        file_path.write_text(new_text)


