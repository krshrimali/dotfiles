#!/bin/bash
pid=$(hyprctl activewindow -j | jq '.pid')
# Traverse down to the leaf child process (the shell)
while true; do
    child=$(pgrep -P "$pid" | tail -1)
    [ -z "$child" ] && break
    pid=$child
done
cwd=$(readlink /proc/"$pid"/cwd 2>/dev/null || echo "$HOME")
kitty --working-directory "$cwd"
