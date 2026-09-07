from __future__ import annotations

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gtk  # noqa: E402

from ..backend import lua_readers as lr  # noqa: E402
from .widgets import esc  # noqa: E402


def build_page() -> Adw.PreferencesPage:
    page = Adw.PreferencesPage(title="Keybinds", icon_name="input-keyboard-symbolic")

    binds = lr.parse_keybinds()

    search_group = Adw.PreferencesGroup()
    search = Gtk.SearchEntry(placeholder_text="Search keybinds…")
    search_group.add(search)
    page.add(search_group)

    group = Adw.PreferencesGroup(
        title=f"{len(binds)} keybinds", description="Read-only — from config/binds.lua"
    )
    rows = []
    for b in binds:
        subtitle = b.action
        if b.opts:
            subtitle += f"  [{' '.join(b.opts.split())}]"
        title = b.combo
        if b.submap:
            title = f"[{b.submap}] {title}"
        row = Adw.ActionRow(title=esc(title), subtitle=esc(subtitle))
        if b.comment:
            row.set_tooltip_text(b.comment)
        haystack = " ".join([b.combo, b.action, b.submap, b.comment]).lower()
        rows.append((row, haystack))
        group.add(row)
    page.add(group)

    def on_search_changed(entry):
        needle = entry.get_text().strip().lower()
        for row, haystack in rows:
            row.set_visible(needle in haystack)

    search.connect("search-changed", on_search_changed)
    return page
