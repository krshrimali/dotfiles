-- Input configuration https://wiki.hypr.land/Configuring/Basics/Variables/#input

-- Keep the compositor-native workspace preview plugin loaded every session.
local pluginDir = "/home/krshrimali/.local/share/hyprland/plugins/"
hl.plugin.load(pluginDir .. "hyprexpo.so")

local loadedPlugins = {}
for _, plugin in ipairs(hl.get_loaded_plugins()) do
    loadedPlugins[plugin.name] = true
end

local hasHyprexpo = loadedPlugins.hyprexpo == true

local pluginConfig = {}
if hasHyprexpo then
    pluginConfig.hyprexpo = {
        overview_mode = "grid",
        columns = 4,
        rows = 4,
        gaps_in = 14,
        gaps_out = 32,
        bg_col = "rgba(111111ee)",
        workspace_method = "center current",
        skip_empty = 0,
        max_workspace = 30,
        show_cursor = 1,
        show_workspace_numbers = 1,
        show_pinned_windows = 1,
        border_width = 3,
        border_color_current = "rgb(8aadf4)",
        border_color_hover = "rgb(a6da95)",
    }
end

hl.config({
    binds = {
        -- Let high-resolution trackpad scroll events adjust zoom smoothly.
        scroll_event_delay = 50,
    },

    input = {
        kb_layout = "us",
        kb_variant = "",
        kb_model = "",
        kb_options = "caps:ctrl_modifier",
        kb_rules = "",

        follow_mouse = 0,

        sensitivity = 0.1, -- -1.0 - 1.0, 0 means no modification
        accel_profile = "flat",

        touchpad = {
            natural_scroll = true,
        },
    },

    plugin = pluginConfig,
})

-- See https://wiki.hypr.land/Configuring/Gestures/
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
-- Two-finger trackpad pinch zooms around the pointer.
hl.gesture({ fingers = 2, direction = "pinch", action = "cursor_zoom", zoom_level = 1, mode = "live" })

-- A 4x4 preview grid uses monitor-oriented tile geometry. The ten workspace
-- IDs assigned to each monitor fit within its tiles; unused tiles stay blank.
if hasHyprexpo then
    hl.gesture({ fingers = 3, direction = "up", action = function()
        hl.plugin.hyprexpo.expo("toggle")
    end })
    hl.gesture({ fingers = 3, direction = "down", action = function()
        hl.plugin.hyprexpo.expo("close")
    end })
end

-- Four-finger up keeps the Launchpad-style app launcher gesture.
hl.gesture({ fingers = 4, direction = "up", action = function()
    hl.dispatch(hl.dsp.exec_cmd(MENU))
end })

-- Keep independent magnification for each output. A new output starts at 1x;
-- returning to a previously zoomed output restores its saved level.
hl.exec_cmd("~/.config/hypr/scripts/zoom.sh init")
hl.on("monitor.focused", function(monitor)
    hl.exec_cmd("~/.config/hypr/scripts/zoom.sh switch " .. string.format("%q", monitor.name))
end)

-- Unedited placeholder from the default template — "epic-mouse-v1" doesn't match
-- a real device name, so this rule is a harmless no-op. Kept as-is from the backup.
hl.device({ name = "epic-mouse-v1", sensitivity = -0.5 })

-- Mac-like controls for the Apple Magic Trackpad.
hl.device({
    name = "apple-inc.-magic-trackpad",
    natural_scroll = true,
    tap_to_click = true,
    tap_and_drag = true,
    clickfinger_behavior = true,
    disable_while_typing = true,
    drag_3fg = 1,
    drag_lock = 1,
})
