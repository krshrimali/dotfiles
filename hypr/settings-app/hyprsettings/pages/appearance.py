from __future__ import annotations

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gtk  # noqa: E402

from ..backend import border_gradient, store  # noqa: E402
from .widgets import apply_change, attach_color_picker, group_for_specs  # noqa: E402


def _active_border_group() -> Adw.PreferencesGroup:
    group = Adw.PreferencesGroup(
        title="Active border color",
        description="A one- or two-color gradient border for the focused window",
    )
    g = border_gradient.get_active_border()
    color1 = Adw.EntryRow(title="Color 1", text=g.colors[0] if g.colors else "")
    color2 = Adw.EntryRow(title="Color 2 (optional)", text=g.colors[1] if len(g.colors) > 1 else "")
    color1.set_tooltip_text("rgba(RRGGBBAA), rgb(RRGGBB), or use the picker")
    color2.set_tooltip_text("Clear this field for a solid (single-color) border")
    angle_adj = Gtk.Adjustment(value=g.angle, lower=0, upper=360, step_increment=5)
    angle_row = Adw.SpinRow(title="Gradient angle", adjustment=angle_adj, digits=0)

    def push():
        colors = [c.get_text().strip() for c in (color1, color2) if c.get_text().strip()]
        if not colors:
            return
        new_g = border_gradient.BorderGradient(colors=colors, angle=int(angle_row.get_value()))
        apply_change(angle_row, lambda: border_gradient.set_active_border(new_g))

    for entry in (color1, color2):
        entry.connect("apply", lambda r: push())
        entry.connect("entry-activated", lambda r: push())
        attach_color_picker(entry, push)
    angle_row.connect("changed", lambda r: push())

    group.add(color1)
    group.add(color2)
    group.add(angle_row)
    return group


def build_page() -> Adw.PreferencesPage:
    page = Adw.PreferencesPage(title="Appearance", icon_name="applications-graphics-symbolic")
    page.add(group_for_specs("Gaps & borders", store.APPEARANCE_GAPS_BORDERS))
    page.add(_active_border_group())
    page.add(group_for_specs("Inactive border", store.APPEARANCE_COLORS))
    page.add(group_for_specs("Corners & opacity", store.APPEARANCE_CORNERS_OPACITY))
    page.add(group_for_specs("Shadow", store.APPEARANCE_SHADOW))
    page.add(group_for_specs("Blur", store.APPEARANCE_BLUR))
    return page
