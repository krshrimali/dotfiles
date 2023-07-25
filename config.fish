# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
# <<< conda initialize <<<

alias gap "git add -p"
alias gp "git push"
alias gpl "git pull"
alias gco "git commit"
alias gc "git clone"
alias glp "fzf | git log -p"
alias glo "fzf | git log --oneline"

alias lg lazygit

set -xg EDITOR "/home/linuxbrew/.linuxbrew/bin//nvim"
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

set -xg PATH "/home/linuxbrew/.linuxbrew/bin/" $PATH
# alias bat "batcat"

# git config --add oh-my-zsh.hide-status 1
# git config --add oh-my-zsh.hide-dirty 1
zoxide init fish | source
alias j "zoxide"
# starship init fish | source

functions -e fish_right_prompt; function fish_prompt -d "Write out the prompt"
    set -l laststatus $status

    set -l git_info
    if set -l git_branch (command git symbolic-ref HEAD 2>/dev/null | string replace refs/heads/ '')
        set git_branch (set_color -o blue)"$git_branch"
        set -l git_status
        if not command git diff-index --quiet HEAD --
            if set -l count (command git rev-list --count --left-right $upstream...HEAD 2>/dev/null)
                echo $count | read -l ahead behind
                if test "$ahead" -gt 0
                    set git_status "$git_status"(set_color red)⬆
                end
                if test "$behind" -gt 0
                    set git_status "$git_status"(set_color red)⬇
                end
            end
            for i in (git status --porcelain | string sub -l 2 | sort | uniq)
                switch $i
                    case "."
                        set git_status "$git_status"(set_color green)✚
                    case " D"
                        set git_status "$git_status"(set_color red)✖
                    case "*M*"
                        set git_status "$git_status"(set_color green)✱
                    case "*R*"
                        set git_status "$git_status"(set_color purple)➜
                    case "*U*"
                        set git_status "$git_status"(set_color brown)═
                    case "??"
                        set git_status "$git_status"(set_color red)≠
                end
            end
        else
            set git_status (set_color green):
        end
        set git_info "(git$git_status$git_branch"(set_color white)")"
    end

    # Disable PWD shortening by default.
    set -q fish_prompt_pwd_dir_length
    or set -lx fish_prompt_pwd_dir_length 0

    set_color -b black
    printf '%s%s%s%s%s%s%s%s%s%s%s%s%s' (set_color -o white) '❰' (set_color green) $USER (set_color white) '❙' (set_color yellow) (prompt_pwd) (set_color white) $git_info (set_color white) '❱' (set_color white)
    if test $laststatus -eq 0
        printf "%s✔%s≻%s " (set_color -o green) (set_color white) (set_color normal)
    else
        printf "%s✘%s≻%s " (set_color -o red) (set_color white) (set_color normal)
    end
end
# funcsave fish_prompt && funcsave fish_right_prompt 2>/dev/null

functions -e fish_right_prompt; function fish_prompt
    # This prompt shows:
    # - green lines if the last return command is OK, red otherwise
    # - your user name, in red if root or yellow otherwise
    # - your hostname, in cyan if ssh or blue otherwise
    # - the current path (with prompt_pwd)
    # - date +%X
    # - the current virtual environment, if any
    # - the current git status, if any, with fish_git_prompt
    # - the current battery state, if any, and if your power cable is unplugged, and if you have "acpi"
    # - current background jobs, if any

    # It goes from:
    # ┬─[nim@Hattori:~]─[11:39:00]
    # ╰─>$ echo here

    # To:
    # ┬─[nim@Hattori:~/w/dashboard]─[11:37:14]─[V:django20]─[G:master↑1|●1✚1…1]─[B:85%, 05:41:42 remaining]
    # │ 2    15054    0%    arrêtée    sleep 100000
    # │ 1    15048    0%    arrêtée    sleep 100000
    # ╰─>$ echo there

    set -l retc red
    test $status = 0; and set retc green

    set -q __fish_git_prompt_showupstream
    or set -g __fish_git_prompt_showupstream auto

    function _nim_prompt_wrapper
        set retc $argv[1]
        set -l field_name $argv[2]
        set -l field_value $argv[3]

        set_color normal
        set_color $retc
        echo -n '─'
        set_color -o green
        echo -n '['
        set_color normal
        test -n $field_name
        and echo -n $field_name:
        set_color $retc
        echo -n $field_value
        set_color -o green
        echo -n ']'
    end

    set_color $retc
    echo -n '┬─'
    set_color -o green
    echo -n [

    if functions -q fish_is_root_user; and fish_is_root_user
        set_color -o red
    else
        set_color -o yellow
    end

    echo -n $USER
    set_color -o white
    echo -n @

    if test -z "$SSH_CLIENT"
        set_color -o blue
    else
        set_color -o cyan
    end

    echo -n (prompt_hostname)
    set_color -o white
    echo -n :(prompt_pwd)
    set_color -o green
    echo -n ']'

    # Date
    _nim_prompt_wrapper $retc '' (date +%X)

    # Vi-mode
    # The default mode prompt would be prefixed, which ruins our alignment.
    function fish_mode_prompt
    end

    if test "$fish_key_bindings" = fish_vi_key_bindings
        or test "$fish_key_bindings" = fish_hybrid_key_bindings
        set -l mode
        switch $fish_bind_mode
            case default
                set mode (set_color --bold red)N
            case insert
                set mode (set_color --bold green)I
            case replace_one
                set mode (set_color --bold green)R
                echo '[R]'
            case replace
                set mode (set_color --bold cyan)R
            case visual
                set mode (set_color --bold magenta)V
        end
        set mode $mode(set_color normal)
        _nim_prompt_wrapper $retc '' $mode
    end


    # Virtual Environment
    set -q VIRTUAL_ENV_DISABLE_PROMPT
    or set -g VIRTUAL_ENV_DISABLE_PROMPT true
    set -q VIRTUAL_ENV
    and _nim_prompt_wrapper $retc V (basename "$VIRTUAL_ENV")

    # git
    set -l prompt_git (fish_git_prompt '%s')
    test -n "$prompt_git"
    and _nim_prompt_wrapper $retc G $prompt_git

    # Battery status
    type -q acpi
    and test (acpi -a 2> /dev/null | string match -r off)
    and _nim_prompt_wrapper $retc B (acpi -b | cut -d' ' -f 4-)

    # New line
    echo

    # Background jobs
    set_color normal

    for job in (jobs)
        set_color $retc
        echo -n '│ '
        set_color brown
        echo $job
    end

    set_color normal
    set_color $retc
    echo -n '╰─>'
    set_color -o red
    echo -n '$ '
    set_color normal
end

functions -e fish_right_prompt; function fish_prompt --description 'Informative prompt'
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

starship init fish | source
