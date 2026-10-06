#!/usr/bin/env bash
# Per-monitor zoom state for Hyprland's native cursor magnifier.

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/hypr-zoom"
LAST_MONITOR="$STATE_DIR/active-monitor"
BASE_STEP=1.06
FAST_STEP=1.16
FAST_WINDOW_MS=120
STALE_MS=800
MIN=1
MAX=8

mkdir -p "$STATE_DIR"
now_ms=$(($(date +%s%N) / 1000000))

live_zoom() {
    hyprctl getoption cursor:zoom_factor -j | jq -r .float
}

active_monitor() {
    hyprctl monitors -j | jq -er '.[] | select(.focused == true) | .name'
}

state_file() {
    local safe_name
    safe_name=$(printf '%s' "$1" | sed 's/[^[:alnum:]_.-]/_/g')
    printf '%s/%s.state' "$STATE_DIR" "$safe_name"
}

write_state() {
    printf '%s %s\n' "$1" "$2" > "$3"
}

apply_zoom() {
    hyprctl eval "return hl.config({cursor = {zoom_factor = $1}})" >/dev/null
}

case "${1:-}" in
    init)
        monitor=$(active_monitor) || exit 0
        state=$(state_file "$monitor")
        # Don't overwrite a remembered level on config reload.
        if [[ ! -f "$state" ]]; then
            write_state "$(live_zoom)" "$now_ms" "$state"
        fi
        printf '%s\n' "$monitor" > "$LAST_MONITOR"
        exit 0
        ;;
    switch)
        monitor="${2:-}"
        [[ -n "$monitor" ]] || exit 2

        # Save the output we just left, then restore the destination output's
        # own level. A monitor with no saved zoom starts at 1x.
        previous=""
        [[ -f "$LAST_MONITOR" ]] && read -r previous < "$LAST_MONITOR"
        if [[ -n "$previous" && "$previous" != "$monitor" ]]; then
            previous_state=$(state_file "$previous")
            if [[ ! -f "$previous_state" ]]; then
                write_state "$(live_zoom)" "$now_ms" "$previous_state"
            else
                # Keep script-saved zoom if Hyprland has already reset the
                # live factor at the boundary. Also capture pinch changes
                # while the live factor still carries a non-1x value.
                read -r saved _ < "$previous_state"
                current=$(live_zoom)
                if awk -v c="$current" -v s="$saved" 'BEGIN { exit !(c > 1.0001 && c != s) }'; then
                    write_state "$current" "$now_ms" "$previous_state"
                fi
            fi

            read -r previous_zoom _ < "$previous_state"
            if awk -v z="$previous_zoom" 'BEGIN { exit !(z > 1.0001) }'; then
                # Only block pointer crossings. A keyboard-driven focus change
                # leaves the pointer on the old output, outside the target box.
                read -r pointer_x pointer_y < <(hyprctl cursorpos -j | jq -r '[.x, .y] | @tsv')
                read -r target_x target_y target_w target_h < <(
                    hyprctl monitors -j | jq -r --arg name "$monitor" '.[] | select(.name == $name) | [.x, .y, .width, .height] | @tsv'
                )
                if awk -v px="$pointer_x" -v py="$pointer_y" -v x="$target_x" -v y="$target_y" -v w="$target_w" -v h="$target_h" \
                    'BEGIN { exit !(px >= x && px < x+w && py >= y && py < y+h) }'; then
                    read -r old_x old_y old_w old_h < <(
                        hyprctl monitors -j | jq -r --arg name "$previous" '.[] | select(.name == $name) | [.x, .y, .width, .height] | @tsv'
                    )
                    clamp_x=$(awk -v p="$pointer_x" -v x="$old_x" -v w="$old_w" 'BEGIN { p=p<x?x:(p>=x+w?x+w-1:p); printf "%.0f", p }')
                    clamp_y=$(awk -v p="$pointer_y" -v y="$old_y" -v h="$old_h" 'BEGIN { p=p<y?y:(p>=y+h?y+h-1:p); printf "%.0f", p }')
                    hyprctl dispatch movecursor "$clamp_x" "$clamp_y" >/dev/null
                    hyprctl dispatch focusmonitor "$previous" >/dev/null
                    exit 0
                fi
            fi
        fi

        state=$(state_file "$monitor")
        target=1
        if [[ -f "$state" ]]; then
            read -r target _ < "$state"
            [[ -n "$target" ]] || target=1
        fi
        write_state "$target" "$now_ms" "$state"
        printf '%s\n' "$monitor" > "$LAST_MONITOR"
        apply_zoom "$target"
        ;;
    in|out)
        monitor=$(active_monitor) || exit 0
        state=$(state_file "$monitor")
        target=""
        last_ts=0
        if [[ -f "$state" ]]; then
            read -r target last_ts < "$state"
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
        write_state "$new" "$now_ms" "$state"
        printf '%s\n' "$monitor" > "$LAST_MONITOR"
        apply_zoom "$new"
        ;;
    reset)
        monitor=$(active_monitor) || exit 0
        state=$(state_file "$monitor")
        write_state 1 "$now_ms" "$state"
        printf '%s\n' "$monitor" > "$LAST_MONITOR"
        apply_zoom 1
        ;;
    *)
        echo "Usage: $(basename "$0") {in|out|reset|init|switch <monitor>}" >&2
        exit 2
        ;;
esac
