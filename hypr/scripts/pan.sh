#!/usr/bin/env bash
# Keyboard panning for the zoomed desktop: nudges the cursor, which drags the
# magnified viewport along (works with both loose and rigid cursor:zoom_rigid).
#
# Usage: pan.sh {left|right|up|down}

STEP=60

read -r x y < <(hyprctl cursorpos -j | jq -r '"\(.x) \(.y)"')

case "${1:-}" in
    left)  x=$((x - STEP)) ;;
    right) x=$((x + STEP)) ;;
    up)    y=$((y - STEP)) ;;
    down)  y=$((y + STEP)) ;;
    *)     echo "Usage: $(basename "$0") {left|right|up|down}" >&2; exit 2 ;;
esac

hyprctl eval "return hl.dispatch(hl.dsp.cursor.move({x = $x, y = $y}))" >/dev/null
