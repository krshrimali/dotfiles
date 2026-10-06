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
            enabled = false,
            range = 4,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },

        blur = {
            enabled = false,
            size = 3,
            passes = 1,
            vibrancy = 0.1696,
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
