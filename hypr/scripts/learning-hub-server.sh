#!/usr/bin/env bash
# Keep the local Learning Hub (~/learning-hub) served at localhost:8420 across
# every Hyprland session. Idempotent: skips if something's already answering
# on the port (e.g. a manual `python3 -m http.server` left running).
set -u

PORT=8420
ROOT="$HOME/learning-hub"
LOG="${XDG_CACHE_HOME:-$HOME/.cache}/learning-hub-server.log"

mkdir -p "$ROOT"

if curl -sf "http://localhost:${PORT}/" >/dev/null 2>&1; then
    exit 0
fi

cd "$ROOT" && nohup python3 -m http.server "$PORT" >"$LOG" 2>&1 &
disown
