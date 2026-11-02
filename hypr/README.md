# Hyprland config notes

Notes on the custom keybinds and helper scripts in this config (Hyprland 0.57,
Lua config).

## Where things live

| File | What it holds |
|---|---|
| [`hyprland.lua`](hyprland.lua) | Entry point; loads everything in `config/` |
| [`config/binds.lua`](config/binds.lua) | All keybinds and submaps (resize, pan) |
| [`config/inputs.lua`](config/inputs.lua) | Keyboard, trackpad and gestures |
| [`config/monitors.lua`](config/monitors.lua) → [`monitors.lua`](monitors.lua) | Monitor layout (written by `nwg-displays`) |
| [`config/workspaces.lua`](config/workspaces.lua) | Per-monitor workspace rules |
| [`config/animations.lua`](config/animations.lua) | Bezier and spring curves, animations |
| [`config/decorations.lua`](config/decorations.lua) | Gaps, borders, rounding, blur, cursor zoom |
| [`config/autostart.lua`](config/autostart.lua) | Startup programs |
| [`config/variables.lua`](config/variables.lua) | Default terminal, file manager, launcher, browser |
| [`scripts/`](scripts/) | Helper scripts (see below) |

## Finding keybinds

| Key | Action |
|---|---|
| `Super+/` | **Cheatsheet**: searchable list of every active bind (`keybinds.sh`) |
| `Super+;` | **Runner**: pick a bind in rofi and run it (`keybind-runner.sh`) |

Both read the live bind table from `hyprctl binds -j`, so they always match the
running config, including submap binds (shown as `[pan] h`, etc.).

## Desktop zoom

Uses Hyprland's `cursor:zoom_factor`, driven by `scripts/zoom.sh`.

| Key | Action |
|---|---|
| `Super+=` (can hold) | Zoom in |
| `Super+-` (can hold) | Zoom out |
| `Super+Backspace` | Reset to 1× |
| `Super+scroll` | Zoom in/out |
| Two-finger pinch | Smooth trackpad zoom |

- Several quick steps (within 120 ms of each other) zoom faster; a single
  step stays fine-grained. Max zoom is 8×.
- The `zoomFactor` animation eases each step.
- With `zoom_rigid = false` and `zoom_detached_camera = true`, the pointer moves
  freely and the view follows it near the edges.
- Each monitor keeps its own zoom level. While a monitor is zoomed, the pointer
  can't leave it.

## Pan mode

`Super+Z` enters the `pan` submap (a notification confirms it). Normal binds
come back when you leave.

| Key (in pan mode) | Action |
|---|---|
| `h/j/k/l` or arrows | Pan (can hold) |
| `=` / `-` | Zoom in / out |
| `Backspace` | Reset zoom |
| `Esc` or `Super+Z` | Leave pan mode |

`scripts/pan.sh` moves the cursor 60 px per step (`STEP` at the top of the
script), which drags the zoomed view along.

## Resize mode

`Super+Alt+R` enters the `resize` submap: `h/j/k/l` or arrows resize the
focused window, `Esc` or `Super+Alt+R` leaves. Outside the submap,
`Super+Ctrl+H/J/K/L` resizes directly.

## Workspaces and monitors

Each monitor has its own workspaces 1–10:

| Monitor | Position | Workspace IDs |
|---|---|---|
| `HDMI-A-3` | middle (main), landscape | 1–10 |
| `DP-3` | left, portrait | 11–20 |
| `HDMI-A-4` | right, portrait | 21–30 |

| Key | Action |
|---|---|
| `Super+1…0` | Switch to workspace on the current monitor (`workspace.sh`) |
| `Super+Shift+1…0` | Move window there |
| `Super+[` / `Super+]` | Previous / next workspace on this monitor |
| `Super+Shift+←/→` | Move the whole workspace to the next monitor |
| `Super+D` | Workspace overview |
| `Super+S` | Toggle the `magic` scratchpad |
| `Super+G` | Toggle the `gpu-observer` scratchpad |

When a monitor reconnects, its workspaces are moved back to it automatically.

The offsets in `workspaces.lua` and `scripts/workspace.sh` must match.

**Overview:** `Super+D` and a 3-finger swipe up use the Hyprexpo plugin if it's
loaded. If not, they toggle the `hyprexpose` daemon started in `autostart.lua`.
Hyprexpo has no 0.57 build yet.

## Trackpad gestures

| Gesture | Action |
|---|---|
| 3 fingers left/right | Change workspace |
| 3 fingers up | Workspace overview |
| 4 fingers up | App launcher |
| 2-finger pinch | Zoom |

## Sharing with the Mac

| Key | Action |
|---|---|
| `Super+I` | Switch the left BenQ GW2790QT between PC and Mac over DDC/CI |
| `Super+Shift+I` | Force it back to the PC |
| `Super+O` / `Super+Shift+O` | Move mouse and keyboard to the Mac / back (`lan-mouse`) |

These call scripts in a separate `~/Documents/projects/monitor-switch/` project
that isn't part of this repo.

## Other binds

| Key | Action |
|---|---|
| `Super+A` / `Super+Shift+A` | Switch audio output / input (`audio-switch.py`) |
| `Super+Shift+X` | Spotlight around the cursor; `Super+Shift+scroll` resizes it |
| `Super+Alt+X` | `wayscriber` annotation overlay |
| `Super+N` / `Super+Shift+N` | Open / refresh the daily briefing |
| `Super+,` | Settings TUI |
| `Super+M` / `Super+Shift+M` | Lock / log out |

## Scripts

| Script | Purpose |
|---|---|
| `zoom.sh` | Per-monitor zoom via `cursor:zoom_factor` |
| `pan.sh` | Keyboard panning while zoomed |
| `workspace.sh` | Per-monitor workspace switch/move |
| `keybinds.sh` | Searchable keybind cheatsheet |
| `keybind-runner.sh` | Pick and run a bind from rofi |
| `launch-terminal.sh` | Opens a terminal in the focused shell's folder |
| `audio-switch.py` | On-screen audio device switcher |
| `spotlight.sh` / `spotlight.py` | Dims the screens except a circle around the cursor |
| `monitor-profile.sh` | Brightness/contrast profiles for all monitors over DDC/CI |
| `briefing-*.sh/.py` | Daily briefing fetch, notify and open |
| `fitness-nudge.sh` | Wellbeing reminders; skipped while an app is fullscreen |
| `learning-hub-server.sh` | Serves `~/learning-hub` at `localhost:8420` |
