from __future__ import annotations

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gtk  # noqa: E402

from ..backend import lua_readers as lr  # noqa: E402
from .widgets import esc  # noqa: E402


def build_page() -> Adw.PreferencesPage:
    page = Adw.PreferencesPage(title="Workspaces", icon_name="view-paged-symbolic")

    group = Adw.PreferencesGroup(
        title="Per-monitor assignment", description="Read-only — from config/workspaces.lua"
    )
    for r in lr.parse_workspace_ranges():
        row = Adw.ActionRow(title=f"Workspaces {r.start}–{r.end}", subtitle=f"Monitor: {r.monitor}")
        group.add(row)
    page.add(group)

    specials = lr.parse_workspace_rules_raw()
    if specials:
        sgroup = Adw.PreferencesGroup(title="Special workspace rules")
        for raw in specials:
            row = Adw.ActionRow(title=esc(" ".join(raw.split())[:120]))
            sgroup.add(row)
        page.add(sgroup)

    return page
