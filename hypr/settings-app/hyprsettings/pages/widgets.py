"""Shared helpers for turning a SettingSpec into an Adw row, wired to apply
changes live + persist them, with a small toast-based error surface so a
failed hyprctl/file write is visible instead of silently swallowed.
"""
from __future__ import annotations

import re

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gdk, GLib, Gtk  # noqa: E402

from ..backend.hyprctl import HyprctlError  # noqa: E402
from ..backend.store import SettingSpec  # noqa: E402


def esc(text) -> str:
    """Escape text for use in Adw title/subtitle properties, which render
    as Pango markup — raw '&'/'<' in config-derived strings otherwise break
    the widget (GTK logs "Failed to set text ... from markup" and drops it)."""
    return GLib.markup_escape_text(str(text))


def report_error(widget: Gtk.Widget, message: str) -> None:
    root = widget.get_root()
    if isinstance(root, Adw.ApplicationWindow) and hasattr(root, "toast_overlay"):
        root.toast_overlay.add_toast(Adw.Toast(title=esc(message), timeout=4))
    else:
        print(f"error: {message}")


def apply_change(widget: Gtk.Widget, fn) -> bool:
    try:
        fn()
        return True
    except (HyprctlError, ValueError, OSError) as exc:
        report_error(widget, f"Couldn't apply change: {exc}")
        return False


# --- Hyprland color literals <-> Gdk.RGBA ----------------------------------

_HEX_RE = re.compile(r"^rgba?\(\s*([0-9a-fA-F]{6}|[0-9a-fA-F]{8})\s*\)$")
_LEGACY_RE = re.compile(r"^0x([0-9a-fA-F]{8})$")


def parse_hypr_color(text: str) -> Gdk.RGBA | None:
    """Parse a Hyprland color literal into a Gdk.RGBA.

    Accepts rgb(RRGGBB), rgba(RRGGBBAA) and the legacy 0xAARRGGBB form.
    Returns None for anything else so callers leave the picker untouched
    rather than silently rewriting a value they couldn't understand.
    """
    text = (text or "").strip()
    match = _HEX_RE.match(text)
    if match:
        digits = match.group(1)
        red, green, blue = digits[0:2], digits[2:4], digits[4:6]
        alpha = digits[6:8] if len(digits) == 8 else "ff"
    else:
        match = _LEGACY_RE.match(text)
        if not match:
            return None
        digits = match.group(1)
        alpha, red, green, blue = digits[0:2], digits[2:4], digits[4:6], digits[6:8]

    rgba = Gdk.RGBA()
    rgba.red = int(red, 16) / 255
    rgba.green = int(green, 16) / 255
    rgba.blue = int(blue, 16) / 255
    rgba.alpha = int(alpha, 16) / 255
    return rgba


def format_hypr_color(rgba: Gdk.RGBA) -> str:
    """Render a Gdk.RGBA as rgba(RRGGBBAA), the form used across the config."""

    def channel(value: float) -> int:
        return max(0, min(255, round(value * 255)))

    return (
        f"rgba({channel(rgba.red):02x}{channel(rgba.green):02x}"
        f"{channel(rgba.blue):02x}{channel(rgba.alpha):02x})"
    )


def attach_color_picker(row: Adw.EntryRow, on_picked=None) -> Gtk.ColorDialogButton:
    """Add a color-picker button to an EntryRow holding a Hyprland color string.

    The entry stays the source of truth — the button writes into it and mirrors
    hand-typed edits — so pasting a literal or clearing an optional color keeps
    working exactly as it did before the picker existed.
    """
    button = Gtk.ColorDialogButton(
        dialog=Gtk.ColorDialog(with_alpha=True),
        valign=Gtk.Align.CENTER,
        tooltip_text="Pick a color",
    )
    button.add_css_class("flat")
    syncing = False

    def sync_button_from_entry(*_args):
        nonlocal syncing
        rgba = parse_hypr_color(row.get_text())
        if rgba is None:
            return
        syncing = True
        try:
            button.set_rgba(rgba)
        finally:
            syncing = False

    def on_rgba_changed(_button, _param):
        if syncing:
            return
        row.set_text(format_hypr_color(button.get_rgba()))
        if on_picked is not None:
            on_picked()

    sync_button_from_entry()
    button.connect("notify::rgba", on_rgba_changed)
    row.connect("changed", sync_button_from_entry)
    row.add_suffix(button)
    return button


def row_for_spec(spec: SettingSpec) -> Adw.PreferencesRow:
    try:
        current = spec.get()
    except (ValueError, FileNotFoundError) as exc:
        row = Adw.ActionRow(title=esc(spec.label), subtitle=esc(f"unreadable: {exc}"))
        row.set_sensitive(False)
        return row

    if spec.kind == "bool":
        row = Adw.SwitchRow(title=esc(spec.label), subtitle=esc(spec.subtitle), active=bool(current))

        def on_toggle(r, _param):
            apply_change(r, lambda: spec.set(r.get_active()))

        row.connect("notify::active", on_toggle)
        return row

    if spec.kind in ("int", "float"):
        adjustment = Gtk.Adjustment(
            value=float(current), lower=spec.min, upper=spec.max, step_increment=spec.step
        )
        row = Adw.SpinRow(
            title=esc(spec.label), subtitle=esc(spec.subtitle), adjustment=adjustment, digits=spec.digits
        )

        def on_changed(r):
            value = r.get_value()
            typed = int(value) if spec.kind == "int" else round(value, max(spec.digits, 4))
            apply_change(r, lambda: spec.set(typed))

        row.connect("changed", on_changed)
        return row

    if spec.kind in ("choice_str", "choice_int"):
        model = Gtk.StringList.new(spec.choices)
        row = Adw.ComboRow(title=esc(spec.label), subtitle=esc(spec.subtitle), model=model)
        try:
            row.set_selected(spec.choices.index(str(current)))
        except ValueError:
            pass

        def on_selected(r, _param):
            idx = r.get_selected()
            if idx == Gtk.INVALID_LIST_POSITION:
                return
            value = spec.choices[idx]
            apply_change(r, lambda: spec.set(value))

        row.connect("notify::selected", on_selected)
        return row

    # str
    row = Adw.EntryRow(title=esc(spec.label), text=str(current))
    if spec.subtitle:
        row.set_tooltip_text(spec.subtitle)

    def on_apply(r):
        apply_change(r, lambda: spec.set(r.get_text()))

    if spec.is_color:
        attach_color_picker(row, lambda: on_apply(row))

    row.connect("apply", on_apply)
    row.connect("entry-activated", on_apply)

    def on_focus_leave(controller):
        on_apply(row)

    focus = Gtk.EventControllerFocus()
    focus.connect("leave", on_focus_leave)
    row.add_controller(focus)
    return row


def group_for_specs(title: str, specs: list[SettingSpec], description: str = "") -> Adw.PreferencesGroup:
    group = Adw.PreferencesGroup(title=esc(title), description=esc(description))
    for spec in specs:
        group.add(row_for_spec(spec))
    return group
