-- Workspace rules wiki https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- Per-monitor workspace assignments (i3-style)

local function workspaceRange(startId, endId, monitor)
    for i = startId, endId do
        hl.workspace_rule({ workspace = tostring(i), monitor = monitor, default = (i == startId) })
    end
end

workspaceRange(1, 10, "HDMI-A-2")  -- right,  1920x1080, transform 3 (portrait), 10-bit
workspaceRange(11, 20, "DP-2")     -- middle, 2560x1440 landscape
workspaceRange(21, 30, "HDMI-A-1") -- left,   2560x1440 landscape

-- GPU Observer special workspace: Hyprland auto-spawns kitty on first open (Super+G)
hl.workspace_rule({
    workspace = "special:gpu-observer",
    on_created_empty = 'kitty --class gpu-observer --title "GPU Observer" -e gpu-observer',
})
