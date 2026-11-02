-- Machine-specific layout: portrait | landscape (main) | portrait, vertically centred.
-- transform = 1 rotates 90°; use 3 instead if a panel ends up upside down.

-- Left: BenQ GW2790QT 2560x1440, portrait (1440x2560 logical)
hl.monitor({
    output = "DP-3",
    mode = "2560x1440@74.97",
    position = "0x0",
    scale = 1,
    vrr = 0,
    transform = 1
})
-- Middle (main): BenQ GW2790QT 2560x1440, landscape
hl.monitor({
    output = "HDMI-A-3",
    mode = "2560x1440@74.97",
    position = "1440x560",
    scale = 1,
    vrr = 0,
    transform = 0
})
-- Right: BenQ GW2480 1920x1080, portrait (1080x1920 logical)
hl.monitor({
    output = "HDMI-A-4",
    mode = "1920x1080@60.000",
    position = "4000x320",
    scale = 1,
    vrr = 0,
    transform = 1
})
