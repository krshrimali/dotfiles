# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="geoffgarside"
# ZSH_THEME="josh"
# ZSH_THEME="agnoster"
ZSH_THEME="sorin"

plugins=(git themes)

source $ZSH/oh-my-zsh.sh

export LANG=en_US.UTF-8

# Git aliases
alias gap="git add -p"
alias gp="git push"
alias gpl="git pull"
alias gco="git commit"
alias gc="git clone"
alias glp="fzf | git log -p"
alias glo="fzf | git log --oneline"

# Alias for lazygit
# TODO: @krshrimali: check if lazygit is installed, then only run this, also raise a warning
alias lg="lazygit"

export EDITOR="/home/linuxbrew/.linuxbrew/bin/nvim"
export VISUAL=$EDITOR

export PATH=~/.local/bin:$PATH

# The next line updates PATH for the Google Cloud SDK.
# if [ -f '/home/krshrimali/google-cloud-sdk/path.zsh.inc' ]; then . '/home/krshrimali/google-cloud-sdk/path.zsh.inc'; fi

# # The next line enables shell command completion for gcloud.
# if [ -f '/home/krshrimali/google-cloud-sdk/completion.zsh.inc' ]; then . '/home/krshrimali/google-cloud-sdk/completion.zsh.inc'; fi

# # # Source: https://wiki.archlinux.org/title/fzf
# # # fzf aliases and key-bindings
# # # export FZF_DEFAULT_OPTS="--ansi --preview-window 'right:60%' --preview 'bat --color=always --style=header,grid --line-range :300 {}'"
# # # export FZF_PREVIEW_COMMAND="bat --style=numbers,changes --wrap never --color always {} || cat {} || tree -C {}"
# # # # export FZF_CTRL_T_OPTS="--min-height 30 --preview-window down:60% --preview-window noborder --preview '($FZF_PREVIEW_COMMAND) 2> /dev/null'"

# # this is what matters
FZF_COMMON_OPTIONS="
  --bind='?:toggle-preview'
  --bind='ctrl-u:preview-page-up'
  --bind='ctrl-d:preview-page-down'
  --preview-window 'right:60%:hidden:wrap'
  --height 100
  --min-height 50
  --preview '([[ -d {} ]] && tree -C {}) || ([[ -f {} ]] && bat --style=full --color=always {}) || echo {}'"

# command -v fd > /dev/null && export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
# command -v bat > /dev/null && command -v tree > /dev/null && export FZF_DEFAULT_OPTS="$FZF_COMMON_OPTIONS"
alias v="nvim"
# command -v fd > /dev/null && export FZF_ALT_C_COMMAND='fd --type d . --exclude .git'
export FZF_TMUX=1
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type d . --hidden"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always {}' --height 50 --min-height 100"
export FZF_ALT_C_OPTS="--preview 'tree -C {}'"
# command -v fd > /dev/null && export FZF_CTRL_T_COMMAND='fd --type f --hidden --exclude .git'

alias pa="pacman -Slq | fzf --multi --preview 'pacman -Si {1}' | xargs -ro sudo pacman -S"
alias pr="pacman -Qq | fzf --multi --preview 'pacman -Qi {1}' | xargs -ro sudo pacman -Rns"
alias pi="pacman -Qq | fzf --multi --preview 'pacman -Qi {1}'"
alias pu="sudo pacman -Syuu"

# Better git diff
fgd() {
  preview="git diff $@ --color=always -- {-1}"
  git diff $@ --name-only | fzf -m --ansi --preview $preview
}

# Git checkout
gch() {
  git branch -a | fzf -m --ansi | xargs git checkout
}

# Git diff against
gda() {
  curr_branch="$(git branch --show-current)"
  preview="echo $curr_branch && git diff $curr_branch..{1}"
  get_diff="git diff $curr_branch.."
  git branch -a | fzf -m --ansi --preview $preview | bat $preview | diff-so-fancy
}

fif() {
  if [ ! "$#" -gt 0 ]; then echo "Need a string to search for!"; return 1; fi
  rg --files-with-matches --no-messages "$1" | fzf --preview "highlight -O ansi -l {} 2> /dev/null | rg --colors 'match:bg:yellow' --ignore-case --pretty --context 10 '$1' || rg --ignore-case --pretty --context 10 '$1' {}"
}

fii() {
  [[ -n $1 ]] && cd $1 # go to provided folder or noop
  RG_DEFAULT_COMMAND="rg -i -l --hidden --no-ignore-vcs"

  selected=$(
  FZF_DEFAULT_COMMAND="rg --files" fzf \
    -m \
    -e \
    --ansi \
    --disabled \
    --reverse \
    --bind "ctrl-a:select-all" \
    --bind "f12:execute-silent:(subl -b {})" \
    --bind "change:reload:$RG_DEFAULT_COMMAND {q} || true" \
    --preview "rg -i --pretty --context 2 {q} {}" | cut -d":" -f1,2
  )
  [[ -n $selected ]] && nvim $selected # open multiple files in editor
}

# fkill - kill processes - list only the ones you can kill. Modified the earlier script.
fkill() {
    local pid 
    if [ "$UID" != "0" ]; then
        pid=$(ps -f -u $UID | sed 1d | fzf -m | awk '{print $2}')
    else
        pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
    fi  

    if [ "x$pid" != "x" ]
    then
        echo $pid | xargs kill -${1:-9}
    fi  
}

fbr() {
  local branches branch
  branches=$(git --no-pager branch -vv) &&
  branch=$(echo "$branches" | fzf +m) &&
  git checkout $(echo "$branch" | awk '{print $1}' | sed "s/.* //")
}


# fbr - checkout git branch (including remote branches), sorted by most recent commit, limit 30 last branches
fbr() {
  local branches branch
  branches=$(git for-each-ref --count=30 --sort=-committerdate refs/heads/ --format="%(refname:short)") &&
  branch=$(echo "$branches" |
           fzf-tmux -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
  git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}


# fbr - checkout git branch (including remote branches), sorted by most recent commit, limit 30 last branches
fbR() {
  local branches branch
  branches=$(git for-each-ref --count=30 --sort=-committerdate refs/heads/ --format="%(refname:short)") &&
  branch=$(echo "$branches" |
           fzf-tmux -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
  git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

# fco - checkout git branch/tag
fcb() {
  local tags branches target
  branches=$(
    git --no-pager branch --all \
      --format="%(if)%(HEAD)%(then)%(else)%(if:equals=HEAD)%(refname:strip=3)%(then)%(else)%1B[0;34;1mbranch%09%1B[m%(refname:short)%(end)%(end)" \
    | sed '/^$/d') || return
  tags=$(
    git --no-pager tag | awk '{print "\x1b[35;1mtag\x1b[m\t" $1}') || return
  target=$(
    (echo "$branches"; echo "$tags") |
    fzf --no-hscroll --no-multi -n 2 \
        --ansi) || return
  git checkout $(awk '{print $2}' <<<"$target" )
}


# fco_preview - checkout git branch/tag, with a preview showing the commits between the tag/branch and HEAD
fcbp() {
  local tags branches target
  branches=$(
    git --no-pager branch --all \
      --format="%(if)%(HEAD)%(then)%(else)%(if:equals=HEAD)%(refname:strip=3)%(then)%(else)%1B[0;34;1mbranch%09%1B[m%(refname:short)%(end)%(end)" \
    | sed '/^$/d') || return
  tags=$(
    git --no-pager tag | awk '{print "\x1b[35;1mtag\x1b[m\t" $1}') || return
  target=$(
    (echo "$branches"; echo "$tags") |
    fzf --no-hscroll --no-multi -n 2 \
        --ansi --preview="git --no-pager log -150 --pretty=format:%s '..{2}'") || return
  git checkout $(awk '{print $2}' <<<"$target" )
}

# fcoc - checkout git commit
fcc() {
  local commits commit
  commits=$(git log --pretty=oneline --abbrev-commit --reverse) &&
  commit=$(echo "$commits" | fzf --tac +s +m -e) &&
  git checkout $(echo "$commit" | sed "s/ .*//")
}

fs() {
  git log --graph --color=always \
      --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
  fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
      --bind "ctrl-m:execute:
                (grep -o '[a-f0-9]\{7\}' | head -1 |
                xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
                {}
FZF-EOF"
}

alias glNoGraph='git log --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr% C(auto)%an" "$@"'
_gitLogLineToHash="echo {} | grep -o '[a-f0-9]\{7\}' | head -1"
_viewGitLogLine="$_gitLogLineToHash | xargs -I % sh -c 'git show --color=always % | diff-so-fancy'"
# fcocp - checkout git commit with previews
fcp() {
  local commit
  commit=$( glNoGraph |
    fzf --no-sort --reverse --tiebreak=index --no-multi \
        --ansi --preview="$_viewGitLogLine" ) &&
  git checkout $(echo "$commit" | sed "s/ .*//")
}

fsp() {
    glNoGraph |
        fzf --no-sort --reverse --tiebreak=index --no-multi \
            --ansi --preview="$_viewGitLogLine" \
                --header "enter to view, alt-y to copy hash" \
                --bind "enter:execute:$_viewGitLogLine   | less -R" \
                --bind "alt-y:execute:$_gitLogLineToHash | xclip"
}

# fcs - get git commit sha
# example usage: git rebase -i `fcs`
fcs() {
  local commits commit
  commits=$(git log --color=always --pretty=oneline --abbrev-commit --reverse) &&
  commit=$(echo "$commits" | fzf --tac +s +m -e --ansi --reverse) &&
  echo -n $(echo "$commit" | sed "s/ .*//")
}

# fstash - easier way to deal with stashes
# type fstash to get a list of your stashes
# enter shows you the contents of the stash
# ctrl-d shows a diff of the stash against your current HEAD
# ctrl-b checks the stash out as a branch, for easier merging
# fstash() {
#   local out q k sha
#   while out=$(
#     git stash list --pretty="%C(yellow)%h %>(14)%Cgreen%cr %C(blue)%gs" |
#     fzf --ansi --no-sort --query="$q" --print-query \
#         --expect=ctrl-d,ctrl-b);
#   do
#     mapfile -t out <<< "$out"
#     q="${out[0]}"
#     k="${out[1]}"
#     sha="${out[-1]}"
#     sha="${sha%% *}"
#     [[ -z "$sha" ]] && continue
#     if [[ "$k" == 'ctrl-d' ]]; then
#       git diff $sha
#     elif [[ "$k" == 'ctrl-b' ]]; then
#       git stash branch "stash-$sha" $sha
#       break;
#     else
#       git stash show -p $sha
#     fi
#   done
# }

# # # Forgit
# # # [ -f ~/.forgit/forgit.plugin.zsh ] && source ~/.forgit/forgit.plugin.zsh

# # # export FZF_DEFAULT_COMMAND='fd --type f --color=never --hidden'

# source /usr/share/fzf/key-bindings.zsh
# source /usr/share/fzf/completion.zsh

# From dt's dotfiles: https://gitlab.com/dwt1/dotfiles/-/blob/master/.zshrc
alias ea='exa -a --color=always --group-directories-first'  # all files and dirs
alias el='exa -l --color=always --group-directories-first'  # long format
alias et='exa -aT --color=always --group-directories-first'  # tree listing

alias cls="clear"
alias clsl="clear && ls"
alias mkdp='mkdir -p "$0" && cd "$0"'
alias rg="rg --hidden"

export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
# alias python="python3"
# alias python3="python"

[[ -s /Users/krshrimali/.autojump/etc/profile.d/autojump.sh ]] && source /Users/krshrimali/.autojump/etc/profile.d/autojump.sh
    autoload -U compinit && compinit -u
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
alias bat="batcat"
export PATH=~/.local/kitty.app/bin/:$PATH

export SOURCE="$HOME/Documents/Projects/Abnormal/copy/source"
export VENV="$SOURCE/.venv"
alias venv-activate="source $SOURCE/tools/dev/venv-activate"
# source $SOURCE/tools/dev/common_bash_includes
# source "$VENV/bin/activate.fish"

# export ZPLUG_HOME=/opt/homebrew/opt/zplug
# source $ZPLUG_HOME/init.zsh
# zplug "tranzystorek-io/zellij-zsh"
# zellij
# venv-activate
# export python3="/Users/krshrimali/Documents/Projects/Abnormal/copy/source/.venv/bin/python3"
# git config --local oh-my-zsh.hide-status 1
# git config --local oh-my-zsh.hide-dirty 1

alias z="zoxide
alias j="zoxide
alias zconf="nvim ~/.zshrc"
alias wez="nvim ~/.config/wezterm/wezterm.lua"
alias nc="nvim ~/.config/nvim/"

# eval "$(zellij setup --generate-auto-start zsh)"
eval "$(zoxide init zsh)"

# Function to set Oh My Zsh Git configurations if the current directory is a Git repository
set_oh_my_zsh_git_config() {
  if [[ -n $(git rev-parse --is-inside-work-tree 2>/dev/null) ]]; then
    git config --add oh-my-zsh.hide-status 1
    git config --add oh-my-zsh.hide-dirty 1
  fi
}

alias wez="nvim ~/.config/wezterm/wezterm.lua"
alias nc="nvim ~/.config/nvim/"

bindkey "^[[1;3D" backward-word
bindkey "^[[1;3C" forward-word

DISABLE_MAGIC_FUNCTIONS=true

# Call the function
set_oh_my_zsh_git_config
