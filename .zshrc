# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Controls whether the cursor style is changed when switching to a diff input mode
# Default is unset
VI_MODE_SET_CURSOR=true

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git vi-mode)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
export PATH=/home/linuxbrew/.linuxbrew/bin:$PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
alias gap="git add -p"
alias gaa="git add --all"
alias gc="git commit -v"
alias gcm="git commit -m"
alias gca="git commit -v --amend"
alias gs="git status -sb"
alias gd="git diff"
alias gds="git diff --staged"
alias gl="git log --oneline --decorate --color --graph"
alias glp="git log --stat -p | nvim -R -"
alias gp="git push"
alias gpf="git push --force-with-lease"
alias gpl="git pull"
gpo() { git push origin "$(git branch --show-current)" "$@" }
gPo() { git pull origin "$(git branch --show-current)" "$@" }
alias gco="git checkout"
alias gcb="git checkout -b"
alias gb="git branch"
alias gbd="git branch -d"
alias grb="git rebase"
alias grbi="git rebase -i"
alias gst="git stash"
alias gstp="git stash pop"
alias gstl="git stash list"
alias grh="git reset HEAD"
alias grhh="git reset HEAD --hard"
alias gcp="git cherry-pick"

# Auto-activate .venv on cd
function chpwd() {
    if [[ -d .venv ]]; then
        source .venv/bin/activate
    fi
}
eval "$(zoxide init zsh)"

# Store timestamps in history
setopt EXTENDED_HISTORY

# Ctrl+R: fuzzy history search with timestamps
fzf-history-widget() {
    local selected
    selected=$(fc -li 1 2>/dev/null | fzf \
        --height 50% \
        --reverse \
        --tac \
        --no-sort \
        --query "$LBUFFER" \
        --prompt "history> " \
        --preview 'echo {}' \
        --preview-window 'down:2:wrap')
    if [[ -n "$selected" ]]; then
        # fc -li format: "  NUM  DATE  TIME  COMMAND"
        LBUFFER=$(echo "$selected" | sed 's/^ *[0-9]* *[0-9-]* *[0-9:]* *//')
    fi
    zle redisplay
}
zle -N fzf-history-widget
bindkey '^R' fzf-history-widget

# Ctrl+T: fuzzy file search with bat preview
fzf-file-widget() {
    local selected
    selected=$(
        { command -v fd &>/dev/null \
            && fd --type f --hidden --follow --exclude .git \
            || find . -type f 2>/dev/null; } | \
        fzf \
            --height 70% \
            --reverse \
            --multi \
            --preview 'bat --color=always --style=numbers,changes --line-range=:200 {}' \
            --preview-window 'right:60%:wrap'
    )
    if [[ -n "$selected" ]]; then
        LBUFFER+="${(q)selected}"
    fi
    zle redisplay
}
zle -N fzf-file-widget
bindkey '^T' fzf-file-widget
alias lg="lazygit"
