from __future__ import annotations

import shutil
import subprocess

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gtk  # noqa: E402

from ..backend import hyprctl  # noqa: E402
from .widgets import esc, report_error  # noqa: E402


def _monitor_row(m: dict) -> Adw.ExpanderRow:
    title = m.get("description") or m["name"]
    subtitle = f'{m["width"]}x{m["height"]}@{m["refreshRate"]:.2f}Hz · scale {m["scale"]}'
    row = Adw.ExpanderRow(title=esc(f'{m["name"]} — {title}'), subtitle=esc(subtitle))

    if m.get("focused"):
        badge = Gtk.Image.new_from_icon_name("emblem-ok-symbolic")
        badge.set_tooltip_text("Focused monitor")
        row.add_prefix(badge)

    details = [
        ("Resolution", f'{m["width"]} x {m["height"]}'),
        ("Refresh rate", f'{m["refreshRate"]:.3f} Hz'),
        ("Position", f'{m["x"]}, {m["y"]}'),
        ("Scale", str(m["scale"])),
        ("Transform", str(m["transform"])),
        ("Active workspace", m.get("activeWorkspace", {}).get("name", "-")),
        ("VRR", "on" if m.get("vrr") else "off"),
        ("Enabled", "no" if m.get("disabled") else "yes"),
    ]
    for label, value in details:
        r = Adw.ActionRow(title=label)
        r.add_suffix(Gtk.Label(label=value, css_classes=["dim-label"]))
        row.add_row(r)
    return row


def build_page() -> Adw.PreferencesPage:
    page = Adw.PreferencesPage(title="Monitors", icon_name="video-display-symbolic")

    group = Adw.PreferencesGroup(
        title="Connected monitors", description="Live state from hyprctl — read-only"
    )
    try:
        for m in hyprctl.monitors():
            group.add(_monitor_row(m))
    except hyprctl.HyprctlError as exc:
        error_row = Adw.ActionRow(title="Couldn't query monitors", subtitle=str(exc))
        group.add(error_row)
    page.add(group)

    arrange = Adw.PreferencesGroup(
        title="Arrange displays",
        description="Position, resolution, refresh rate, scale and rotation are managed by nwg-displays "
        "to avoid two tools fighting over the same config file",
    )
    row = Adw.ActionRow(title="nwg-displays", subtitle="Drag-and-drop monitor arrangement")
    launch_btn = Gtk.Button(label="Open", valign=Gtk.Align.CENTER, css_classes=["suggested-action"])

    def on_launch(_btn):
        if not shutil.which("nwg-displays"):
            report_error(launch_btn, "nwg-displays is not installed")
            return
        try:
            subprocess.Popen(
                ["nwg-displays"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True
            )
        except OSError as exc:
            report_error(launch_btn, f"Couldn't launch nwg-displays: {exc}")

    launch_btn.connect("clicked", on_launch)
    row.add_suffix(launch_btn)
    row.set_activatable_widget(launch_btn)
    arrange.add(row)
    page.add(arrange)

    return page
