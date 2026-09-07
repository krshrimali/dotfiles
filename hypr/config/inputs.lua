-- Input configuration https://wiki.hypr.land/Configuring/Basics/Variables/#input

hl.config({
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

-- Unedited placeholder from the default template — "epic-mouse-v1" doesn't match
-- a real device name, so this rule is a harmless no-op. Kept as-is from the backup.
hl.device({ name = "epic-mouse-v1", sensitivity = -0.5 })
