-- Export session env to systemd/dbus, then bring up the graphical session so
-- xdg-desktop-portal (the frontend) can start. Without this, OBS screen capture
-- is missing because org.freedesktop.portal.Desktop never activates.
hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP XDG_RUNTIME_DIR; dbus-update-activation-environment --systemd WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP; systemctl --user start hyprland-session.target xdg-desktop-portal.service")
    -- noctalia v5 ships as its own binary now, not a quickshell config
    -- (the old "quickshell -c noctalia-shell" invocation errors with
    -- "Could not find noctalia-shell config directory" since that
    -- directory no longer exists on this package version).
    hl.exec_cmd("noctalia")

    -- Make the notification daemon + hyprctl reachable from systemd --user timers
    -- (daily briefing + wellbeing nudges). Needed once per session.
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP XDG_RUNTIME_DIR")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP")

    -- Software KVM: share keyboard/mouse with the Mac (see monitor-switch/SETUP-kvm.md)
    hl.exec_cmd("lan-mouse daemon")
    -- Reconcile the BenQ panel to wherever the lan-mouse seat is (covers the Mac->PC return path)
    hl.exec_cmd("~/Documents/projects/monitor-switch/kvm-panel-follow.sh")
end)
