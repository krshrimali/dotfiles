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

table.insert(mykeys, { key = "c", mods = "SHIFT|ALT", action = act.ActivateCopyMode })

-- table.insert(mykeys, { key = "q", mods = "ALT", action = act.QuickSelect })

table.insert(mykeys, { key = "s", mods = "ALT", action = act.Search({ CaseSensitiveString = "" }) })

table.insert(mykeys, { key = "f", mods = "ALT", action = "ToggleFullScreen" })

table.insert(mykeys, { key = "t", mods = "ALT", action = act({ SpawnTab = "CurrentPaneDomain" }) })

table.insert(mykeys, { key = "[", mods = "ALT", action = act.MoveTabRelative(-1) })

table.insert(mykeys, { key = "]", mods = "ALT", action = act.MoveTabRelative(1) })

table.insert(mykeys, { key = "V", mods = "ALT", action = act({ SplitPane = { direction = "Left" } }) })
table.insert(mykeys, { key = "X", mods = "ALT", action = act({ SplitPane = { direction = "Down" } }) })

table.insert(mykeys, { key = "h", mods = "ALT", action = act({ ActivatePaneDirection = "Left" }) })
table.insert(mykeys, { key = "j", mods = "ALT", action = act({ ActivatePaneDirection = "Down" }) })
table.insert(mykeys, { key = "k", mods = "ALT", action = act({ ActivatePaneDirection = "Up" }) })
table.insert(mykeys, { key = "l", mods = "ALT", action = act({ ActivatePaneDirection = "Right" }) })

config.leader = { key = "a", mods = "CTRL" }
table.insert(mykeys, { key = "h", mods = "SHIFT|ALT", action = act({ AdjustPaneSize = { "Left", 3 } }) })
table.insert(mykeys, { key = "j", mods = "SHIFT|ALT", action = act({ AdjustPaneSize = { "Down", 3 } }) })
table.insert(mykeys, { key = "k", mods = "SHIFT|ALT", action = act({ AdjustPaneSize = { "Up", 3 } }) })
table.insert(mykeys, { key = "l", mods = "SHIFT|ALT", action = act({ AdjustPaneSize = { "Right", 3 } }) })

-- config.font = wezterm.font("Iosevka", { weight = "Medium", italic = false, stretch = "Normal" })
config.line_height = 1.10
-- config.cell_width = 1.0
config.font = wezterm.font("DankMono Nerd Font", {weight="Regular", italic = false, stretch="Normal", style="Normal"}) -- /Library/Fonts/DankMonoNerdFont-Regular.ttf, CoreText
-- config.font = wezterm.font("Iosevka", { weight = "Medium", italic = false, stretch = "Normal" })
config.font_size = 20.0


config.scrollback_lines = 10000
config.exit_behavior = "Close"
config.keys = mykeys
config.default_cursor_style = "BlinkingUnderline"
-- config.color_scheme = scheme_for_appearance(get_appearance())

-- wezterm.gui is not available to the mux server, so take care to
-- do something reasonable when this config is evaluated by the mux
function get_appearance()
	if wezterm.gui then
		return wezterm.gui.get_appearance()
	end
	return "Dark"
end

function scheme_for_appearance(appearance)
	if appearance:find("Dark") then
		return "Builtin Solarized Dark"
	else
		return "Builtin Solarized Light"
	end
end

-- The filled in variant of the < symbol
local SOLID_LEFT_ARROW = wezterm.nerdfonts.pl_right_hard_divider

-- The filled in variant of the > symbol
local SOLID_RIGHT_ARROW = wezterm.nerdfonts.pl_left_hard_divider

-- config.tab_bar_style = {
--   new_tab_left = wezterm.format {
--     { Background = { Color = '#0b0022' } },
--     { Foreground = { Color = '#2b2042' } },
--     { Text = SOLID_LEFT_ARROW },
--   },
--   new_tab_right = wezterm.format {
--     { Background = { Color = '#0b0022' } },
--     { Foreground = { Color = '#2b2042' } },
--     { Text = SOLID_RIGHT_ARROW },
--   },
--   new_tab_hover_left = wezterm.format {
--     { Background = { Color = '#0b0022' } },
--     { Foreground = { Color = '#1b1032' } },
--     { Text = SOLID_LEFT_ARROW },
--   },
--   new_tab_hover_right = wezterm.format {
--     { Background = { Color = '#0b0022' } },
--     { Foreground = { Color = '#1b1032' } },
--     { Text = SOLID_RIGHT_ARROW },
--   },
-- }

config.color_scheme = scheme_for_appearance(get_appearance())
config.hide_tab_bar_if_only_one_tab = true
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

config.window_background_opacity = 1.0
config.macos_window_background_blur = 50
config.color_scheme = "Catppuccin Mocha"

return config
