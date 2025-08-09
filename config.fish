# Fish Shell Configuration
# Ported from .zshrc with all functions and utilities

# =============================================================================
# Environment Variables
# =============================================================================

set -gx LANG en_US.UTF-8
set -gx EDITOR "/home/linuxbrew/.linuxbrew/bin/nvim"
set -gx VISUAL $EDITOR

# PATH Configuration
set -gx PATH ~/.local/bin $PATH
set -gx PATH /home/linuxbrew/.linuxbrew/bin $PATH
set -gx PATH ~/.local/kitty.app/bin $PATH
set -gx PATH ~/.cargo/bin $PATH

# Project-specific environment variables
set -gx SOURCE "$HOME/Documents/Projects/Abnormal/copy/source"
set -gx VENV "$SOURCE/.venv"

# =============================================================================
# FZF Configuration
# =============================================================================

set -gx FZF_COMMON_OPTIONS "
  --bind='?:toggle-preview'
  --bind='ctrl-u:preview-page-up'
  --bind='ctrl-d:preview-page-down'
  --preview-window 'right:60%:hidden:wrap'
  --height 100
  --min-height 50
  --preview '([[ -d {} ]] && tree -C {}) || ([[ -f {} ]] && bat --style=full --color=always {}) || echo {}'"

set -gx FZF_TMUX 1
set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --exclude .git'
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
set -gx FZF_ALT_C_COMMAND "fd --type d . --hidden"
set -gx FZF_CTRL_T_OPTS "--preview 'bat --color=always {}' --height 50 --min-height 100"
set -gx FZF_ALT_C_OPTS "--preview 'tree -C {}'"

# =============================================================================
# Git Aliases
# =============================================================================

alias gap="git add -p"
alias gp="git push"
alias gpl="git pull"
alias gco="git commit"
alias gc="git clone"
alias glp="fzf | git log -p"
alias glo="fzf | git log --oneline"
alias lg="lazygit"

# =============================================================================
# System Aliases
# =============================================================================

# Pacman aliases (for Arch-based systems)
alias pa="pacman -Slq | fzf --multi --preview 'pacman -Si {1}' | xargs -ro sudo pacman -S"
alias pr="pacman -Qq | fzf --multi --preview 'pacman -Qi {1}' | xargs -ro sudo pacman -Rns"
alias pi="pacman -Qq | fzf --multi --preview 'pacman -Qi {1}'"
alias pu="sudo pacman -Syuu"

# Better alternatives
alias v="nvim"
alias ea='exa -a --color=always --group-directories-first'  # all files and dirs
alias el='exa -l --color=always --group-directories-first'  # long format
alias et='exa -aT --color=always --group-directories-first'  # tree listing
alias cls="clear"
alias clsl="clear && ls"
alias rg="rg --hidden"
alias bat="batcat"

# Navigation aliases
alias j="zoxide"
alias z="zoxide"
alias zconf="nvim ~/.config/fish/config.fish"
alias wez="nvim ~/.config/wezterm/wezterm.lua"
alias nc="nvim ~/.config/nvim/"

# Project-specific aliases
alias venv-activate="source $SOURCE/tools/dev/venv-activate"

# =============================================================================
# Git Functions
# =============================================================================

# Better git diff with fzf
function fgd --description "Fuzzy git diff"
    set -l preview "git diff $argv --color=always -- {-1}"
    git diff $argv --name-only | fzf -m --ansi --preview $preview
end

# Git checkout branch with fzf
function gch --description "Git checkout branch with fzf"
    git branch -a | fzf -m --ansi | xargs git checkout
end

# Git diff against current branch
function gda --description "Git diff against current branch"
    set -l curr_branch (git branch --show-current)
    set -l preview "echo $curr_branch && git diff $curr_branch..{1}"
    git branch -a | fzf -m --ansi --preview $preview
end

# Checkout git branch (sorted by recent commits)
function fbr --description "Fuzzy git branch checkout (recent)"
    set -l branches (git for-each-ref --count=30 --sort=-committerdate refs/heads/ --format="%(refname:short)")
    set -l branch (echo "$branches" | fzf-tmux -d (math 2 + (echo "$branches" | wc -l)) +m)
    if test -n "$branch"
        git checkout (echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
    end
end

# Alternative branch checkout (same as fbr but different name for compatibility)
function fbR --description "Fuzzy git branch checkout (recent) - alternative"
    fbr
end

# Checkout git branch/tag with color coding
function fcb --description "Fuzzy checkout git branch or tag"
    set -l branches (git --no-pager branch --all \
        --format="%(if)%(HEAD)%(then)%(else)%(if:equals=HEAD)%(refname:strip=3)%(then)%(else)%1B[0;34;1mbranch%09%1B[m%(refname:short)%(end)%(end)" \
        | sed '/^$/d')
    set -l tags (git --no-pager tag | awk '{print "\x1b[35;1mtag\x1b[m\t" $1}')
    set -l target (printf '%s\n%s\n' "$branches" "$tags" | fzf --no-hscroll --no-multi -n 2 --ansi)
    if test -n "$target"
        git checkout (echo "$target" | awk '{print $2}')
    end
end

# Checkout git branch/tag with preview
function fcbp --description "Fuzzy checkout git branch or tag with preview"
    set -l branches (git --no-pager branch --all \
        --format="%(if)%(HEAD)%(then)%(else)%(if:equals=HEAD)%(refname:strip=3)%(then)%(else)%1B[0;34;1mbranch%09%1B[m%(refname:short)%(end)%(end)" \
        | sed '/^$/d')
    set -l tags (git --no-pager tag | awk '{print "\x1b[35;1mtag\x1b[m\t" $1}')
    set -l target (printf '%s\n%s\n' "$branches" "$tags" | fzf --no-hscroll --no-multi -n 2 \
        --ansi --preview="git --no-pager log -150 --pretty=format:%s '..{2}'")
    if test -n "$target"
        git checkout (echo "$target" | awk '{print $2}')
    end
end

# Checkout git commit
function fcc --description "Fuzzy checkout git commit"
    set -l commits (git log --pretty=oneline --abbrev-commit --reverse)
    set -l commit (echo "$commits" | fzf --tac +s +m -e)
    if test -n "$commit"
        git checkout (echo "$commit" | sed "s/ .*//")
    end
end

# Interactive git log with fzf
function fs --description "Fuzzy git log with show"
    git log --graph --color=always \
        --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" $argv | \
    fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
        --bind "ctrl-m:execute:
                  (grep -o '[a-f0-9]\{7\}' | head -1 |
                  xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
                  {}
FZF-EOF"
end

# Git log without graph (helper function)
function glNoGraph --description "Git log without graph"
    git log --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr% C(auto)%an" $argv
end

# Git log line to hash conversion
set -g _gitLogLineToHash "echo {} | grep -o '[a-f0-9]\{7\}' | head -1"
set -g _viewGitLogLine "$_gitLogLineToHash | xargs -I % sh -c 'git show --color=always % | diff-so-fancy'"

# Checkout git commit with preview
function fcp --description "Fuzzy checkout git commit with preview"
    set -l commit (glNoGraph | fzf --no-sort --reverse --tiebreak=index --no-multi \
        --ansi --preview="$_viewGitLogLine")
    if test -n "$commit"
        git checkout (echo "$commit" | sed "s/ .*//")
    end
end

# Show git commit with preview
function fsp --description "Fuzzy show git commit with preview"
    glNoGraph | fzf --no-sort --reverse --tiebreak=index --no-multi \
        --ansi --preview="$_viewGitLogLine" \
        --header "enter to view, alt-y to copy hash" \
        --bind "enter:execute:$_viewGitLogLine | less -R" \
        --bind "alt-y:execute:$_gitLogLineToHash | xclip"
end

# Get git commit SHA
function fcs --description "Fuzzy get git commit SHA"
    set -l commits (git log --color=always --pretty=oneline --abbrev-commit --reverse)
    set -l commit (echo "$commits" | fzf --tac +s +m -e --ansi --reverse)
    if test -n "$commit"
        echo -n (echo "$commit" | sed "s/ .*//")
    end
end

# =============================================================================
# File and Directory Functions
# =============================================================================

# Find in files with fzf
function fif --description "Find in files with fzf"
    if not test (count $argv) -gt 0
        echo "Need a string to search for!"
        return 1
    end
    rg --files-with-matches --no-messages "$argv[1]" | fzf --preview "highlight -O ansi -l {} 2> /dev/null | rg --colors 'match:bg:yellow' --ignore-case --pretty --context 10 '$argv[1]' || rg --ignore-case --pretty --context 10 '$argv[1]' {}"
end

# Interactive find and edit
function fii --description "Interactive find and edit files"
    if test -n "$argv[1]"
        cd $argv[1] # go to provided folder or noop
    end
    set -l RG_DEFAULT_COMMAND "rg -i -l --hidden --no-ignore-vcs"
    
    set -l selected (env FZF_DEFAULT_COMMAND="rg --files" fzf \
        -m \
        -e \
        --ansi \
        --disabled \
        --reverse \
        --bind "ctrl-a:select-all" \
        --bind "f12:execute-silent:(subl -b {})" \
        --bind "change:reload:$RG_DEFAULT_COMMAND {q} || true" \
        --preview "rg -i --pretty --context 2 {q} {}" | cut -d":" -f1,2)
    
    if test -n "$selected"
        nvim $selected # open multiple files in editor
    end
end

# Kill processes with fzf
function fkill --description "Kill processes with fzf"
    set -l pid
    if test "$UID" != "0"
        set pid (ps -f -u $UID | sed 1d | fzf -m | awk '{print $2}')
    else
        set pid (ps -ef | sed 1d | fzf -m | awk '{print $2}')
    end
    
    if test -n "$pid"
        echo $pid | xargs kill -$argv[1] 2>/dev/null; or echo $pid | xargs kill -9
    end
end

# Create directory and cd into it
function mkdp --description "Make directory and cd into it"
    mkdir -p $argv[1] && cd $argv[1]
end

# =============================================================================
# Utility Functions
# =============================================================================

# Function to set Oh My Zsh Git configurations (adapted for Fish)
function set_oh_my_zsh_git_config --description "Set git config for oh-my-zsh compatibility"
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1
        git config --add oh-my-zsh.hide-status 1 2>/dev/null
        git config --add oh-my-zsh.hide-dirty 1 2>/dev/null
    end
end

# =============================================================================
# Key Bindings
# =============================================================================

# Enable vi key bindings
fish_vi_key_bindings

# Custom key bindings for word navigation (if supported by terminal)
bind -M insert \e\[1\;3D backward-word
bind -M insert \e\[1\;3C forward-word

# =============================================================================
# Initialization
# =============================================================================

# Initialize zoxide for directory jumping
if command -v zoxide > /dev/null
    zoxide init fish | source
end

# Initialize fzf key bindings if available
if test -f ~/.fzf.fish
    source ~/.fzf.fish
end

# Initialize autojump if available (macOS path)
if test -s /Users/krshrimali/.autojump/etc/profile.d/autojump.fish
    source /Users/krshrimali/.autojump/etc/profile.d/autojump.fish
end

# Call git config setup function
set_oh_my_zsh_git_config

# Disable magic functions for better performance
set -g DISABLE_MAGIC_FUNCTIONS true

# =============================================================================
# Interactive Mode Setup
# =============================================================================

if status is-interactive
    # Commands to run in interactive sessions can go here
    
    # Custom prompt (keeping the existing sophisticated prompt)
    function fish_prompt --description 'Informative prompt'
        #Save the return status of the previous command
        set -l last_pipestatus $pipestatus
        set -lx __fish_last_status $status # Export for __fish_print_pipestatus.

        if functions -q fish_is_root_user; and fish_is_root_user
            printf '%s@%s %s%s%s# ' $USER (prompt_hostname) (set -q fish_color_cwd_root
                                                             and set_color $fish_color_cwd_root
                                                             or set_color $fish_color_cwd) \
                (prompt_pwd) (set_color normal)
        else
            set -l status_color (set_color $fish_color_status)
            set -l statusb_color (set_color --bold $fish_color_status)
            set -l pipestatus_string (__fish_print_pipestatus "[" "]" "|" "$status_color" "$statusb_color" $last_pipestatus)

            printf '[%s] %s%s@%s %s%s %s%s%s \n> ' (date "+%H:%M:%S") (set_color brblue) \
                $USER (prompt_hostname) (set_color $fish_color_cwd) $PWD $pipestatus_string \
                (set_color normal)
        end
    end
    
    # Disable right prompt
    functions -e fish_right_prompt 2>/dev/null
end

# =============================================================================
# Conditional Configurations
# =============================================================================

# macOS specific configurations
if test (uname) = "Darwin"
    set -gx PATH /opt/homebrew/bin $PATH
end

# Linux specific configurations  
if test (uname) = "Linux"
    # Add any Linux-specific configurations here
end

# =============================================================================
# Plugin Management (Fisher)
# =============================================================================

# Uncomment and modify as needed for your Fisher plugins
# if not functions -q fisher
#     curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
# end

# Example Fisher plugins (uncomment as needed):
# fisher install PatrickF1/fzf.fish
# fisher install jethrokuan/z
# fisher install franciscolourenco/done
