from __future__ import annotations

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw  # noqa: E402

from ..backend import store  # noqa: E402
from .widgets import group_for_specs  # noqa: E402


def build_page() -> Adw.PreferencesPage:
    page = Adw.PreferencesPage(title="Input", icon_name="input-keyboard-symbolic")
    page.add(group_for_specs("Keyboard", store.INPUT_KEYBOARD))
    page.add(group_for_specs("Mouse", store.INPUT_MOUSE))
    page.add(group_for_specs("Touchpad", store.INPUT_TOUCHPAD))

    gestures = Adw.PreferencesGroup(title="Gestures", description="Defined in config/inputs.lua — edit the file to change")
    row = Adw.ActionRow(title="3-finger swipe", subtitle="Horizontal → switch workspace")
    gestures.add(row)
    page.add(gestures)
    return page
