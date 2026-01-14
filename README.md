# dotfiles

My personal dotfiles configuration with support for both Zsh and Fish shells, featuring extensive Git utilities, FZF integration, and modern terminal tools.

## Supported Shells & Tools

### Shell Configurations
- **Zsh** with Oh My Zsh (`.zshrc`)
- **Fish Shell** with comprehensive function porting (`config.fish`)

### Terminal & Multiplexer
- **tmux** with extensive plugin configuration
- **Zellij** configuration
- **WezTerm** Lua configuration

### Terminal Emulators
- **Alacritty** with theme switching support
- **Kitty** with advanced features

### Editors & Tools
- **Neovim** configuration
- **Lazygit** for Git operations
- **FZF** for fuzzy finding with custom functions
- **Bat** for syntax highlighting
- **Fd** for fast file searching
- **Ripgrep** for fast text searching
- **Exa** for modern `ls` replacement
- **Zoxide** for smart directory jumping

## Installation

### Prerequisites

Install the following tools for full functionality:

1. **[fd](https://github.com/sharkdp/fd#installation)** - Fast file finder
   ```bash
   # On Debian/Ubuntu, you might need to create a symlink
   ln -s $(which fdfind) ~/.local/bin/fd
   ```

2. **[bat](https://github.com/sharkdp/bat)** - Better cat with syntax highlighting
   ```bash
   # On Ubuntu/Debian
   sudo apt install bat
   # Create alias if installed as batcat
   alias bat="batcat"
   ```

3. **[tmux](https://github.com/tmux/tmux)** - Terminal multiplexer
   ```bash
   sudo apt install tmux  # Ubuntu/Debian
   brew install tmux      # macOS
   ```

4. **[tree](https://linux.die.net/man/1/tree)** - Directory tree viewer
   ```bash
   sudo apt install tree
   ```

5. **[fzf](https://github.com/junegunn/fzf)** - Fuzzy finder
   ```bash
   git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
   ~/.fzf/install
   ```

6. **[ats](https://github.com/tichopad/alacritty-theme-switch)** - Alacritty theme switcher
   ```bash
   npm install -g alacritty-theme-switch
   ```

7. **[lazygit](https://github.com/jesseduffield/lazygit)** - Git TUI
   ```bash
   brew install lazygit  # macOS or Linux with Homebrew
   ```

8. **[ripgrep](https://github.com/BurntSushi/ripgrep)** - Fast text search
   ```bash
   sudo apt install ripgrep  # Ubuntu/Debian
   brew install ripgrep      # macOS
   ```

9. **[exa](https://github.com/ogham/exa)** - Modern ls replacement
   ```bash
   sudo apt install exa  # Ubuntu/Debian
   brew install exa      # macOS
   ```

10. **[zoxide](https://github.com/ajeetdsouza/zoxide)** - Smart directory jumper
    ```bash
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
    ```

11. **[autojump](https://github.com/wting/autojump)** - Directory jumping (optional)

### Shell Setup

#### For Zsh (with Oh My Zsh)
```bash
# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Copy the .zshrc configuration
cp .zshrc ~/.zshrc
source ~/.zshrc
```

#### For Fish Shell
```bash
# Install Fish Shell
sudo apt install fish     # Ubuntu/Debian
brew install fish         # macOS

# Set Fish as default shell (optional)
chsh -s $(which fish)

# Copy the Fish configuration
mkdir -p ~/.config/fish
cp config.fish ~/.config/fish/config.fish

# Install Fisher (Fish package manager) - optional but recommended
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
```

### Terminal Emulator Setup

#### Alacritty
```bash
mkdir -p ~/.config/alacritty
cp alacritty.yml ~/.config/alacritty/alacritty.yml
```

#### Kitty
```bash
mkdir -p ~/.config/kitty
cp kitty.conf ~/.config/kitty/kitty.conf
```

#### WezTerm
```bash
mkdir -p ~/.config/wezterm
cp wezterm.lua ~/.config/wezterm/wezterm.lua
```

### tmux Setup
```bash
cp .tmux.conf ~/.tmux.conf
cp .tmux.conf.local ~/.tmux.conf.local

# Install tmux plugin manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Install plugins (press prefix + I in tmux)
```

## Features & Functions

### Git Utilities

Both Zsh and Fish configurations include extensive Git utilities:

#### Git Aliases
- `gap` - `git add -p` (interactive staging)
- `gp` - `git push`
- `gpl` - `git pull`
- `gco` - `git commit`
- `gc` - `git clone`
- `glp` - `git log -p` with fzf
- `glo` - `git log --oneline` with fzf
- `lg` - `lazygit`

#### Advanced Git Functions
- `fgd` - Fuzzy git diff (select files to diff with fzf)
- `gch` - Git checkout branch with fzf selection
- `gda` - Git diff against current branch with preview
- `fbr` - Fuzzy branch checkout (sorted by recent commits)
- `fbR` - Alternative fuzzy branch checkout
- `fcb` - Fuzzy checkout git branch or tag with color coding
- `fcbp` - Fuzzy checkout with commit preview
- `fcc` - Fuzzy checkout git commit
- `fs` - Interactive git log with show capability
- `fcp` - Fuzzy checkout commit with preview
- `fsp` - Show git commit with preview and copy hash
- `fcs` - Get git commit SHA for use in other commands

### File & Directory Operations

- `fif <search_term>` - Find in files with fzf and preview
- `fii [directory]` - Interactive find and edit files
- `fkill` - Kill processes with fzf selection
- `mkdp <directory>` - Create directory and cd into it

### System Aliases

#### File Operations
- `v` - `nvim` (Neovim)
- `ea` - `exa -a --color=always --group-directories-first`
- `el` - `exa -l --color=always --group-directories-first`
- `et` - `exa -aT --color=always --group-directories-first`
- `cls` - `clear`
- `clsl` - `clear && ls`
- `rg` - `rg --hidden` (search hidden files by default)
- `bat` - `batcat` (if installed as batcat)

#### Navigation
- `j` - `zoxide` (smart directory jumping)
- `z` - `zoxide` (alternative)
- `zconf` - Edit shell configuration
- `wez` - Edit WezTerm configuration
- `nc` - Edit Neovim configuration

#### Package Management (Arch Linux)
- `pa` - Install packages with fzf selection and preview
- `pr` - Remove packages with fzf selection and preview
- `pi` - Show package info with fzf selection
- `pu` - System update (`sudo pacman -Syuu`)

### FZF Configuration

Both configurations include extensive FZF customization:

- **Preview window** - Right side with 60% width, toggleable with `?`
- **Navigation** - `Ctrl+U/D` for preview page up/down
- **File preview** - Uses `bat` for syntax highlighting
- **Directory preview** - Uses `tree` for directory structure
- **Git integration** - Custom previews for Git operations
- **History search** - Enhanced history with fzf

### Key Bindings

#### Fish Shell
- **Vi mode** - Enabled by default
- **Word navigation** - Alt+Left/Right for word jumping
- **Custom prompt** - Informative prompt with timestamp and status

#### Zsh
- **Oh My Zsh** - Full Oh My Zsh integration
- **Word navigation** - Alt+Left/Right for word jumping
- **Git status** - Automatic Git status hiding for performance

## Environment Variables

### Paths
- `~/.local/bin` - User local binaries
- `/home/linuxbrew/.linuxbrew/bin` - Linuxbrew binaries
- `~/.local/kitty.app/bin` - Kitty terminal binaries
- `~/.cargo/bin` - Rust/Cargo binaries

### Editors
- `EDITOR` - Set to Neovim
- `VISUAL` - Set to Neovim

### FZF Settings
- Custom preview commands for files and directories
- Integration with `fd` for file finding
- Custom key bindings for enhanced navigation

## Platform Support

### Linux (Primary)
- **Endeavour OS** - Primary development environment
- **Pop OS 22.04** - Laptop environment
- Full support for all features

### macOS
- Homebrew integration
- macOS-specific path configurations
- Conditional configurations based on platform detection

## Customization

### Adding Custom Functions

#### In Fish
```fish
function my_function --description "My custom function"
    # Your code here
end
```

#### In Zsh
```bash
my_function() {
    # Your code here
}
```

### Plugin Management

#### Fish (using Fisher)
```bash
fisher install PatrickF1/fzf.fish
fisher install jethrokuan/z
fisher install franciscolourenco/done
```

#### Zsh (using Oh My Zsh)
Edit `.zshrc` and add plugins to the `plugins=()` array.

## Troubleshooting

### Common Issues

1. **fzf not working** - Ensure fzf is installed and in PATH
2. **bat command not found** - Install bat or create alias for batcat
3. **fd command not found** - Install fd or create symlink from fdfind
4. **Git functions not working** - Ensure you're in a Git repository
5. **Prompt issues** - Check terminal color support and font configuration

### Performance

- Git status checking is optimized for large repositories
- Magic functions are disabled in Fish for better performance
- Lazy loading is used where possible

## Contributing

Feel free to submit issues and pull requests for improvements to these configurations.

## License

These dotfiles are provided as-is for personal use and customization.
