#!/usr/bin/env bash
# Fire a short, readable desktop ping summarising today's briefing.
# Depth lives in the digest (Super+N) — this is deliberately terse.
set -euo pipefail

DIGEST="$HOME/.local/share/briefings/today.md"
[[ -f "$DIGEST" ]] || exit 0

# Count items per section for an at-a-glance summary.
papers=$(grep -c '^- \*\*\[' <<<"$(sed -n '/## 🔬/,/## 💻/p' "$DIGEST")" || true)
hn=$(grep -c '^- \*\*\[' <<<"$(sed -n '/## 💻/,/## 📦/p' "$DIGEST")" || true)
fresh=$(grep -c '🆕' "$DIGEST" || true)

body="🔬 ${papers} papers   💻 ${hn} HN stories"
[[ "${fresh:-0}" -gt 0 ]] && body+="   📦 ${fresh} new release(s)"
body+="\n<i>Super+N to read</i>"

notify-send \
  --app-name="Briefing" \
  --icon=accessories-dictionary \
  --urgency=normal \
  --expire-time=12000 \
  "🗞  Your daily briefing is ready" "$body"
