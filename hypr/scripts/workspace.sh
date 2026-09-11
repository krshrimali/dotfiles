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
    HDMI-A-2) OFFSET=0  ;;  # right,  1920x1080 portrait (transform 3)
    DP-2)     OFFSET=10 ;;  # middle, 2K landscape
    HDMI-A-1) OFFSET=20 ;;  # left,   2K landscape
    *)        OFFSET=0; notify-send "Hyprland workspace routing" "Unknown focused monitor: $MONITOR_NAME. Falling back to workspaces 1-10." ;;
esac

TARGET=$((OFFSET + NUM))

if [ "$ACTION" = "move" ]; then
    hyprctl eval "return hl.dispatch(hl.dsp.window.move({workspace = $TARGET}))"
else
    hyprctl eval "return hl.dispatch(hl.dsp.focus({workspace = $TARGET}))"
fi
