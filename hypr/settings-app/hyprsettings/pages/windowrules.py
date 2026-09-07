from __future__ import annotations

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gtk  # noqa: E402

from ..backend import lua_readers as lr  # noqa: E402
from .widgets import esc  # noqa: E402

KIND_LABELS = {"window_rule": "Window rule", "layer_rule": "Layer rule", "dynamic": "Dynamic (scripted)"}


def build_page() -> Adw.PreferencesPage:
    page = Adw.PreferencesPage(title="Window Rules", icon_name="preferences-system-windows-symbolic")
    group = Adw.PreferencesGroup(
        title="Rules", description="Read-only — from config/windowrules.lua"
    )
    for r in lr.parse_window_rules():
        subtitle = KIND_LABELS.get(r.kind, r.kind) + (f" · {r.comment}" if r.comment else "")
        row = Adw.ExpanderRow(title=esc(r.name), subtitle=esc(subtitle))
        label = Gtk.Label(label=r.raw, wrap=False, xalign=0, css_classes=["monospace", "caption"], selectable=True)
        scroller = Gtk.ScrolledWindow(hscrollbar_policy=Gtk.PolicyType.AUTOMATIC, vscrollbar_policy=Gtk.PolicyType.NEVER)
        scroller.set_child(label)
        scroller.set_margin_start(12)
        scroller.set_margin_end(12)
        scroller.set_margin_bottom(8)
        wrapper_row = Adw.ActionRow()
        wrapper_row.set_child(scroller)
        row.add_row(wrapper_row)
        group.add(row)
    page.add(group)
    return page
