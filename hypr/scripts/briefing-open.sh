#!/usr/bin/env bash
# Open today's briefing in a floating, centred reader (glow pager in kitty).
# Bound to Super+N. Falls back to bat/less if glow is missing.
set -euo pipefail

DIGEST="$HOME/.local/share/briefings/today.md"

if [[ ! -f "$DIGEST" ]]; then
  notify-send --app-name="Briefing" --icon=dialog-information \
    "No briefing yet" "Run: systemctl --user start briefing.service"
  exit 0
fi

if command -v glow >/dev/null 2>&1; then
  reader=(glow -p -w 100 "$DIGEST")
elif command -v bat >/dev/null 2>&1; then
  reader=(bat --style=plain --paging=always -l markdown "$DIGEST")
else
  reader=(less -R "$DIGEST")
fi

# --class lets the Hyprland window rule float + centre it.
exec kitty --class briefing --title "Daily Briefing" "${reader[@]}"
