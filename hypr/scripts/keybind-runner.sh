#!/bin/bash

selected=$(hyprkeys -b -r -c ~/.config/hypr/hyprland.conf | rofi -dmenu -p "Keybinds")
[ -z "$selected" ] && exit 0

# Format: bind = MODIFIERS KEY DISPATCHER ARG...
dispatcher=$(echo "$selected" | awk '{print $5}')
arg=$(echo "$selected" | awk '{for(i=6;i<=NF;i++) printf "%s%s", $i, (i<NF?" ":""); print ""}')

hyprctl dispatch "$dispatcher" "$arg"
