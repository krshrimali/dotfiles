# Dotfiles

Personal configuration for the desktop, shells, terminals, and editors I use.

| Category | Config | What’s configured |
|---|---|---|
| Desktop compositor | [`hypr/`](hypr/) | Hyprland Lua configuration for monitors, workspaces, window rules, layout, decorations, animations, startup, and environment. Includes keyboard and Magic Trackpad gestures, Hyprexpo workspace previews, per-monitor zoom and pan controls, and helper scripts. |
| Hyprland controls | [`hypr/config/binds.lua`](hypr/config/binds.lua), [`hypr/scripts/`](hypr/scripts/) | Window and workspace navigation, resizing and pan modes, monitor switching, audio controls, screenshots, keybind search, briefing tools, and other desktop helpers. |
| Hyprland settings tools | [`hypr/settings-app/`](hypr/settings-app/), [`hypr/settings-tui/`](hypr/settings-tui/) | GTK and terminal interfaces for changing compositor settings. |
| Shells | [`.zshrc`](.zshrc), [`config.fish`](config.fish), [`fish/`](fish/) | Zsh with Oh My Zsh and Fish with Oh My Fish, shell startup settings, aliases, functions, completions, and prompt/plugin configuration. |
| Search and command-line workflow | [`fish/`](fish/), [`.zshrc`](.zshrc), [`key-bindings.zsh`](key-bindings.zsh) | Fuzzy file, directory, history, process, and Git workflows using tools such as fzf, fd, ripgrep, and bat; Git and package-manager shortcuts are also included. |
| Terminal emulators | [`kitty/`](kitty/), [`wezterm.lua`](wezterm.lua), [`alacritty.yml`](alacritty.yml) | Kitty and WezTerm settings, keymaps, pane workflows, theme switching, and Alacritty configuration. Theme files are collected in [`kitty/themes/`](kitty/themes/) and [`themes/`](themes/). |
| Terminal multiplexer | [`zellij/`](zellij/) | Custom pane, tab, resize, move, scroll, and search keymaps, plus themes and bundled plugins. |
| Emacs | [`doom/`](doom/) | Doom Emacs module selection and package declarations, including Evil, completion, LSP, Magit, vterm, and Copilot. |
| Visual Studio Code | [`vscode-user-settings.json`](vscode-user-settings.json) | Vim-style editing, Space leader mappings, and shortcuts for Explorer, search, source control, and quick open. |

## Notes

- The Hyprland monitor names, workspace assignments, device rules, and some startup paths are specific to my machine.
- Optional utilities referenced by configs and scripts—such as `fzf`, `fd`, `bat`, `ripgrep`, `rofi`, and `hyprctl`—need to be installed separately.
- Application configuration files can be linked into their expected locations under `~/.config` or the home directory. Review machine-specific paths before using them on another system.
