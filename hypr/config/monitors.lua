-- Monitor layout is managed by nwg-displays (GUI). It writes the actual
-- hl.monitor() calls to ~/.config/hypr/monitors.lua on every save; this
-- file just pulls that in so GUI changes take effect on reload.
require("monitors")
