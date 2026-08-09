#!/bin/bash
# Pick a keybind in rofi and dispatch it directly.
# Reads from `hyprctl binds -j` (the live, running bind table) rather than
# parsing a config file: hyprland.lua is the real source now, and hyprkeys
# (the previous approach) can only parse the classic .conf format, so it
# would silently go stale. This works no matter which config format is active.

mapfile -t binds < <(hyprctl binds -j | jq -r '
  .[]
  | select(.dispatcher != "")
  | ([ (if ((.modmask/64|floor)%2==1) then "SUPER" else empty end),
       (if ((.modmask/4|floor)%2==1)  then "CTRL"  else empty end),
       (if ((.modmask/8|floor)%2==1)  then "ALT"   else empty end),
       (if  ((.modmask%2)==1)         then "SHIFT" else empty end)
     ] | join("+")) as $mods
  | (if $mods == "" then .key else $mods + "+" + .key end) as $combo
  | (if .submap != "" then "[" + .submap + "] " else "" end) as $ctx
  | "\($ctx + $combo)\t\(.dispatcher)\t\(.arg)"
')

[ "${#binds[@]}" -eq 0 ] && exit 0

idx=$(printf '%s\n' "${binds[@]}" | awk -F'\t' '{printf "%-28s %-16s %s\n", $1, $2, $3}' \
  | sed -e "s|$HOME|~|g" -e "s|~/.config/hypr/scripts/||g" \
  | rofi -dmenu -p "Keybinds" -format i)
[ -z "$idx" ] && exit 0

IFS=$'\t' read -r _ dispatcher arg <<< "${binds[$idx]}"
hyprctl dispatch "$dispatcher" "$arg"
