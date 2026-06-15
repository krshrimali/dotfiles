#!/usr/bin/env bash
# Apply brightness/contrast profiles to all three monitors over DDC/CI.
# Monitors are addressed by serial so i2c renumbering can't break it. The
# right monitor may be with the Mac (connector off) — failures there are
# ignored so the other two still switch.
#
# Usage: monitor-profile.sh {day|night|movie|cycle|status}

set -u

MONITORS="JBM0441401Q M7P00526019 V8P00596019"  # GW2480 left, GW2790QT mid, GW2790QT right
VCP_BRIGHTNESS=10
VCP_CONTRAST=12
STATE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/monitor-profile.state"

profile_values() {
    # "<brightness> <contrast>" per profile; tweak to taste
    case "$1" in
        day)   echo "80 50" ;;
        night) echo "25 45" ;;
        movie) echo "10 55" ;;
        *)     return 1 ;;
    esac
}

apply() {
    local profile=$1 b c sn
    read -r b c < <(profile_values "$profile")
    for sn in $MONITORS; do
        (
            ddcutil --sn "$sn" --noverify setvcp "$VCP_BRIGHTNESS" "$b" 2>/dev/null
            ddcutil --sn "$sn" --noverify setvcp "$VCP_CONTRAST" "$c" 2>/dev/null
        ) &
    done
    wait
    echo "$profile" > "$STATE_FILE"
    command -v notify-send >/dev/null 2>&1 && \
        notify-send -t 2000 "Monitor profile" "$profile (brightness $b, contrast $c)"
    echo "$profile"
}

case "${1:-cycle}" in
    day|night|movie)
        apply "$1"
        ;;
    cycle)
        cur=$(cat "$STATE_FILE" 2>/dev/null || echo "")
        case "$cur" in
            day)   apply night ;;
            night) apply movie ;;
            *)     apply day ;;
        esac
        ;;
    status)
        cat "$STATE_FILE" 2>/dev/null || echo unknown
        ;;
    *)
        echo "Usage: $(basename "$0") {day|night|movie|cycle|status}" >&2
        exit 2
        ;;
esac
