-- Citrix multi-monitor support. Only applies when running the patched build
-- (~/Projects/hyprland-citrix) started with HYPR_CITRIX=1; stock Hyprland
-- does not know these options, so this block stays inert there.
if os.getenv("HYPR_CITRIX") == "1" then
    hl.config({
        xwayland = {
            real_layout = true,           -- Xwayland sees the real monitor layout
            fullscreen_monitors = true,   -- _NET_WM_FULLSCREEN_MONITORS spanning
            allow_keyboard_grabs = true,  -- Citrix fullscreen gets Super, Alt+Tab, etc.
        },
        -- caps:ctrl_modifier keeps the Caps_Lock keysym (only adds the Ctrl modifier), so Citrix
        -- forwards it to Windows as a real Caps Lock press. ctrl:nocaps emits Control_L instead:
        -- identical locally, and Windows sees Ctrl.
        input = { kb_options = "ctrl:nocaps" },
    })

    -- Escape hatch while Citrix holds the keyboard: dont_inhibit binds always reach Hyprland.
    -- Takes the focused window (the Citrix session) out of fullscreen, like the toolbar's "Window"
    -- button; Citrix then releases the keyboard grab and every Hyprland bind works again.
    hl.bind("SUPER + CTRL + Escape", hl.dsp.window.fullscreen({ action = "unset" }), { dont_inhibit = true })
end

-- Citrix (Wfica) windows open on an empty workspace of the monitor they appear on, never on
-- top of existing windows. Workspace IDs are per monitor (see workspaces.lua), so pick the
-- lowest empty ID in that monitor's range and follow it there.
local citrixRange = { ["HDMI-A-3"] = 0, ["DP-4"] = 10, ["HDMI-A-4"] = 20 }
hl.on("window.open", function(w)
    if w.class ~= "Wfica" then return end
    local ws = w.workspace
    if not ws or ws.special then return end
    for _, other in ipairs(ws:get_windows()) do
        if other.class ~= "Wfica" then
            local offset = (w.monitor and citrixRange[w.monitor.name]) or 0
            for id = offset + 1, offset + 10 do
                local cand = hl.get_workspace(id)
                if not cand or cand.windows == 0 then
                    hl.dispatch(hl.dsp.window.move({ workspace = id, window = w }))
                    return
                end
            end
            return
        end
    end
end)
