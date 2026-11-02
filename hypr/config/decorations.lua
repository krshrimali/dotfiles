-- Look and feel https://wiki.hypr.land/Configuring/Basics/Variables/

hl.config({
    general = {
        gaps_in = 2,
        gaps_out = 3,
        border_size = 3,

        col = {
            active_border = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },

        -- Resize windows by clicking and dragging on borders and gaps
        resize_on_border = true,

        allow_tearing = true,
        layout = "dwindle",
    },

    decoration = {
        rounding = 10,
        rounding_power = 2,

        active_opacity = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },

        blur = {
            enabled = true,
            size = 3,
            passes = 1,
            vibrancy = 0.1696,
            -- 0.57 blur variants: kawase (classic), frost, ripple, drops, water,
            -- fluid_jar, prism, heat_shimmer, acrylic, aurora, haze.
            -- Animated ones (drops, heat_shimmer, aurora, water, fluid_jar) cost
            -- GPU every frame. "frost" / "acrylic" are the cheap, static-looking ones.
            variant = "kawase",
        },

        -- ---- New 0.57 effects ----

        -- Soft inner glow along window edges
        glow = {
            enabled = true,
            range = 10,
            render_power = 3,
            color = "rgba(33ccff55)",
            color_inactive = "rgba(00000000)",
        },

        -- Motion blur while windows move/resize (pairs well with animations)
        motion_blur = {
            enabled = true,
            samples = 7,
        },

        -- Compiz-style wobbly windows when dragging/resizing
        wobble = {
            enabled = true,
            stiffness = 200,
            damping = 12,
            intensity = 0.2,
        },
    },

    cursor = {
        -- Let the pointer move freely; pan the magnified view only as needed
        -- to keep it visible near the edges of the active monitor.
        zoom_rigid = false,
        zoom_detached_camera = true,
    },

    xwayland = {
        force_zero_scaling = true,
    },
})
