local config = {}
local wezterm = require("wezterm")
local act = wezterm.action

if wezterm.config_builder then
	config = wezterm.config_builder()
end

local mykeys = {}

for i = 1, 8 do
	table.insert(mykeys, {
		key = tostring(i),
		mods = "ALT",
		action = act({ ActivateTab = i - 1 }),
	})
end

table.insert(mykeys, { key = "c", mods = "ALT", action = act.ActivateCopyMode })

table.insert(mykeys, { key = "q", mods = "ALT", action = act.QuickSelect })

table.insert(mykeys, { key = "s", mods = "ALT", action = act.Search({ CaseSensitiveString = "" }) })

table.insert(mykeys, { key = "f", mods = "ALT", action = "ToggleFullScreen" })

table.insert(mykeys, { key = "n", mods = "ALT", action = act({ SpawnTab = "CurrentPaneDomain" }) })

table.insert(mykeys, { key = "[", mods = "ALT", action = act.MoveTabRelative(-1) })

table.insert(mykeys, { key = "]", mods = "ALT", action = act.MoveTabRelative(1) })

table.insert(mykeys, { key = "V", mods = "ALT", action = act({ SplitPane = { direction = "Left" } }) })
table.insert(mykeys, { key = "X", mods = "ALT", action = act({ SplitPane = { direction = "Down" } }) })

table.insert(mykeys, { key = "h", mods = "ALT", action = act({ ActivatePaneDirection = "Left" }) })
table.insert(mykeys, { key = "j", mods = "ALT", action = act({ ActivatePaneDirection = "Down" }) })
table.insert(mykeys, { key = "k", mods = "ALT", action = act({ ActivatePaneDirection = "Up" }) })
table.insert(mykeys, { key = "l", mods = "ALT", action = act({ ActivatePaneDirection = "Right" }) })

table.insert(mykeys, { key = "h", mods = "ALT|SHIFT", action = act({ AdjustPaneSize = { "Left", 1 } }) })
table.insert(mykeys, { key = "j", mods = "ALT|SHIFT", action = act({ AdjustPaneSize = { "Down", 1 } }) })
table.insert(mykeys, { key = "k", mods = "ALT|SHIFT", action = act({ AdjustPaneSize = { "Up", 1 } }) })
table.insert(mykeys, { key = "l", mods = "ALT|SHIFT", action = act({ AdjustPaneSize = { "Right", 1 } }) })

config.font = wezterm.font("Jetbrains Mono", { weight = "Medium", italic = false, stretch = "Normal" })
config.font_size = 16.0

config.window_background_opacity = 0.90
config.scrollback_lines = 10000
config.exit_behavior = "Close"
config.keys = mykeys
config.default_cursor_style = "BlinkingUnderline"

return config
