#!/usr/bin/env bash
# Keyboard "pinch zoom": scales the whole desktop around the cursor via
# Hyprland's built-in magnifier (cursor:zoom_factor).
#
# Usage: zoom.sh {in|out|reset}

STEP=1.08   # per-repeat multiplier; held key repeats make it feel continuous
MAX=8

cur=$(hyprctl getoption cursor:zoom_factor -j | jq -r .float)

case "${1:-}" in
    in)    new=$(awk -v c="$cur" -v s="$STEP" -v m="$MAX" 'BEGIN { n = c * s; if (n > m) n = m; print n }') ;;
    out)   new=$(awk -v c="$cur" -v s="$STEP" 'BEGIN { n = c / s; if (n < 1) n = 1; print n }') ;;
    reset) new=1 ;;
    *)     echo "Usage: $(basename "$0") {in|out|reset}" >&2; exit 2 ;;
esac

hyprctl keyword cursor:zoom_factor "$new" >/dev/null
