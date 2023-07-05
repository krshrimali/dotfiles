# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
eval /opt/anaconda3/bin/conda "shell.fish" "hook" $argv | source
# <<< conda initialize <<<

alias gap "git add -p"
alias gp "git push"
alias gpl "git pull"
alias gco "git commit"
alias gc "git clone"
alias glp "fzf | git log -p"
alias glo "fzf | git log --oneline"

alias lg lazygit

set -xg EDITOR "/opt/homebrew/bin/nvim"
set -xg VISUAL $EDITOR
set -xg PATH ~/.local/bin $PATH

set -xg FZF_COMMON_OPTIONS "
  --bind='?:toggle-preview'
  --bind='ctrl-u:preview-page-up'
  --bind='ctrl-d:preview-page-down'
  --preview-window 'right:60%:hidden:wrap'
  --height 100
  --min-height 50
  --preview '([[ -d {} ]] && tree -C {}) || ([[ -f {} ]] && bat --style=full --color=always {}) || echo {}'"

alias v nvim
set -xg FZF_TMUX 1
set -xg FZF_DEFAULT_COMMAND 'fd --type f --hidden --exclude .git'
set -xg FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
set -xg FZF_ALT_C_COMMAND "fd --type d . --hidden"
set -xg FZF_CTRL_T_OPTS "--preview 'bat --color=always {}' --height 50 --min-height 100"
set -xg FZF_ALT_C_OPTS "--preview 'tree -C {}'"

# Fuzzy find and open files with vim
function vif
  set files (fd -t f -H --exclude .git | fzf --preview 'bat --color=always {}')
  if test -n "$files"
    vim $files
  end
end

# Fuzzy find and cd into directories
function cdf
  set dir (fd -t d -H --exclude .git | fzf --preview 'tree -C {}')
  if test -n "$dir"
    cd $dir
  end
end

# Set the prompt
function fish_prompt
  set -l exit_status $status
  if test $exit_status -ne 0
    set_color red
    echo -n "($exit_status) "
    set_color normal
  end
  echo -n (prompt_pwd)
  set_color cyan
  echo -n ' ⚡ '
  set_color normal
end

# Better git diff
function fgd
  set preview "git diff $argv --color=always -- {-1}"
  git diff $argv --name-only | fzf -m --ansi --preview $preview
end

# Git checkout
function gch
  git branch -a | fzf -m --ansi | xargs git checkout
end

# Git diff against
function gda
  set curr_branch (git branch --show-current)
  set preview "echo $curr_branch && git diff $curr_branch..{1}"
  set get_diff "git diff $curr_branch.."
  git branch -a | fzf -m --ansi --preview $preview | bat $preview | diff-so-fancy
end

function fif
  if not test (count $argv) -gt 0
    echo "Need a string to search for!"
    return 1
  end
  rg --files-with-matches --no-messages $argv | fzf --preview "highlight -O ansi -l {} 2> /dev/null | rg --colors 'match:bg:yellow' --ignore-case --pretty --context 10 '$argv' || rg --ignore-case --pretty --context 10 '$argv' {}"
end

function fii
  if test -n $argv[1]
    cd $argv[1] # go to provided folder or noop
  end
  set RG_DEFAULT_COMMAND "rg -i -l --hidden --no-ignore-vcs"

  set selected (FZF_DEFAULT_COMMAND "rg --files" fzf \
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
  if test -n $selected
    nvim $selected # open multiple files in editor
  end
end

# fkill - kill processes - list only the ones you can kill. Modified the earlier script.
# function fkill
#   if test "$UID" != "0"
#     set pid (ps -f -u $UID | sed 1d | fzf -m | awk '{print $2}')
#   else
#     set pid (ps -ef | sed 1d | fzf -m | awk '{print $2}')
#   end

#   if test "x$pid" != "x"
#     echo $pid | xargs kill -${1:-9}
#   end
# end

function fbr
  set branches (git --no-pager branch -vv)
  set branch (echo "$branches" | fzf +m)
  git checkout (echo "$branch" | awk '{print $1}' | sed "s/.* //")
end

# fbr - checkout git branch (including remote branches), sorted by most recent commit, limit 30 last branches
function fbr
  set branches (git for-each-ref --count=30 --sort=-committerdate refs/heads/ --format="%(refname:short)")
  set branch (echo "$branches" | fzf-tmux -d (math 2 + (count (echo "$branches" | wc -l))) +m)
  git checkout (echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
end

# fbr - checkout git branch (including remote branches), sorted by most recent commit, limit 30 last branches
function fbR
  set branches (git for-each-ref --count=30 --sort=-committerdate refs/heads/ --format="%(refname:short)")
  set branch (echo "$branches" | fzf-tmux -d (math 2 + (count (echo "$branches" | wc -l))) +m)
  git checkout (echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
end

function fii
  if test -n $argv[1]
    cd $argv[1] # go to provided folder or noop
  end
  set RG_DEFAULT_COMMAND "rg -i -l --hidden --no-ignore-vcs"

  set selected (FZF_DEFAULT_COMMAND "rg --files" fzf \
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
  if test -n $selected
    nvim $selected # open multiple files in editor
  end
end

# fkill - kill processes - list only the ones you can kill. Modified the earlier script.
# function fkill
#   if test "$UID" != "0"
#     set pid (ps -f -u $UID | sed 1d | fzf -m | awk '{print $2}')
#   else
#     set pid (ps -ef | sed 1d | fzf -m | awk '{print $2}')
#   end

#   if test "x$pid" != "x"
#     echo $pid | xargs kill -${1:-9}
#   end
# end

function fbr
  set branches (git --no-pager branch -vv)
  set branch (echo "$branches" | fzf +m)
  git checkout (echo "$branch" | awk '{print $1}' | sed "s/.* //")
end

# fbr - checkout git branch (including remote branches), sorted by most recent commit, limit 30 last branches
function fbr
  set branches (git for-each-ref --count=30 --sort=-committerdate refs/heads/ --format="%(refname:short)")
  set branch (echo "$branches" | fzf-tmux -d (math 2 + (count (echo "$branches" | wc -l))) +m)
  git checkout (echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
end

# fbr - checkout git branch (including remote branches), sorted by most recent commit, limit 30 last branches
function fbR
  set branches (git for-each-ref --count=30 --sort=-committerdate refs/heads/ --format="%(refname:short)")
  set branch (echo "$branches" | fzf-tmux -d (math 2 + (count (echo "$branches" | wc -l))) +m)
  git checkout (echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
end

# fco - checkout git branch/tag
function fcb
  set tags branches target
  set branches (git --no-pager branch --all \
      --format="%(if)%(HEAD)%(then)%(else)%(if:equals=HEAD)%(refname:strip=3)%(then)%(else)%1B[0;34;1mbranch%09%1B[m%(refname:short)%(end)%(end)" \
    | sed '/^$/d') || return
  set tags (git --no-pager tag | awk '{print "\x1b[35;1mtag\x1b[m\t" $1}') || return
  set target (
    echo "$branches"
    echo "$tags"
  ) | fzf --no-hscroll --no-multi -n 2 --ansi || return
  git checkout (echo "$target" | awk '{print $2}')
end

# fco_preview - checkout git branch/tag, with a preview showing the commits between the tag/branch and HEAD
function fcbp
  set tags branches target
  set branches (git --no-pager branch --all \
      --format="%(if)%(HEAD)%(then)%(else)%(if:equals=HEAD)%(refname:strip=3)%(then)%(else)%1B[0;34;1mbranch%09%1B[m%(refname:short)%(end)%(end)" \
    | sed '/^$/d') || return
  set tags (git --no-pager tag | awk '{print "\x1b[35;1mtag\x1b[m\t" $1}') || return
  set target (
    echo "$branches"
    echo "$tags"
  ) | fzf --no-hscroll --no-multi -n 2 --ansi --preview="git --no-pager log -150 --pretty=format:%s '..{2}'" || return
  git checkout (echo "$target" | awk '{print $2}')
end

# fcoc - checkout git commit
function fcc
  set commits commit
  set commits (git log --pretty=oneline --abbrev-commit --reverse) || return
  set commit (echo "$commits" | fzf --tac +s +m -e) || return
  git checkout (echo "$commit" | sed "s/ .*//")
end

function fs
  git log --graph --color=always \
      --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" $argv | \
  fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
      --bind "ctrl-m:execute:\
                (grep -o '[a-f0-9]\{7\}' | head -1 | \
                xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'\
                {}\
FZF-EOF"
end

alias glNoGraph 'git log --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr% C(auto)%an" "$argv"'
set _gitLogLineToHash "echo {} | grep -o '[a-f0-9]\{7\}' | head -1"
set _viewGitLogLine "$_gitLogLineToHash | xargs -I % sh -c 'git show --color=always % | diff-so-fancy'"

# fcocp - checkout git commit with previews
function fcp
  set commit
  set commit (glNoGraph | fzf --no-sort --reverse --tiebreak=index --no-multi \
        --ansi --preview="$_viewGitLogLine") || return
  git checkout (echo "$commit" | sed "s/ .*//")
end

function fsp
  glNoGraph | \
        fzf --no-sort --reverse --tiebreak=index --no-multi \
            --ansi --preview="$_viewGitLogLine" \
                --header "enter to view, alt-y to copy hash" \
                --bind "enter:execute:$_viewGitLogLine   | less -R" \
                --bind "alt-y:execute:$_gitLogLineToHash | xclip"
end

# fcs - get git commit sha
# example usage: git rebase -i (fcs)
function fcs
    set -l commits commit
    set commits (git log --color=always --pretty=oneline --abbrev-commit --reverse)
    set commit (echo "$commits" | fzf --tac +s +m -e --ansi --reverse)
    echo -n (echo "$commit" | sed "s/ .*//")
end

alias rg "rg --hidden"

set -x PATH "/opt/homebrew/bin/" $PATH
alias bat "batcat"
set -x SOURCE "$HOME/Documents/Projects/Abnormal/copy/source"
set -x VENV "$SOURCE/.venv"
set -x PATH "$SOURCE/tools/dev" $PATH

git config --add oh-my-zsh.hide-status 1
git config --add oh-my-zsh.hide-dirty 1
alias z "zoxide query"
alias j "zoxide query"
# starship init fish | source
source $SOURCE/.venv/bin/activate.fish
