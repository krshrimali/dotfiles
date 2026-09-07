#!/usr/bin/env python3
"""On-screen audio device switcher for Hyprland.

The first press opens a layer-shell overlay listing every output (or input)
device and highlights the next one in the list. Each further press advances the
highlight. Nothing is switched while you are still cycling -- the device you
land on is committed once you stop pressing for COMMIT_DELAY_MS, so streams get
moved once instead of at every device along the way.

Usage: audio-switch.py sink|source
"""

import errno
import json
import os
import socket
import subprocess
import sys

# gtk4-layer-shell has to be loaded ahead of libwayland-client, which the Python
# bindings cannot arrange on their own, so re-exec ourselves once with the
# preload in place. See https://github.com/wmww/gtk4-layer-shell/blob/main/linking.md
_PRELOAD = "libgtk4-layer-shell.so.0"
if _PRELOAD not in os.environ.get("LD_PRELOAD", ""):
    _env = dict(os.environ)
    _env["LD_PRELOAD"] = ":".join(filter(None, [_PRELOAD, _env.get("LD_PRELOAD", "")]))
    os.execve(sys.executable, [sys.executable, os.path.abspath(__file__), *sys.argv[1:]], _env)

# How long to wait, after the last press, before committing the selection.
COMMIT_DELAY_MS = 1500

# Device descriptions to skip while cycling (exact match). Add e.g.
# "Easy Effects Sink" here if you never want to land on it.
EXCLUDE = set()

KINDS = {
    "sink": {
        "title": "Output",
        "icon": "audio-speakers-symbolic",
        "list": "sinks",
        "get_default": "get-default-sink",
        "set_default": "set-default-sink",
        "streams": "sink-inputs",
        "move": "move-sink-input",
    },
    "source": {
        "title": "Input",
        "icon": "audio-input-microphone-symbolic",
        "list": "sources",
        "get_default": "get-default-source",
        "set_default": "set-default-source",
        "streams": "source-outputs",
        "move": "move-source-output",
    },
}

CSS = b"""
window { background: transparent; }
.card {
    background: rgba(26, 26, 26, 0.96);
    border: 1px solid rgba(51, 204, 255, 0.35);
    border-radius: 18px;
    padding: 18px 20px;
}
.title {
    color: #33ccff;
    font-size: 12pt;
    font-weight: bold;
    letter-spacing: 1px;
}
.row {
    padding: 9px 14px;
    border-radius: 11px;
    color: #b9b9b9;
    font-size: 11pt;
}
.row.selected {
    background: linear-gradient(45deg, rgba(51,204,255,0.22), rgba(0,255,153,0.22));
    color: #ffffff;
    font-weight: bold;
}
.hint { color: #6f6f6f; font-size: 9pt; }
"""


# --------------------------------------------------------------------------
# PipeWire plumbing (pactl only -- no GTK needed, so presses stay cheap)
# --------------------------------------------------------------------------

def pactl(*args, parse_json=False):
    """Run pactl and return stdout, optionally parsed as JSON."""
    cmd = ["pactl"]
    if parse_json:
        cmd += ["-f", "json"]
    cmd += list(args)
    try:
        out = subprocess.run(
            cmd, capture_output=True, text=True, timeout=5, check=True
        ).stdout
    except (subprocess.SubprocessError, OSError):
        return [] if parse_json else ""
    if not parse_json:
        return out.strip()
    try:
        return json.loads(out)
    except json.JSONDecodeError:
        return []


def list_devices(kind):
    """[(name, description)] of selectable devices; monitor sources excluded."""
    devices = []
    for dev in pactl("list", KINDS[kind]["list"], parse_json=True):
        props = dev.get("properties") or {}
        if props.get("device.class") == "monitor":
            continue
        desc = dev.get("description") or dev.get("name") or "?"
        if desc in EXCLUDE or not dev.get("name"):
            continue
        devices.append((dev["name"], desc))
    return devices


def commit(kind, name):
    """Make `name` the default device and drag existing streams over to it."""
    spec = KINDS[kind]
    pactl(spec["set_default"], name)
    for line in pactl("list", "short", spec["streams"]).splitlines():
        stream_id = line.split("\t", 1)[0].strip()
        if stream_id.isdigit():
            pactl(spec["move"], stream_id, name)


def focused_connector():
    """Connector name (e.g. HDMI-A-1) of the monitor Hyprland has focused."""
    try:
        out = subprocess.run(
            ["hyprctl", "-j", "monitors"], capture_output=True, text=True, timeout=2
        ).stdout
        for mon in json.loads(out):
            if mon.get("focused"):
                return mon.get("name")
    except (subprocess.SubprocessError, OSError, json.JSONDecodeError):
        pass
    return None


# --------------------------------------------------------------------------
# Press relay: one overlay process owns the socket, later presses just poke it
# --------------------------------------------------------------------------

def send_press(path):
    """Poke a running overlay. True if one was actually listening."""
    try:
        client = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
        client.connect(path)
        client.send(b"next")
        client.close()
        return True
    except OSError:
        return False


def bind_server(path):
    """Claim the overlay socket, or None if another instance owns it.

    A crash can leave the socket file behind with nothing listening; that one is
    safe to clear. A socket someone is still listening on never gets unlinked,
    otherwise two presses racing at startup would each end up with an overlay.
    """
    server = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
    try:
        server.bind(path)
        return server
    except OSError as exc:
        if exc.errno != errno.EADDRINUSE:
            server.close()
            raise
    if send_press(path):  # live owner -- our press has been delivered
        server.close()
        return None
    try:
        os.unlink(path)  # stale leftover
    except OSError:
        pass
    try:
        server.bind(path)
        return server
    except OSError:
        server.close()
        return None


# --------------------------------------------------------------------------
# Overlay (GTK is imported lazily, only by the process that owns the socket)
# --------------------------------------------------------------------------

def load_gtk():
    """Import GTK into module globals. Only the overlay process pays for this."""
    global Gdk, Gio, GLib, Gtk, LayerShell, fd_add_full
    import gi

    gi.require_version("Gtk", "4.0")
    gi.require_version("Gdk", "4.0")
    gi.require_version("Gtk4LayerShell", "1.0")
    from gi.repository import Gdk, Gio, GLib, Gtk
    from gi.repository import Gtk4LayerShell as LayerShell

    try:  # GLib.unix_fd_add_full is deprecated in favour of the GLibUnix namespace
        gi.require_version("GLibUnix", "2.0")
        from gi.repository import GLibUnix

        fd_add_full = GLibUnix.fd_add_full
    except (ValueError, ImportError):
        fd_add_full = GLib.unix_fd_add_full


class Switcher:
    def __init__(self, kind, devices, index, server):
        self.kind = kind
        self.devices = devices
        self.index = index
        self.server = server
        self.rows = []
        self.timer = None
        self.app = Gtk.Application(
            application_id="dev.krshrimali.AudioSwitch",
            flags=Gio.ApplicationFlags.NON_UNIQUE,
        )
        self.app.connect("activate", self.on_activate)

    def on_activate(self, app):
        provider = Gtk.CssProvider()
        provider.load_from_data(CSS)
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        window = Gtk.Window(application=app)
        LayerShell.init_for_window(window)
        LayerShell.set_layer(window, LayerShell.Layer.OVERLAY)
        # NONE means the overlay never takes focus, so the keybind keeps working
        # and a fullscreen game underneath does not lose input.
        LayerShell.set_keyboard_mode(window, LayerShell.KeyboardMode.NONE)
        LayerShell.set_namespace(window, "audio-switch")

        want = focused_connector()
        if want:
            monitors = Gdk.Display.get_default().get_monitors()
            for i in range(monitors.get_n_items()):
                mon = monitors.get_item(i)
                if mon.get_connector() == want:
                    LayerShell.set_monitor(window, mon)
                    break

        spec = KINDS[self.kind]
        card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        card.add_css_class("card")
        card.set_size_request(460, -1)

        header = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        header.set_margin_bottom(10)
        icon = Gtk.Image.new_from_icon_name(spec["icon"])
        icon.set_pixel_size(20)
        header.append(icon)
        title = Gtk.Label(label=spec["title"], xalign=0.0)
        title.add_css_class("title")
        header.append(title)
        card.append(header)

        for _, desc in self.devices:
            label = Gtk.Label(label=desc, xalign=0.0)
            label.add_css_class("row")
            label.set_ellipsize(3)  # Pango.EllipsizeMode.END
            card.append(label)
            self.rows.append(label)

        hint = Gtk.Label(label="press again to cycle", xalign=0.0)
        hint.add_css_class("hint")
        hint.set_margin_top(10)
        card.append(hint)

        window.set_child(card)
        self.refresh()
        window.present()

        fd_add_full(
            GLib.PRIORITY_DEFAULT,
            self.server.fileno(),
            GLib.IOCondition.IN,
            self.on_press,
        )
        self.restart_timer()

    def refresh(self):
        for i, row in enumerate(self.rows):
            if i == self.index:
                row.add_css_class("selected")
            else:
                row.remove_css_class("selected")

    def on_press(self, fd, condition):
        # Drain everything queued since the last redraw so a burst of presses
        # advances once per press rather than being coalesced into one step.
        presses = 0
        while True:
            try:
                if not self.server.recv(64, socket.MSG_DONTWAIT):
                    break
                presses += 1
            except (BlockingIOError, OSError):
                break
        if presses:
            self.index = (self.index + presses) % len(self.devices)
            self.refresh()
            self.restart_timer()
        return True

    def restart_timer(self):
        if self.timer is not None:
            GLib.source_remove(self.timer)
        self.timer = GLib.timeout_add(COMMIT_DELAY_MS, self.on_commit)

    def on_commit(self):
        self.timer = None
        commit(self.kind, self.devices[self.index][0])
        self.app.quit()
        return False

    def run(self):
        self.app.run([])


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in KINDS:
        print(f"usage: {os.path.basename(sys.argv[0])} sink|source", file=sys.stderr)
        return 2
    kind = sys.argv[1]

    runtime = os.environ.get("XDG_RUNTIME_DIR") or f"/tmp/{os.getuid()}"
    path = os.path.join(runtime, f"hypr-audio-switch-{kind}.sock")

    # An overlay is already up: this press just advances it and we are done.
    if send_press(path):
        return 0

    server = bind_server(path)
    if server is None:
        # Another press won the race and is bringing the overlay up; bind_server
        # already delivered our press to it.
        return 0

    try:
        devices = list_devices(kind)
        if not devices:
            subprocess.run(
                ["notify-send", "-a", "audio-switch",
                 f"No {KINDS[kind]['title'].lower()} devices found"],
                check=False,
            )
            return 1

        current = pactl(KINDS[kind]["get_default"])
        start = next((i for i, (n, _) in enumerate(devices) if n == current), -1)
        index = (start + 1) % len(devices)

        load_gtk()
        Switcher(kind, devices, index, server).run()
    finally:
        server.close()
        try:
            os.unlink(path)
        except OSError:
            pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
