# dotfiles

The dotfiles I use.

```
tmux, zsh (+ oh-my-zsh), alacritty, neovim, fzf, lazygit
```

## Installation

Make sure to install the following

1. [fd](https://github.com/sharkdp/fd#installation) - on debian based OS, you might have to do: `ln -s $(which fdfind) ~/.local/bin/fd`
2. [bat](https://github.com/sharkdp/bat)
3. [tmux](https://github.com/tmux/tmux)
4. `tree`, if using `apt`: `sudo apt install tree`
5. [fzf](https://github.com/junegunn/fzf)
6. [ats](https://github.com/tichopad/alacritty-theme-switch): can just do `npm install -g alacritty-theme-switch`
7. [lazygit](https://github.com/jesseduffield/lazygit) -> you may need [homebrew](https://brew.sh/) for this if you are on Linux.
8. [autojump](https://github.com/wting/autojump) -- optional

## Notes

**Distribution**: Endeavour OS - PC and Pop OS (22.04) - Laptop
**Current Code Editor**: neovim
**Current color-scheme**: catppuccin (mocha flavour)

1. `tmux`:
  * Plugins: `tmux-sensible, tmux-tilish, tmux-navigate, tmux-fzf`
  * Navigate and tilish allow me to navigate between vim windows and tmux panes easily using Alt+j/k/h/l keymaps.

To set background correctly for alacritty + nvim: [refer this gist]( https://gist.github.com/andersevenrud/015e61af2fd264371032763d4ed965b6?permalink_comment_id=4109663#gistcomment-4109663 ).

2. `alacritty-theme-switch`:
	* Using it to switch between available themes (`~/.config/alacritty/themes`).
  * Shortcut: `ats`, and that's it.

3. `fzf`:
	* It plays a major role. I mostly use, `fii` to search for a word (interactively) and open the file in neovim, alt+C, ctrl+T keymaps. Do `alias` to search for the available aliases.

4. `lg` (lazygit):
	* Very useful, I use it to stage/commit/push/pull changes to my GitHub repo.

5. neovim:
	* neovim has played huge role in my life, professionally and personally. :) I would definitely recommend everyone using it.
  * My config: https://github.com/krshrimali/nvim

6. `bat`:
	* Just better alternative to `cat`. IMO
