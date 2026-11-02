# Dotfiles

My Linux desktop config: Hyprland, the shells, terminals and editors I use.

> **Heads-up:** These files are written for my machine. Monitor names, workspace
> assignments and some script paths won't match yours. Read before you copy.

---

## My current setup

| | |
|---|---|
| **OS** | CachyOS (Arch-based), kernel `7.3.x-cachyos` |
| **Hardware** | Intel i9-12900K · NVIDIA RTX 3060 · 64 GB RAM |
| **Compositor** | Hyprland 0.57, configured in Lua |
| **Shell / bar** | [Noctalia](https://github.com/noctalia-dev/noctalia-shell) (bar, notifications, panels) |
| **Launcher** | `hyprlauncher` (`Super+R`), `rofi` for helper menus |
| **Terminal** | Kitty, DankMono Nerd Font 12, Noctalia theme |
| **Shell** | Fish (login shell) with the CachyOS fish config; Zsh is also set up |
| **File manager** | Dolphin |
| **Browser** | Google Chrome |
| **Workspace overview** | `hyprexpose` (`Super+D` / 3-finger swipe up), standing in until Hyprexpo has a 0.57 build |
| **Input** | Keyboard plus Apple Magic Trackpad (gestures for workspaces, zoom, overview) |
| **Mac sharing** | `lan-mouse` software KVM and DDC/CI input switching on the left monitor |

### Monitors

Three BenQ screens: portrait, landscape, portrait.

```
 ┌──────┐                      ┌──────┐
 │      │ ┌──────────────────┐ │      │
 │ DP-3 │ │    HDMI-A-3      │ │HDMI- │
 │ 1440 │ │   2560×1440      │ │ A-4  │
 │  ×   │ │     (main)       │ │ 1080 │
 │ 2560 │ └──────────────────┘ │ ×1920│
 │      │                      │      │
 └──────┘                      └──────┘
 GW2790QT      GW2790QT         GW2480
 portrait      landscape        portrait
```

Each monitor has its own workspaces numbered 1–10 (IDs 1–10 on the main screen,
11–20 on the left, 21–30 on the right). The layout is set with `nwg-displays`,
which writes `~/.config/hypr/monitors.lua`.

---

## What's in here

### In daily use

| Folder / file | What it is |
|---|---|
| [`hypr/`](hypr/) | Hyprland config, split into files under [`hypr/config/`](hypr/config/). Has its own [README](hypr/README.md) for keybinds and scripts. |
| [`hypr/scripts/`](hypr/scripts/) | Helpers for zoom, pan, per-monitor workspaces, keybind cheatsheet, terminal launcher, audio switching, daily briefing and screen spotlight. |
| [`hypr/settings-app/`](hypr/settings-app/) | GTK app for changing Hyprland settings (Python). |
| [`hypr/settings-tui/`](hypr/settings-tui/) | The same idea as a terminal app (Rust), opened with `Super+,`. |
| [`kitty/`](kitty/) | Kitty config, keymap search, and a theme switcher ([`switch_theme.py`](kitty/switch_theme.py)) with 20 themes. |
| [`fish/`](fish/), [`config.fish`](config.fish) | Fish functions, fzf search bindings (files, history, git, processes) and prompt. |
| [`.zshrc`](.zshrc), [`key-bindings.zsh`](key-bindings.zsh), [`completion.zsh`](completion.zsh) | Zsh with Oh My Zsh, aliases and fzf bindings. |

### Kept for reference (not installed right now)

| Folder / file | What it is |
|---|---|
| [`wezterm.lua`](wezterm.lua) | WezTerm config with pane keymaps and theme switching. |
| [`alacritty.yml`](alacritty.yml), [`themes/`](themes/) | Alacritty config and a large set of color themes. |
| [`zellij/`](zellij/) | Zellij keymaps, themes and plugins. |
| [`.tmux.conf`](.tmux.conf), [`.tmux.conf.local`](.tmux.conf.local) | tmux config. |
| [`doom/`](doom/) | Doom Emacs modules and packages (Evil, LSP, Magit, vterm, Copilot). |
| [`vscode-user-settings.json`](vscode-user-settings.json) | VS Code Vim mode with Space-leader shortcuts. |

---

## Hyprland at a glance

The full list lives in [`hypr/README.md`](hypr/README.md), or press `Super+/`
for a searchable cheatsheet of every active bind.

| Keys | Action |
|---|---|
| `Super+Q` / `Super+Enter` | Terminal (opens in the focused shell's folder) |
| `Super+R` | App launcher |
| `Super+W` | Close window |
| `Super+H/J/K/L` | Move focus |
| `Super+Shift+H/J/K/L` | Move window |
| `Super+Ctrl+H/J/K/L` | Resize window |
| `Super+1…0` | Switch workspace on the current monitor |
| `Super+Shift+1…0` | Send window to a workspace on the current monitor |
| `Super+Shift+←/→` | Move the whole workspace to another monitor |
| `Super+D` | Workspace overview |
| `Super+=` / `Super+-` / `Super+Backspace` | Zoom in / out / reset |
| `Super+Z` | Pan mode while zoomed |
| `Super+Shift+S` | Screenshot a region to the clipboard |
| `Super+M` | Lock screen |
| `Super+I` / `Super+O` | Switch left monitor input / move mouse+keyboard to the Mac |
| `Super+/` | Keybind cheatsheet |

**Trackpad:** 3-finger swipe left/right changes workspace, 3-finger up opens the
overview, 2-finger pinch zooms the desktop.

---

## Installing

There's no install script. The files are copied into place:

| Repo path | Goes to |
|---|---|
| `hypr/` | `~/.config/hypr/` |
| `kitty/` | `~/.config/kitty/` |
| `fish/` | `~/.config/fish/` |
| `.zshrc`, `.tmux.conf*` | `~/` |
| `wezterm.lua` | `~/.config/wezterm/wezterm.lua` |
| `zellij/` | `~/.config/zellij/` |
| `doom/` | `~/.config/doom/` |

Before using the Hyprland config on another machine, change:

- `hypr/monitors.lua` and `hypr/config/workspaces.lua` (monitor names)
- `hypr/scripts/workspace.sh` (workspace ID offsets must match)
- `hypr/config/autostart.lua` (Noctalia, lan-mouse, hyprexpose and local paths)
- `hypr/config/binds.lua` (`Super+I` / `Super+O` call scripts from a separate `monitor-switch` project)

**Tools the configs expect:** `fzf`, `fd`, `bat`, `ripgrep`, `rofi`, `grim`,
`slurp`, `wl-clipboard`, `hyprlock`, `ddcutil`, `nwg-displays`, plus Noctalia
and a Nerd Font.
