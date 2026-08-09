-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/
-- and https://wiki.hypr.land/Configuring/Layouts/Master-Layout/

hl.config({
    dwindle = {
        preserve_split = true, -- you probably want this
    },
    master = {
        new_status = "master",
    },
    misc = {
        force_default_wallpaper = -1, -- set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo = false,
    },
})
