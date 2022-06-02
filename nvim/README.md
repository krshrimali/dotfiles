## About

I use [AstroNvim Config](https://github.com/AstroNvim/AstroNvim/). Theme I prefer: `terafox` from [NightFox](https://github.com/EdenEast/nightfox.nvim).


## Steps

Make sure to install NeoVim, currently I'm on 0.7 version. and I built the stable release of [NeoVim](https://github.com/neovim/neovim).

```bash
git clone https://github.com/AstroNvim/AstroNvim ~/.config/nvim
nvim +PackerSync

# Create a user repository
cp ~/.config/nvim/lua/user_example ~/.config/nvim/lua/user
```

Now clone this dotfiles repo:

```
git clone git@github.com:krshrimali/dotfiles.git
# Copy the init.lua to the user folder in ~/.config/nvim/lua
cp dotfiles/neovim/init.lua ~/.config/nvim/lua/user/
nvim +PackerSync
```

That's it! Done.

Note that I didn't change any shortcuts, mostly just theming, and disabled pylsp linting that I sometimes feel is too much. :)

## TODO

Make a video and share the link here
