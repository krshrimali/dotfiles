#!/bin/bash
# Usage: workspace.sh <switch|move> <1-10>
# Dispatches to per-monitor workspace based on focused monitor name.
# Monitor name → workspace offset mapping must match hyprland.conf assignments.

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
    HDMI-A-2) OFFSET=0  ;;
    DP-1)     OFFSET=10 ;;
    HDMI-A-1) OFFSET=20 ;;
    *)        OFFSET=0; notify-send "Hyprland workspace routing" "Unknown focused monitor: $MONITOR_NAME. Falling back to workspaces 1-10." ;;
esac

TARGET=$((OFFSET + NUM))

if [ "$ACTION" = "move" ]; then
    hyprctl dispatch movetoworkspace "$TARGET"
else
    hyprctl dispatch workspace "$TARGET"
fi
