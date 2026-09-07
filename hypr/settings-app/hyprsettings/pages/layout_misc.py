from __future__ import annotations

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw  # noqa: E402

from ..backend import store  # noqa: E402
from .widgets import group_for_specs  # noqa: E402


def build_page() -> Adw.PreferencesPage:
    page = Adw.PreferencesPage(title="Layout & Misc", icon_name="view-grid-symbolic")
    page.add(
        group_for_specs(
            "Layout & startup behavior",
            store.LAYOUT_MISC,
            description="dwindle/master layout tuning, cursor and XWayland behavior",
        )
    )
    return page
