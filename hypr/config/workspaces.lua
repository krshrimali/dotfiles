-- Workspace rules wiki https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- Per-monitor workspace assignments (i3-style)

-- Each monitor owns ten workspace IDs, but every workspace is *named* 1-10 so
-- each monitor reads as its own 1-10. Offsets must match scripts/workspace.sh.
--
-- Portrait monitors use the master layout with orientation "top": the master
-- window spans the full width at the top and the rest stack below it in
-- full-width rows. That fits tall screens better than dwindle, which keeps
-- splitting into narrow columns. The landscape main monitor stays on dwindle
-- (the global default).
local PORTRAIT = { layout = "master", layout_opts = { orientation = "top" } }

-- Right monitor (trial): scrolling layout running downward. Windows sit on an
-- endless vertical strip of full-width rows; focusing up/down (SUPER+j/k)
-- scrolls the strip. Row height comes from scrolling:column_width (a fraction
-- of the screen) and SUPER+T cycles through the preset heights. To go back to
-- master on this monitor, swap PORTRAIT_SCROLL for PORTRAIT below.
local PORTRAIT_SCROLL = { layout = "scrolling", layout_opts = { direction = "down" } }

local function workspaceRange(startId, endId, monitor, extra)
    for i = startId, endId do
        local rule = {
            workspace = tostring(i),
            monitor = monitor,
            default = (i == startId),
            default_name = tostring(i - startId + 1),
        }
        for k, v in pairs(extra or {}) do rule[k] = v end
        hl.workspace_rule(rule)
    end
end

workspaceRange(1, 10, "HDMI-A-3")            -- middle, 2560x1440 landscape (main)
workspaceRange(11, 20, "DP-4", PORTRAIT)     -- left,   2560x1440 portrait
workspaceRange(21, 30, "HDMI-A-4", PORTRAIT_SCROLL) -- right,  1920x1080 portrait

-- Rules above only apply when a workspace is created. When a monitor drops
-- (e.g. Super+I to the Mac) its workspaces migrate and never come back, so on
-- reconnect move every workspace back to its owning monitor.
local homeMonitor = { [0] = "HDMI-A-3", [1] = "DP-4", [2] = "HDMI-A-4" }
hl.on("monitor.added", function()
    local connected = {}
    for _, m in ipairs(hl.get_monitors()) do connected[m.name] = true end
    for _, ws in ipairs(hl.get_workspaces()) do
        local id = ws.id
        if id and id >= 1 and id <= 30 and not ws.special then
            local home = homeMonitor[(id - 1) // 10]
            if connected[home] and ws.monitor and ws.monitor.name ~= home then
                hl.dispatch(hl.dsp.workspace.move({ workspace = id, monitor = home }))
            end
        end
    end
end)

-- GPU Observer special workspace: auto-spawn kitty on first open (Super+G)
hl.on("workspace.created", function(workspace)
    if workspace.name == "special:gpu-observer" and workspace.is_empty then
        hl.exec_cmd('kitty --class gpu-observer --title "GPU Observer" -e gpu-observer')
    end
end)
