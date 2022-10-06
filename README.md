# dotfiles

The dotfiles I use.

```
tmux, zsh (+ oh-my-zsh), alacritty, neovim
```

## Installation

Make sure to install the following

1. [fd](https://github.com/sharkdp/fd#installation) - on debian based OS, you might have to do: `ln -s $(which fdfind) ~/.local/bin/fd`
2. [bat](https://github.com/sharkdp/bat)
3. [tmux](https://github.com/tmux/tmux)
4. `tree`, if using `apt`: `sudo apt install tree`
5. [fzf](https://github.com/junegunn/fzf)
6. [ats](https://github.com/tichopad/alacritty-theme-switch): can just do `npm install -g alacritty-theme-switch`

**Distribution**: Endeavour OS - PC and Pop OS (22.04) - Laptop

Configurations:

1. `tmux`:
  * Plugins: `tmux-sensible, tmux-tilish, tmux-navigate, tmux-fzf`
  * Navigate and tilish allow me to navigate between vim windows and tmux panes easily using Alt+j/k/h/l keymaps.

To set background correctly for alacritty + nvim: [refer this gist]( https://gist.github.com/andersevenrud/015e61af2fd264371032763d4ed965b6?permalink_comment_id=4109663#gistcomment-4109663 ).
