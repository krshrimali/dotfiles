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
-- special workspace + on_created_empty spawn.
hl.window_rule({
    name   = "gpu-observer-float",
    match  = { class = "gpu-observer" },
    float  = true,
    size   = { "1200", "750" },
    center = true,
    rounding = 16,
    opacity  = "0.92 override 0.92",
})

-- Force Counter-Strike 2 to launch on DP-2 (middle 2K monitor) in fullscreen
hl.window_rule({
    name       = "cs2-fullscreen",
    match      = { class = "^cs2$" },
    monitor    = "DP-2",
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
