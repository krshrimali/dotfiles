from __future__ import annotations

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gtk  # noqa: E402

from ..backend import animations_store as anim  # noqa: E402
from .widgets import apply_change, esc, row_for_spec  # noqa: E402


def _leaf_row(a: anim.AnimationLeaf) -> Adw.ActionRow:
    subtitle = f"curve: {a.bezier}"
    if a.style:
        subtitle += f" · style: {a.style}"
    row = Adw.ActionRow(title=esc(a.label), subtitle=esc(subtitle))

    switch = Gtk.Switch(active=a.enabled, valign=Gtk.Align.CENTER)
    spin = Gtk.SpinButton.new_with_range(0.1, 15, 0.1)
    spin.set_digits(2)
    spin.set_value(a.speed)
    spin.set_valign(Gtk.Align.CENTER)

    def push():
        a.enabled = switch.get_active()
        a.speed = round(spin.get_value(), 2)
        apply_change(row, lambda: anim.set_animation(a))

    switch.connect("notify::active", lambda *_: push())
    spin.connect("value-changed", lambda *_: push())

    row.add_suffix(spin)
    row.add_suffix(Gtk.Separator(orientation=Gtk.Orientation.VERTICAL))
    row.add_suffix(switch)
    row.set_activatable_widget(switch)
    return row


def build_page() -> Adw.PreferencesPage:
    page = Adw.PreferencesPage(title="Animations", icon_name="preferences-desktop-display-symbolic")

    top = Adw.PreferencesGroup()
    top.add(row_for_spec(anim.ANIMATIONS_ENABLED))
    page.add(top)

    group = Adw.PreferencesGroup(
        title="Animation curves", description="Speed is in deciseconds; each row's switch enables/disables it"
    )
    for leaf in anim.parse_animations():
        group.add(_leaf_row(leaf))
    page.add(group)
    return page
