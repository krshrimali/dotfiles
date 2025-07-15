function fish_prompt
    set -l last_status $status
    
    # Simple prompt without icons
    set_color blue
    echo -n (prompt_pwd)
    set_color normal
    
    # Git branch without icons
    if git rev-parse --git-dir >/dev/null 2>&1
        set -l branch (git branch --show-current 2>/dev/null)
        if test -n "$branch"
            set_color yellow
            echo -n " ($branch)"
            set_color normal
        end
    end
    
    # Prompt character
    if test $last_status -eq 0
        set_color green
        echo -n " > "
    else
        set_color red
        echo -n " > "
    end
    set_color normal
end
