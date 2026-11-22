-- Picture-in-picture for any window.
--
--   SUPER+SHIFT+P        toggle PiP on the focused window: float it, shrink it
--                        (aspect ratio kept), park it in a corner and pin it so
--                        it follows you across workspaces. Press again to put it
--                        back exactly where it was (tiled or floating).
--   SUPER+SHIFT+ALT+P    move the focused PiP window to the next corner
--                        (bottom-right -> bottom-left -> top-left -> top-right).
--
-- PiP windows carry the "pip" tag, so they can be targeted by window rules.

local mainMod = MAIN_MOD

local PIP_WIDTH_FRAC  = 0.25 -- PiP width as a fraction of the monitor's width
local PIP_HEIGHT_FRAC = 0.40 -- ...but never taller than this fraction of its height
local MARGIN          = 24   -- gap from the screen edge / bar, in logical px
local CORNERS         = { "br", "bl", "tl", "tr" }

-- Saved pre-PiP geometry, keyed by window address. Global so a config reload
-- doesn't forget windows that are currently in PiP.
PIP_STATE = PIP_STATE or {}

local function notify(msg)
    hl.dispatch(hl.dsp.exec_cmd('notify-send -t 1500 "Picture-in-picture" "' .. msg .. '"'))
end

local function is_pip(w)
    for _, t in pairs(w.tags or {}) do
        if t == "pip" or t == "pip*" then return true end
    end
    return false
end

-- Usable area of a monitor in layout coordinates (rotation, scale and bars).
local function usable_area(m)
    local w, h = m.width, m.height
    if m.transform % 2 == 1 then w, h = h, w end
    w, h = w / m.scale, h / m.scale
    local r = m.reserved or {}
    return {
        x = m.x + (r.left or 0),
        y = m.y + (r.top or 0),
        w = w - (r.left or 0) - (r.right or 0),
        h = h - (r.top or 0) - (r.bottom or 0),
    }
end

local function corner_pos(area, size, corner)
    local left   = area.x + MARGIN
    local right  = area.x + area.w - size.x - MARGIN
    local top    = area.y + MARGIN
    local bottom = area.y + area.h - size.y - MARGIN
    local x = (corner == "bl" or corner == "tl") and left or right
    local y = (corner == "tl" or corner == "tr") and top or bottom
    return math.floor(x), math.floor(y)
end

local function enter_pip(w)
    local area = usable_area(w.monitor)
    local sw, sh = math.max(w.size.x, 1), math.max(w.size.y, 1)

    local width  = area.w * PIP_WIDTH_FRAC
    local height = width * sh / sw
    local max_h  = area.h * PIP_HEIGHT_FRAC
    if height > max_h then
        height = max_h
        width  = height * sw / sh
    end
    local size = { x = math.floor(width), y = math.floor(height) }

    PIP_STATE[w.address] = {
        floating = w.floating,
        at       = { x = w.at.x, y = w.at.y },
        size     = { x = w.size.x, y = w.size.y },
        corner   = 1,
    }

    local x, y = corner_pos(area, size, CORNERS[1])
    hl.dispatch(hl.dsp.window.float({ action = "enable", window = w }))
    hl.dispatch(hl.dsp.window.resize({ x = size.x, y = size.y, window = w }))
    hl.dispatch(hl.dsp.window.move({ x = x, y = y, window = w }))
    hl.dispatch(hl.dsp.window.pin({ action = "enable", window = w }))
    hl.dispatch(hl.dsp.window.tag({ tag = "+pip", window = w }))
end

local function exit_pip(w)
    local s = PIP_STATE[w.address]
    PIP_STATE[w.address] = nil

    hl.dispatch(hl.dsp.window.pin({ action = "disable", window = w }))
    hl.dispatch(hl.dsp.window.tag({ tag = "-pip", window = w }))

    if s and s.floating then
        hl.dispatch(hl.dsp.window.resize({ x = s.size.x, y = s.size.y, window = w }))
        hl.dispatch(hl.dsp.window.move({ x = s.at.x, y = s.at.y, window = w }))
    else
        -- Was tiled (or state lost): hand it back to the layout.
        hl.dispatch(hl.dsp.window.float({ action = "disable", window = w }))
    end
end

PIP = {}

function PIP.toggle()
    local w = hl.get_active_window()
    if w == nil then return end
    if is_pip(w) then
        exit_pip(w)
    elseif w.fullscreen ~= 0 then
        notify("Exit fullscreen first")
    else
        enter_pip(w)
    end
end

function PIP.next_corner()
    local w = hl.get_active_window()
    if w == nil or not is_pip(w) then return end
    local s = PIP_STATE[w.address] or { corner = 1 }
    s.corner = s.corner % #CORNERS + 1
    PIP_STATE[w.address] = s
    local x, y = corner_pos(usable_area(w.monitor), w.size, CORNERS[s.corner])
    hl.dispatch(hl.dsp.window.move({ x = x, y = y, window = w }))
end

hl.bind(mainMod .. " + SHIFT + P",       PIP.toggle)
hl.bind(mainMod .. " + SHIFT + ALT + P", PIP.next_corner)

-- Forget saved geometry when a PiP window closes.
hl.on("window.close", function(w)
    if w ~= nil then PIP_STATE[w.address] = nil end
end)
