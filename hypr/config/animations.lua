-- Animations (Hyprland 0.57), see https://wiki.hypr.land/configuring/core/animations/
-- Previous version kept at config/animations.lua.bak

hl.config({
    animations = {
        enabled = true,
        -- Slide 10 -> 1 (and 1 -> 10) in the "natural" direction instead of
        -- flying back across every workspace in between.
        workspace_wraparound = true,
    },
})

-- Bezier curves
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

-- Spring curves (new in 0.57): physically-based, interruptible motion.
-- "easy" is the upstream default; "snappy" settles faster with a hint of overshoot.
hl.curve("easy",   { type = "spring", mass = 1, stiffness = 238.1191, damping = 24.21279333 })
hl.curve("snappy", { type = "spring", mass = 1, stiffness = 320,      damping = 26 })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })

-- Windows: springy open/move, quick linear close
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  spring = "easy",   style = "popin 87%" })
hl.animation({ leaf = "windowsMove",   enabled = true, speed = 4.5,  spring = "snappy" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })

-- Fades
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "fadePopups",    enabled = true, speed = 2,    bezier = "quick" })

-- Layers (bars, launchers, notifications)
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })

-- Workspaces: horizontal slide; portrait monitors still slide sideways which
-- reads fine. Special workspaces (scratchpad, GPU observer) drop in vertically.
hl.animation({ leaf = "workspaces",        enabled = true, speed = 3.5, bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "specialWorkspace",  enabled = true, speed = 3.5, bezier = "easeOutQuint", style = "slidefadevert 20%" })

-- Desktop zoom (zoom.sh / pinch)
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 7,    bezier = "quick" })

-- Rotating gradient border. Looks great but forces a redraw every frame on
-- every monitor (bad for idle power and CS2 frame pacing) -- opt in if wanted:
-- hl.animation({ leaf = "borderangle", enabled = true, speed = 60, bezier = "linear", style = "loop" })
