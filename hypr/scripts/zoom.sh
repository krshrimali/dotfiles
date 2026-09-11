#!/usr/bin/env bash
# "Pinch zoom": scales the whole desktop around the cursor via Hyprland's
# built-in magnifier (cursor:zoom_factor). Driven by SUPER+=/-, the scroll
# wheel (SUPER+SHIFT+CTRL+scroll), and pan mode.
#
# animations:enabled is globally off in this config, so zoom_factor changes
# are hard snaps with no eased glide to smooth them out. To still feel like
# a continuous pinch rather than a slider with big detents, each step's size
# depends on how fast repeats/notches are arriving: a burst (held key or fast
# scroll) escalates to a bigger per-step multiplier, a single deliberate
# notch stays fine-grained. The intended value is tracked in a state file
# rather than re-read from `hyprctl getoption` each time, since re-reading
# the live value on every call in a fast burst causes lost/undercounted
# steps (a spawned call can land before its predecessor is even applied).
#
# This build's hyprctl can't set live config values via `keyword` ("keyword
# can't work with non-legacy parsers. Use eval."), so we go through
# `hyprctl eval` and the hl.config Lua API instead.
#
# Usage: zoom.sh {in|out|reset}

STATE="${XDG_RUNTIME_DIR:-/tmp}/hypr-zoom-target"
BASE_STEP=1.06   # per-notch multiplier for a deliberate, slow scroll/press
FAST_STEP=1.16   # per-notch multiplier once notches arrive in a burst
FAST_WINDOW_MS=120  # a notch within this long of the last counts as a burst
STALE_MS=800        # older than this, don't trust the file: re-anchor to live
MIN=1
MAX=8

now_ms=$(($(date +%s%N) / 1000000))

live_zoom() {
    hyprctl getoption cursor:zoom_factor -j | jq -r .float
}

case "${1:-}" in
    in|out)
        target=""
        last_ts=0
        if [[ -f "$STATE" ]]; then
            read -r target last_ts < "$STATE"
        fi
        age=$((now_ms - last_ts))
        if [[ -z "$target" ]] || ((age > STALE_MS)); then
            target=$(live_zoom)
        fi
        if ((age < FAST_WINDOW_MS)); then
            step=$FAST_STEP
        else
            step=$BASE_STEP
        fi
        if [[ "$1" == in ]]; then
            new=$(awk -v t="$target" -v s="$step" -v m="$MAX" 'BEGIN { n = t * s; if (n > m) n = m; print n }')
        else
            new=$(awk -v t="$target" -v s="$step" -v m="$MIN" 'BEGIN { n = t / s; if (n < m) n = m; print n }')
        fi
        echo "$new $now_ms" > "$STATE"
        ;;
    reset)
        new=1
        rm -f "$STATE"
        ;;
    *)
        echo "Usage: $(basename "$0") {in|out|reset}" >&2
        exit 2
        ;;
esac

hyprctl eval "return hl.config({cursor = {zoom_factor = $new}})" >/dev/null
