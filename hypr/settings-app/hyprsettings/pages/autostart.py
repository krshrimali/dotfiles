from __future__ import annotations

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw  # noqa: E402

from ..backend import lua_readers as lr  # noqa: E402
from .widgets import esc  # noqa: E402


def build_page() -> Adw.PreferencesPage:
    page = Adw.PreferencesPage(title="Autostart", icon_name="system-run-symbolic")
    group = Adw.PreferencesGroup(
        title="Startup commands", description="Read-only — from config/autostart.lua, run once per session"
    )
    for entry in lr.parse_autostart():
        row = Adw.ActionRow(title=esc(entry.command), subtitle=esc(entry.comment) if entry.comment else None)
        group.add(row)
    page.add(group)
    return page
