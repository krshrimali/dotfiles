local mainMod = MAIN_MOD

---------------------------
---- WINDOW MANAGEMENT ----
---------------------------

hl.bind(mainMod .. " + Q",      hl.dsp.exec_cmd(TERMINAL))
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(TERMINAL))
hl.bind(mainMod .. " + W",      hl.dsp.window.close())
hl.bind(mainMod .. " + M",      hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd(
    "if command -v hyprshutdown >/dev/null 2>&1; then hyprshutdown; else hyprctl dispatch exit; fi"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(FILE_MANAGER))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(BROWSER))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(MENU))

-- Hyprland Settings TUI (monitors, appearance, animations, input, ...)
-- GTK/Python version still available at ~/.config/hypr/settings-app if wanted.
hl.bind(mainMod .. " + COMMA", hl.dsp.exec_cmd("~/.config/hypr/settings-tui/hyprland-settings-tui"))

-- Screenshot
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'))

-- Super+Shift+X: toggle the home-grown cursor-following spotlight
-- (scripts/spotlight.py -- dims every monitor, cuts a soft clear hole
-- around the mouse on whichever one it's on). Super+Shift+scroll resizes
-- the lit radius while it's on.
hl.bind(mainMod .. " + SHIFT + X", hl.dsp.exec_cmd("~/.config/hypr/scripts/spotlight.sh toggle"))
hl.bind(mainMod .. " + SHIFT + mouse_down", hl.dsp.exec_cmd("~/.config/hypr/scripts/spotlight.sh grow"))
hl.bind(mainMod .. " + SHIFT + mouse_up",   hl.dsp.exec_cmd("~/.config/hypr/scripts/spotlight.sh shrink"))

-- Super+Alt+X: toggle the wayscriber annotation/zoom overlay (moved off
-- Shift+X to make room for the native spotlight above). No true
-- cursor-following spotlight in wayscriber yet -- that tool only exists
-- on its unreleased main branch as of v0.9.22, the newest AUR release.
-- Once open: Ctrl+Alt+scroll zooms, Ctrl+Alt+L locks the view.
hl.bind(mainMod .. " + ALT + X", hl.dsp.exec_cmd("wayscriber --daemon-toggle"))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())        -- dwindle
hl.bind(mainMod .. " + T", hl.dsp.layout("togglesplit"))  -- dwindle

-- Super+D opens the workspace preview grid (click a workspace to switch).
hl.bind(mainMod .. " + D", function()
    if hl.plugin.hyprexpo then
        hl.plugin.hyprexpo.expo("toggle")
    else
        hl.dispatch(hl.dsp.exec_cmd("rofi -show window"))
    end
end)

-- Keybind viewer
hl.bind(mainMod .. " + semicolon", hl.dsp.exec_cmd("~/.config/hypr/scripts/keybind-runner.sh"))

-- Daily briefing: Super+N opens today's digest; Super+SHIFT+N refreshes it now
hl.bind(mainMod .. " + N",         hl.dsp.exec_cmd("~/.config/hypr/scripts/briefing-open.sh"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("systemctl --user start briefing.service"))

-- Monitor input: Super+I toggles right GW2790QT between PC (HDMI) and Mac (USB-C);
-- Super+SHIFT+I forces it back to the PC
hl.bind(mainMod .. " + I",         hl.dsp.exec_cmd("~/Documents/projects/monitor-switch/monitor-switch.sh toggle"))
hl.bind(mainMod .. " + SHIFT + I", hl.dsp.exec_cmd("~/Documents/projects/monitor-switch/monitor-switch.sh pc"))

-- Software KVM seat handoff (keyboard way; the mouse way is crossing the BenQ's
-- right edge). Super+O sends keyboard/mouse to the Mac, Super+SHIFT+O brings it back.
hl.bind(mainMod .. " + O",         hl.dsp.exec_cmd("~/Documents/projects/monitor-switch/kvm-seat.sh to-mac"))
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd("~/Documents/projects/monitor-switch/kvm-seat.sh to-pc"))

-- Keyboard "gestures"
-- Workspace swipe: hold to scrub through workspaces
hl.bind(mainMod .. " + bracketright", hl.dsp.focus({ workspace = "e+1" }), { repeating = true })
hl.bind(mainMod .. " + bracketleft",  hl.dsp.focus({ workspace = "e-1" }), { repeating = true })
-- Move the current workspace to the adjacent monitor (not just its window).
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.workspace.move({ monitor = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.workspace.move({ monitor = "right" }))
-- Window swipe: cycle windows on the current workspace
hl.bind(mainMod .. " + Tab",         hl.dsp.window.cycle_next())
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.exec_raw("cyclenext", "prev"))
-- Trackpad-style desktop zoom: hold SUPER, scroll to change magnification,
-- and move the pointer to steer the magnified center.
hl.bind(mainMod .. " + equal",     hl.dsp.exec_cmd("~/.config/hypr/scripts/zoom.sh in"),  { repeating = true })
hl.bind(mainMod .. " + minus",     hl.dsp.exec_cmd("~/.config/hypr/scripts/zoom.sh out"), { repeating = true })
hl.bind(mainMod .. " + BackSpace", hl.dsp.exec_cmd("~/.config/hypr/scripts/zoom.sh reset"))
hl.bind(mainMod .. " + mouse_down", hl.dsp.exec_cmd("~/.config/hypr/scripts/zoom.sh in"))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.exec_cmd("~/.config/hypr/scripts/zoom.sh out"))

-- Keybind cheatsheet (SUPER+/): searchable list of all active binds in rofi
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd("~/.config/hypr/scripts/keybinds.sh"))

----------------------
---- RESIZE MODE  ----
----------------------
-- SUPER+ALT+R: modal submap for resizing without holding CTRL each time.
-- hjkl/arrows resize, ESC or SUPER+ALT+R exits.
-- (SUPER+SHIFT+R is already taken by move-to-scratchpad, hence ALT here.)
hl.bind(mainMod .. " + ALT + R", hl.dsp.submap("resize"))
hl.bind(mainMod .. " + ALT + R", hl.dsp.exec_cmd(
    'notify-send -t 2000 "Resize mode" "hjkl/arrows resize, ESC exits"'))

hl.define_submap("resize", "reset", function()
    local STEP = 50
    local function grow(x, y)
        return hl.dsp.window.resize({ x = x, y = y, relative = true })
    end
    hl.bind("h",     grow(-STEP, 0), { repeating = true })
    hl.bind("l",     grow(STEP, 0),  { repeating = true })
    hl.bind("k",     grow(0, -STEP), { repeating = true })
    hl.bind("j",     grow(0, STEP),  { repeating = true })
    hl.bind("left",  grow(-STEP, 0), { repeating = true })
    hl.bind("right", grow(STEP, 0),  { repeating = true })
    hl.bind("up",    grow(0, -STEP), { repeating = true })
    hl.bind("down",  grow(0, STEP),  { repeating = true })
    hl.bind("escape", hl.dsp.submap("reset"))
    hl.bind("escape", hl.dsp.exec_cmd('notify-send -t 1500 "Resize mode" "off"'))
    hl.bind(mainMod .. " + ALT + R", hl.dsp.submap("reset"))
    hl.bind(mainMod .. " + ALT + R", hl.dsp.exec_cmd('notify-send -t 1500 "Resize mode" "off"'))
end)

-------------------
---- PAN MODE  ----
-------------------
-- SUPER+Z: modal submap to move around while zoomed.
-- hjkl/arrows pan, =/- zoom, Backspace resets zoom, ESC or SUPER+Z exits.
hl.bind(mainMod .. " + Z", hl.dsp.submap("pan"))
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd(
    'notify-send -t 2000 "Pan mode" "hjkl/arrows pan, =/- zoom, ESC exits"'))

hl.define_submap("pan", "reset", function()
    hl.bind("h",     hl.dsp.exec_cmd("~/.config/hypr/scripts/pan.sh left"),  { repeating = true })
    hl.bind("j",     hl.dsp.exec_cmd("~/.config/hypr/scripts/pan.sh down"),  { repeating = true })
    hl.bind("k",     hl.dsp.exec_cmd("~/.config/hypr/scripts/pan.sh up"),    { repeating = true })
    hl.bind("l",     hl.dsp.exec_cmd("~/.config/hypr/scripts/pan.sh right"), { repeating = true })
    hl.bind("left",  hl.dsp.exec_cmd("~/.config/hypr/scripts/pan.sh left"),  { repeating = true })
    hl.bind("down",  hl.dsp.exec_cmd("~/.config/hypr/scripts/pan.sh down"),  { repeating = true })
    hl.bind("up",    hl.dsp.exec_cmd("~/.config/hypr/scripts/pan.sh up"),    { repeating = true })
    hl.bind("right", hl.dsp.exec_cmd("~/.config/hypr/scripts/pan.sh right"), { repeating = true })
    hl.bind("equal", hl.dsp.exec_cmd("~/.config/hypr/scripts/zoom.sh in"),   { repeating = true })
    hl.bind("minus", hl.dsp.exec_cmd("~/.config/hypr/scripts/zoom.sh out"),  { repeating = true })
    hl.bind("BackSpace", hl.dsp.exec_cmd("~/.config/hypr/scripts/zoom.sh reset"))
    hl.bind("escape", hl.dsp.submap("reset"))
    hl.bind("escape", hl.dsp.exec_cmd('notify-send -t 1500 "Pan mode" "off"'))
    hl.bind(mainMod .. " + Z", hl.dsp.submap("reset"))
    hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd('notify-send -t 1500 "Pan mode" "off"'))
end)

--------------------------------
---- FOCUS / MOVE / RESIZE  ----
--------------------------------

-- Move focus with mainMod + hjkl (vim-style)
hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "down" }))

-- Move windows with mainMod + SHIFT + hjkl
hl.bind(mainMod .. " + SHIFT + h", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + l", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + k", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + j", hl.dsp.window.move({ direction = "d" }))

-- Resize windows with mainMod + CTRL + hjkl
hl.bind(mainMod .. " + CONTROL + h", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CONTROL + l", hl.dsp.window.resize({ x = 50,  y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CONTROL + k", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CONTROL + j", hl.dsp.window.resize({ x = 0, y = 50,  relative = true }), { repeating = true })

-- Switch workspaces with mainMod + [0-9] (per focused monitor, i3-style)
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.exec_cmd("~/.config/hypr/scripts/workspace.sh switch " .. i))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.exec_cmd("~/.config/hypr/scripts/workspace.sh move " .. i))
end

-- Special workspaces (scratchpad + GPU observer)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(mainMod .. " + G",         hl.dsp.workspace.toggle_special("gpu-observer"))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag())
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize())

-- Middle-button drag: move with no modifier, resize with mainMod
-- Kept as a global (see config/windowrules.lua) so it can be disabled while
-- CS2 is focused, since CS2 uses middle-click in-game (scope/buy binds).
MMB_MOVE_BIND = hl.bind("mouse:274", hl.dsp.window.drag())
hl.bind(mainMod .. " + mouse:274", hl.dsp.window.resize())

---------------------------
---- HARDWARE CONTROLS ----
---------------------------

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Ratatui audio output picker (Super+F8)
hl.bind(mainMod .. " + F8", hl.dsp.exec_cmd(
    "kitty --class sound-switcher -e ~/.config/hypr/sound_switcher/target/release/sound_switcher"))

-- Cycle the default output/input device with an on-screen picker (Super+A for
-- speakers, Super+Shift+A for the mic). Each press advances the highlight; the
-- device you stop on is committed ~1.5s later, so streams are moved once rather
-- than at every step along the way.
hl.bind(mainMod .. " + A",         hl.dsp.exec_cmd("~/.config/hypr/scripts/audio-switch.py sink"))
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd("~/.config/hypr/scripts/audio-switch.py source"))

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
