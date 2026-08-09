-- Monitor wiki https://wiki.hypr.land/Configuring/Basics/Monitors/
-- Layout: [HDMI-A-1 1080p portrait] | [DP-2 2K landscape] | [HDMI-A-2 2K portrait, flipped]
-- HDMI-A-1  BenQ GW2480    1920x1080@60Hz     at x=0     (left,   HD,  portrait, transform=1 -> 1080 wide)
-- DP-2      BenQ GW2790QT  2560x1440@74.97Hz  at x=1080  (middle, 2K,  landscape)
-- HDMI-A-2  BenQ GW2790QT  2560x1440@74.97Hz  at x=3640  (right,  2K,  portrait flipped, transform=3 -> 1440 wide)

hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60.0",  position = "0x0",    scale = "1", transform = 1 })
hl.monitor({ output = "DP-2",     mode = "2560x1440@74.97", position = "1080x0", scale = "1" })
hl.monitor({ output = "HDMI-A-2", mode = "2560x1440@74.97", position = "3640x0", scale = "1", transform = 3 })
