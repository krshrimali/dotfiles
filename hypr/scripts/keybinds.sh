#!/usr/bin/env bash
# Searchable cheatsheet of all active Hyprland keybinds (bound to SUPER+/).
# Reads the live binds from hyprctl (so runtime/submap binds are included),
# decodes the modifier mask, and shows everything in a rofi fuzzy-search menu.
# Submap binds are prefixed with their mode, e.g. "[pan] h".
#
# Usage: keybinds.sh

list=$(hyprctl binds -j | jq -r '
  .[]
  | ([ (if ((.modmask/64|floor)%2==1) then "SUPER" else empty end),
       (if ((.modmask/4|floor)%2==1)  then "CTRL"  else empty end),
       (if ((.modmask/8|floor)%2==1)  then "ALT"   else empty end),
       (if  ((.modmask%2)==1)         then "SHIFT" else empty end)
     ] | join("+")) as $mods
  | (if $mods == "" then .key else $mods + "+" + .key end) as $combo
  | (if .submap != "" then "[" + .submap + "] " else "" end) as $ctx
  | (.dispatcher + (if .arg != "" then " " + .arg else "" end)) as $action
  | "\($ctx + $combo)\t\($action)"
' | sed -e "s|$HOME|~|g" -e "s|~/.config/hypr/scripts/||g" \
  | sort | column -t -s $'\t')

rofi -dmenu -i -p "keybinds" <<< "$list" >/dev/null
