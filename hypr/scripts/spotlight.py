#!/usr/bin/env python3
"""Cursor-following spotlight overlay: dims every monitor, cuts a soft-edged
clear hole around the mouse on whichever monitor it's currently on.

One fullscreen click-through layer-shell surface per monitor (so it renders
correctly on each output's own geometry, including the rotated portrait
ones -- Gdk.Monitor.get_geometry() already accounts for transform). Cursor
position is polled straight off Hyprland's IPC socket each frame; that
round-trip measured ~0.01ms locally, cheap enough for 60fps.

Usage: spotlight.py           # run in foreground (daemonized by spotlight.sh)
Signals: SIGUSR1 grows the radius, SIGUSR2 shrinks it, SIGTERM/SIGINT exit.
"""
import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Gdk", "4.0")
gi.require_version("Gtk4LayerShell", "1.0")

import cairo
import math
import os
import signal
import socket

from gi.repository import Gtk, Gdk, GLib, Gtk4LayerShell as LS

DIM_OPACITY = 0.75      # how dark the greyed-out area is (0-1)
FEATHER = 0.35          # fraction of radius spent softening the edge
POLL_MS = 16            # ~60fps cursor polling
RADIUS_MIN = 60.0
RADIUS_MAX = 900.0
RADIUS_STEP = 1.15      # per SIGUSR1/SIGUSR2 step
RADIUS_DEFAULT = 220.0
RADIUS_FILE = os.path.expanduser("~/.cache/hypr/spotlight_radius")

SOCK_PATH = f"{os.environ['XDG_RUNTIME_DIR']}/hypr/{os.environ['HYPRLAND_INSTANCE_SIGNATURE']}/.socket.sock"


def hypr_cursor_pos():
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.settimeout(0.5)
    try:
        s.connect(SOCK_PATH)
        s.sendall(b"cursorpos")
        data = b""
        while True:
            chunk = s.recv(4096)
            if not chunk:
                break
            data += chunk
        x_str, y_str = data.decode().split(",")
        return float(x_str.strip()), float(y_str.strip())
    finally:
        s.close()


def load_radius():
    try:
        with open(RADIUS_FILE) as f:
            r = float(f.read().strip())
            return max(RADIUS_MIN, min(RADIUS_MAX, r))
    except (OSError, ValueError):
        return RADIUS_DEFAULT


def save_radius(r):
    try:
        os.makedirs(os.path.dirname(RADIUS_FILE), exist_ok=True)
        with open(RADIUS_FILE, "w") as f:
            f.write(str(r))
    except OSError:
        pass


class SpotlightOutput:
    """One click-through fullscreen overlay window bound to a single monitor."""

    def __init__(self, monitor: Gdk.Monitor):
        self.monitor = monitor
        self.geom = monitor.get_geometry()  # local logical geometry, transform-aware

        self.window = Gtk.Window()
        LS.init_for_window(self.window)
        LS.set_monitor(self.window, monitor)
        LS.set_layer(self.window, LS.Layer.OVERLAY)
        LS.set_namespace(self.window, "spotlight")
        for edge in (LS.Edge.TOP, LS.Edge.BOTTOM, LS.Edge.LEFT, LS.Edge.RIGHT):
            LS.set_anchor(self.window, edge, True)
        LS.set_exclusive_zone(self.window, -1)
        LS.set_keyboard_mode(self.window, LS.KeyboardMode.NONE)

        self.area = Gtk.DrawingArea()
        self.area.set_draw_func(self.draw)
        self.window.set_child(self.area)

        self.window.connect("realize", self._on_realize)
        self.window.present()

        self.cx, self.cy = -1000.0, -1000.0  # local coords; off-screen until first poll
        self.on_this_output = False
        self.radius = RADIUS_DEFAULT

    def _on_realize(self, *_a):
        # Click-through: empty input region so all pointer/keyboard events
        # pass straight to whatever is beneath the overlay.
        surface = self.window.get_surface()
        surface.set_input_region(cairo.Region())

    def update_cursor(self, gx, gy, radius):
        # Only queue a redraw when something on THIS output actually
        # changed. Redrawing all 3 monitors every tick regardless of
        # change starves the GLib main loop's frame-clock scheduling and
        # stretches the ~16ms poll interval out to ~35-48ms (visible lag).
        lx = gx - self.geom.x
        ly = gy - self.geom.y
        now_on = 0 <= lx <= self.geom.width and 0 <= ly <= self.geom.height
        changed = (
            radius != self.radius
            or now_on != self.on_this_output
            or (now_on and (lx != self.cx or ly != self.cy))
        )
        self.radius = radius
        self.on_this_output = now_on
        if now_on:
            self.cx, self.cy = lx, ly
        if changed:
            self.area.queue_draw()

    def draw(self, _area, cr: cairo.Context, width, height):
        cr.set_operator(cairo.OPERATOR_SOURCE)
        cr.set_source_rgba(0, 0, 0, DIM_OPACITY)
        cr.paint()

        if not self.on_this_output:
            return

        r = self.radius
        inner = r * (1.0 - FEATHER)
        cr.set_operator(cairo.OPERATOR_DEST_OUT)
        grad = cairo.RadialGradient(self.cx, self.cy, 0, self.cx, self.cy, r)
        grad.add_color_stop_rgba(0.0, 0, 0, 0, 1.0)
        grad.add_color_stop_rgba(inner / r if r else 0.0, 0, 0, 0, 1.0)
        grad.add_color_stop_rgba(1.0, 0, 0, 0, 0.0)
        cr.set_source(grad)
        cr.arc(self.cx, self.cy, r, 0, 2 * math.pi)
        cr.fill()

    def close(self):
        self.window.close()


class Spotlight:
    def __init__(self):
        self.radius = load_radius()
        display = Gdk.Display.get_default()

        # GTK4 paints an opaque theme background behind widgets by default;
        # without this, the alpha "hole" we cut only reveals that opaque
        # backing layer, not the real desktop underneath.
        css = Gtk.CssProvider()
        css.load_from_data(b"window, window > * { background-color: transparent; }")
        Gtk.StyleContext.add_provider_for_display(
            display, css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        monitors = display.get_monitors()
        self.outputs = [SpotlightOutput(monitors.get_item(i)) for i in range(monitors.get_n_items())]
        GLib.timeout_add(POLL_MS, self._tick)

    def _tick(self):
        try:
            gx, gy = hypr_cursor_pos()
        except OSError:
            return True
        for out in self.outputs:
            out.update_cursor(gx, gy, self.radius)
        return True

    def grow(self):
        self.radius = min(RADIUS_MAX, self.radius * RADIUS_STEP)
        save_radius(self.radius)

    def shrink(self):
        self.radius = max(RADIUS_MIN, self.radius / RADIUS_STEP)
        save_radius(self.radius)


def main():
    app = Spotlight()
    loop = GLib.MainLoop()

    def _grow(*_a):
        app.grow()

    def _shrink(*_a):
        app.shrink()

    def _quit(*_a):
        loop.quit()

    GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, signal.SIGUSR1, _grow)
    GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, signal.SIGUSR2, _shrink)
    GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, signal.SIGTERM, _quit)
    GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, signal.SIGINT, _quit)

    loop.run()
    for out in app.outputs:
        out.close()


if __name__ == "__main__":
    main()
