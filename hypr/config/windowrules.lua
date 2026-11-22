-- Window rules https://wiki.hypr.land/Configuring/Basics/Window-Rules/

hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})

hl.layer_rule({
    name = "noctalia",
    match = { namespace = "noctalia-background-.*$" },
    ignore_alpha = 0.5,
    blur = true,
    blur_popups = true,
})

-- GPU Observer (Super+G): floating panel, see config/workspaces.lua for the
-- special workspace + workspace.created spawn.
hl.window_rule({
    name   = "gpu-observer-float",
    match  = { class = "gpu-observer" },
    float  = true,
    size   = { "1200", "750" },
    center = true,
    rounding = 16,
    opacity  = "0.92 override 0.92",
})

-- Force Counter-Strike 2 to launch on the main monitor (HDMI-A-3) in fullscreen
hl.window_rule({
    name       = "cs2-fullscreen",
    match      = { class = "^cs2$" },
    monitor    = "HDMI-A-3",
    fullscreen = true,
    float      = false,
    immediate  = true,
})

-- Disable the middle-click "move window" bind (MMB_MOVE_BIND, see
-- config/binds.lua) while CS2 is focused, since the game uses middle-click
-- itself (scope/buy binds) and shouldn't have it stolen by the compositor.
hl.on("window.active", function()
    local win = hl.get_active_window()
    local cs2_focused = win ~= nil and win.class == "cs2"
    MMB_MOVE_BIND:set_enabled(not cs2_focused)
end)

-- Floating, centred reader for the daily briefing (Super+N)
hl.window_rule({
    name   = "briefing-reader",
    match  = { class = "briefing" },
    float  = true,
    size   = { "900", "1000" },
    center = true,
    rounding = 16,
    opacity  = "0.96 override 0.96",
})

-- Webex: tile every window (main app, meetings, pre-join), it floats them all by default.
hl.window_rule({
    name  = "webex-tile",
    match = { class = "^([Ww]ebex)$" },
    float = false,
})

-- inkover control panel (inkover gui / Super+Alt+G): small floating window.
hl.window_rule({
    name   = "inkover-gui-float",
    match  = { class = "io.github.krshrimali.inkover.Gui" },
    float  = true,
    size   = { "640", "780" },
    center = true,
})

------------------------
---- APP HOMES      ----
------------------------
-- Some apps always open on a fixed monitor, wherever focus happens to be.
-- These rules only act when a window opens, so you can still drag a window
-- elsewhere afterwards. Workspace IDs follow config/workspaces.lua: 11-20 are
-- the left portrait monitor (DP-4), 21-30 the right portrait one (HDMI-A-4).

-- Chat + music: right portrait monitor, its workspace "1" (ID 21). "silent"
-- opens them in the background, so starting Discord doesn't pull focus or the
-- cursor away from the main monitor. With the portrait master layout they
-- stack top/bottom on that workspace.
hl.window_rule({
    name      = "home-chat-right",
    match     = { class = "^(discord|vesktop)$" },
    workspace = "21 silent",
})
hl.window_rule({
    name      = "home-music-right",
    match     = { class = "^([Ss]potify|YouTube Music|feishin)$" },
    workspace = "21 silent",
})

-- Browsers: left portrait monitor, on whichever workspace is active there.
-- This one does take focus, since you usually open a browser to use it.
hl.window_rule({
    name    = "home-browser-left",
    match   = { class = "^(Brave-browser|firefox|google-chrome)$" },
    monitor = "DP-4",
})
