#!/bin/bash
# Usage: workspace.sh <switch|move> <1-10>
# Dispatches to per-monitor workspace based on focused monitor name.
# Monitor name → workspace offset mapping must match hyprland.conf assignments.
#
# This build's hyprctl parses `dispatch <name> <args>` as Lua, so raw
# dispatcher strings (e.g. `hyprctl dispatch workspace 12`) fail. Use
# `hyprctl eval` with the hl.dsp Lua API instead.

ACTION=$1
NUM=$2

MONITOR_NAME=$(hyprctl monitors -j | python3 -c "
import json, sys
monitors = json.load(sys.stdin)
for m in monitors:
    if m['focused']:
        print(m['name'])
        break
")

case "$MONITOR_NAME" in
    HDMI-A-3) OFFSET=0  ;;  # middle, 2K landscape (main)
    DP-3)     OFFSET=10 ;;  # left,   2K portrait
    HDMI-A-4) OFFSET=20 ;;  # right,  1920x1080 portrait
    *)        OFFSET=0; notify-send "Hyprland workspace routing" "Unknown focused monitor: $MONITOR_NAME. Falling back to workspaces 1-10." ;;
esac

TARGET=$((OFFSET + NUM))

# Workspace rules only bind a workspace to its monitor at creation. If a monitor
# was unplugged (e.g. switched to the Mac), its workspaces migrated elsewhere and
# stay there, so focusing them would jump to the wrong screen. Pull it home first.
CURRENT_MON=$(hyprctl workspaces -j | python3 -c "
import json, sys
for w in json.load(sys.stdin):
    if w['id'] == $TARGET:
        print(w['monitor'])
        break
")
if [ -n "$CURRENT_MON" ] && [ "$CURRENT_MON" != "$MONITOR_NAME" ]; then
    hyprctl eval "return hl.dispatch(hl.dsp.workspace.move({workspace = $TARGET, monitor = \"$MONITOR_NAME\"}))" >/dev/null
fi

if [ "$ACTION" = "move" ]; then
    hyprctl eval "return hl.dispatch(hl.dsp.window.move({workspace = $TARGET}))"
else
    hyprctl eval "return hl.dispatch(hl.dsp.focus({workspace = $TARGET}))"
fi
