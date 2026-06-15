#!/usr/bin/env bash
# Gentle wellbeing nudge: movement / posture / hydration / eye-breaks.
# - Suppressed while a fullscreen app is focused (gaming, e.g. CS2, or video).
# - Only fires during active hours.
# - Rotates through categories so it doesn't feel repetitive.
# Designed to be called on a timer (see fitness-nudge.timer).
set -euo pipefail

# ───── config ─────
ACTIVE_START=9          # 24h — no nudges before this
ACTIVE_END=22           # 24h — no nudges after this
STATE="$HOME/.local/state/fitness-nudge.idx"
# ──────────────────

hour=$(date +%-H)
if (( hour < ACTIVE_START || hour >= ACTIVE_END )); then
  exit 0
fi

# Suppress if the focused window is fullscreen (gaming / watching something).
if command -v hyprctl >/dev/null 2>&1; then
  fs=$(hyprctl activewindow -j 2>/dev/null | grep -o '"fullscreen": *[0-9]*' \
        | grep -o '[0-9]*$' || echo 0)
  cls=$(hyprctl activewindow -j 2>/dev/null \
        | grep -o '"class": *"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/' || echo "")
  if [[ "${fs:-0}" != "0" ]] || [[ "$cls" == "cs2" ]]; then
    exit 0
  fi
fi

# Rotating nudge pool. Each entry: "icon|title|body"
nudges=(
  "🧍|Stand & stretch|Roll your shoulders, reach for the ceiling. 30 seconds."
  "👀|20-20-20|Look at something 20 ft away for 20 seconds. Rest your eyes."
  "💧|Hydrate|Sip some water. Future-you says thanks."
  "🪑|Posture check|Sit back, shoulders down, feet flat, screen at eye level."
  "🚶|Move|Quick lap to the kitchen and back. Get the blood going."
  "🌬️|Breathe|Box breathing: in 4, hold 4, out 4, hold 4. Three rounds."
  "💪|Micro-set|10 squats or 10 desk push-ups. Done before the next build."
)

mkdir -p "$(dirname "$STATE")"
idx=$(cat "$STATE" 2>/dev/null || echo 0)
idx=$(( idx % ${#nudges[@]} ))
entry="${nudges[$idx]}"
echo $(( idx + 1 )) > "$STATE"

IFS='|' read -r icon title body <<<"$entry"

notify-send \
  --app-name="Wellbeing" \
  --icon=face-smile \
  --urgency=low \
  --expire-time=15000 \
  "${icon}  ${title}" "$body"
