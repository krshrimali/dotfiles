#!/bin/bash
# Usage: spotlight.sh {toggle|grow|shrink}
# Controls the spotlight.py overlay daemon (one instance at a time).

PIDFILE="$XDG_RUNTIME_DIR/hypr-spotlight.pid"
SCRIPT="$HOME/.config/hypr/scripts/spotlight.py"

running_pid() {
    if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
        cat "$PIDFILE"
    fi
}

case "${1:-}" in
    toggle)
        pid=$(running_pid)
        if [ -n "$pid" ]; then
            kill "$pid"
            rm -f "$PIDFILE"
        else
            # gtk4-layer-shell must be preloaded ahead of libwayland-client or
            # layer surface init silently fails (upstream linking quirk).
            setsid env LD_PRELOAD=/usr/lib/libgtk4-layer-shell.so python3 "$SCRIPT" >/tmp/hypr-spotlight.log 2>&1 &
            echo $! > "$PIDFILE"
        fi
        ;;
    grow)
        pid=$(running_pid)
        [ -n "$pid" ] && kill -USR1 "$pid"
        ;;
    shrink)
        pid=$(running_pid)
        [ -n "$pid" ] && kill -USR2 "$pid"
        ;;
    *)
        echo "Usage: $(basename "$0") {toggle|grow|shrink}" >&2
        exit 2
        ;;
esac
