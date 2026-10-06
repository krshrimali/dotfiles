# Hyprland config notes

Personal notes for the custom keybinds and helper scripts in this config.
Everything lives in `hyprland.conf` (binds) and `scripts/` (helpers).

## Keybind discovery

| Key       | Action                                                                 |
|-----------|------------------------------------------------------------------------|
| `SUPER+/` | **Cheatsheet**: searchable list of every active bind (`keybinds.sh`)   |
| `SUPER+;` | **Runner**: pick a bind in rofi and execute it (`keybind-runner.sh`)   |

- `keybinds.sh` reads the *live* binds from `hyprctl binds -j`, so it includes
  runtime and submap binds (shown as `[pan] h`, etc.). It decodes the modifier
  mask into `SUPER+CTRL+...`, aligns the columns, and opens a rofi fuzzy-search
  menu. Type to filter; ESC closes. Selecting an entry just dismisses the menu.
- `keybind-runner.sh` parses `hyprland.conf` with `hyprkeys`, shows the raw
  bind lines in rofi, and **dispatches the selected bind** — use it to trigger
  an action whose key you forgot.

## Desktop zoom (magnifier)

Built on Hyprland's `cursor:zoom_factor`, driven by `scripts/zoom.sh`.

| Key                       | Action                          |
|---------------------------|----------------------------------|
| `SUPER+=` (hold ok)       | Zoom in                         |
| `SUPER+-` (hold ok)       | Zoom out                        |
| `SUPER+Backspace`         | Reset zoom to 1×                |
| `SUPER+scroll`            | Zoom in/out; pointer steers center |
| Two-finger pinch          | Continuous trackpad zoom        |

`animations:enabled` is globally off in this config, so each zoom step is a
hard snap rather than an eased glide. `zoom.sh` compensates with velocity-
aware stepping: a burst of notches within 120ms of each other (held key or
fast scroll) escalates to a bigger per-step multiplier, while a single slow
notch stays fine-grained — the closest a notched scroll wheel gets to a
trackpad-style pinch. Max zoom is 8×.

`cursor:zoom_rigid = false` and `cursor:zoom_detached_camera = true` let the
pointer move freely. The magnified view pans when needed to keep the pointer
visible near the active monitor's edges. `SUPER+scroll` controls zoom directly;
it no longer switches workspaces. Each monitor keeps its own zoom level: an
unzoomed monitor starts at 1×, and returning to a zoomed monitor restores its
previous level. When zoomed above 1×, crossing a monitor boundary snaps the
pointer back to the zoomed monitor.

## Pan mode (move around while zoomed)

`SUPER+Z` enters a modal submap named `pan` (a notification confirms it).
While active, the keys below are captured; normal binds resume on exit.

| Key (in pan mode)   | Action                              |
|---------------------|-------------------------------------|
| `h/j/k/l`, arrows   | Pan (hold to keep panning)          |
| `=` / `-`           | Zoom in / out (no SUPER needed)     |
| `Backspace`         | Reset zoom to 1×                    |
| `ESC` or `SUPER+Z`  | Exit pan mode                       |

`scripts/pan.sh` pans by nudging the cursor 60 px per step (`STEP` at the top
of the script), which drags the magnified viewport along. Works with both
loose and rigid `zoom_rigid`.

## Monitor input switching

`SUPER+I` toggles the left BenQ GW2790QT (HDMI-A-2) between PC (HDMI) and Mac (USB-C)
over DDC/CI; `SUPER+SHIFT+I` forces it back to the PC. The script and full
notes live in `~/Documents/projects/monitor-switch/`.

## Other scripts in `scripts/`

| Script               | Purpose                                                    |
|----------------------|------------------------------------------------------------|
| `zoom.sh`            | Keyboard "pinch zoom" via `cursor:zoom_factor`             |
| `pan.sh`             | Keyboard panning for the zoomed desktop                    |
| `keybinds.sh`        | Searchable keybind cheatsheet (SUPER+/)                    |
| `keybind-runner.sh`  | Pick & execute a bind via rofi/hyprkeys (SUPER+;)          |
| `workspace.sh`       | Per-monitor workspace switch/move (SUPER+1..0)             |
| `launch-terminal.sh` | Terminal launcher (follows the focused shell's cwd)        |
| `briefing-*.sh/.py`  | Daily briefing fetch/notify/open (SUPER+N)                 |
| `fitness-nudge.sh`   | Wellbeing nudges; suppressed during fullscreen apps        |
