"""
Kitty keymap search kitten (fzf-powered).

Lists every currently active keyboard mapping (kitty's builtin defaults
merged with this config's overrides) and lets you fuzzy-search them with
fzf. Selecting an entry copies its action to the clipboard.

Usage (from kitty.conf map):
    map ctrl+b>/ kitten keymap_search.py
"""

import os
import subprocess
import sys

from kitty.config import load_config
from kitty.constants import config_dir
from kitty.types import Shortcut


def build_rows() -> list[str]:
    conf = os.path.join(config_dir, "kitty.conf")
    opts = load_config(conf)

    def as_str(defns: list) -> str:
        seen = set()
        uniq = []
        for d in reversed(defns):
            key = d.unique_identity_within_keymap
            if key not in seen:
                seen.add(key)
                uniq.append(d)
        return ", ".join(d.human_repr() for d in uniq)

    rows = []
    for mode_name, km in opts.keyboard_modes.items():
        by_seq: dict = {}
        for defns in km.keymap.values():
            for d in defns:
                by_seq.setdefault(d.full_key_sequence_to_trigger, []).append(d)
        for seq, seq_defns in by_seq.items():
            key_str = Shortcut(seq).human_repr(opts.kitty_mod)
            action_str = as_str(seq_defns)
            if not action_str or action_str == "no-op":
                continue
            prefix = f"[{mode_name}] " if mode_name else ""
            rows.append(f"{prefix}{key_str:<28} → {action_str}")

    rows.sort()
    return rows


def main(args: list[str]) -> str:
    rows = build_rows()
    if not rows:
        return ""
    listing = "\n".join(rows)
    try:
        proc = subprocess.run(
            [
                "fzf",
                "--prompt=keymap> ",
                "--header=kitty keybindings — enter: copy action to clipboard, esc: cancel",
            ],
            input=listing,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError:
        sys.stderr.write("keymap_search: fzf not found on PATH\n")
        return ""
    return proc.stdout.strip()


from kittens.tui.handler import result_handler  # noqa: E402


@result_handler(no_ui=False)
def handle_result(args: list[str], result: str, target_window_id: int, boss) -> None:
    if not result:
        return
    action = result.split("→", 1)[1].strip() if "→" in result else result.strip()
    from kitty.clipboard import set_clipboard_string

    set_clipboard_string(action)
