if status is-interactive
    # Commands to run in interactive sessions can go here
end

set -x PKG_CONFIG_PATH /opt/intel/oneapi/mkl/latest/lib/pkgconfig $PKG_CONFIG_PATH
alias dev="source /codemill/shrimali/kush-std/bin/activate.fish"

# Bind Ctrl + L to accept the currently highlighted suggestion
bind -M insert \cf accept-autosuggestion
fish_vi_key_bindings

function __fzf_history_search
    history | fzf --height 40% --reverse --no-sort --tac | read -l cmd
    if test -n "$cmd"
        commandline --replace -- "$cmd"
    end
end

function fish_user_key_bindings
    bind \cr __fzf_history_search
end

# fzf_configure_bindings
fzf_configure_bindings --directory=\cu --git_log=\cl --variables=\ce

function git-checkout-fzf
    # List all Git branches, let fzf select one, and checkout the selected branch
    set -l branch (git branch --all | sed 's/^[* ]*//' | fzf)
    if test -n "$branch"
        git checkout $branch
    else
        echo "No branch selected."
    end
end

# Bind the function to a key sequence, e.g., Alt+U
bind \eu git-checkout-fzf
alias py "ipython --TerminalInteractiveShell.editing_mode=vi"
alias gap "git add -p"
alias lg "lazygit"
alias bs "cd /codemill/shrimali/base"
alias base "cd /codemill/shrimali/base"
alias gcm "git commit -m"
alias gcb "git checkout -b"
