-- Input configuration https://wiki.hypr.land/Configuring/Basics/Variables/#input

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
            natural_scroll = false,
        },
    },
})

-- See https://wiki.hypr.land/Configuring/Gestures/
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
-- Two-finger trackpad pinch zooms around the pointer.
hl.gesture({ fingers = 2, direction = "pinch", action = "cursor_zoom", zoom_level = 1, mode = "live" })

-- Keep independent magnification for each output. A new output starts at 1x;
-- returning to a previously zoomed output restores its saved level.
hl.exec_cmd("~/.config/hypr/scripts/zoom.sh init")
hl.on("monitor.focused", function(monitor)
    hl.exec_cmd("~/.config/hypr/scripts/zoom.sh switch " .. string.format("%q", monitor.name))
end)

-- Unedited placeholder from the default template — "epic-mouse-v1" doesn't match
-- a real device name, so this rule is a harmless no-op. Kept as-is from the backup.
hl.device({ name = "epic-mouse-v1", sensitivity = -0.5 })
