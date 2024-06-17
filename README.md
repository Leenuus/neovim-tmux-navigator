# Neovim-Tmux-Navigator

A __REWRITE__ [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) in pure __lua__, just because I hate __VimScript__ so much, also so more features to fit into my workflow in tmux.

In short, it supercharges your `<c-l>`, `<c-h>`, `<c-j>`, `<c-k>`, you can navigate around vim windows and tmux panes, __even tmux windows__ using this __unifying keybinding.__

## Features

- __Pure lua__, minimal simple file module, no more than 140 lines.

- Navigate vim/tmux __window__/pane like one, explain below:

    Enable `pane_nowrap` and `cross_win`, allows you to __go to previous/next window with the same keybinding to navigate to previous/next pane__ in neovim or tmux.

- Control module's behavior with __vim global variable__, just like what you do with most of plugins from [mini.nvim](https://github.com/echasnovski/mini.nvim).

    It means you can __change neovim-tmux-navigator's behavior anytime when neovim is running__.

- Both __lua functions__ and __vim commands__ API are provided. Choose the best one for your use case.

- An well-written README to tell you how things work even though you are not a _`tmux` nerd_ like me(btw, `man tmux` is too long but life is short).

## Not-Implemented

- `previous` commands support. In tmux and neovim, one can go to previous visited pane or window. In tmux, it is `last-window`; in neovim, it is `:wincmd p`. But I never use these two commands, so I just remove that.

## RoadMap

In fact, this project is done. No more fancy things needed.

I don't think `previous` is a reasonable command in tmux at least. For vim, it may be useful when you get more than two windows.

BTW, I used to consider to implement a neovim plugin to send text in buffers to a interpreter like `python`, `luajit` or `bash`. Now this idea is less attractive to me, because of [the idea provided by _romainl_'s `Redir` vim script](https://gist.github.com/romainl/eae0a260ab9c135390c30cd370c20cd7). I [implement that one in lua too.](https://gist.github.com/Leenuus/db3607091a0cf2f7d8450adaff0132d3)


### TODO

The single file version is not done yet.

I am too lazy to update.

## Installation

- Use your favorite plugin manager. By default, this plugin create keymap for you. Default keymaps are related to following tmux configuration.

```lua
-- lazy.nvim
{
    'Leenuus/neovim-tmux-navigator',
}

```

- Or simply copy the single file version somewhere in your neovim config as a module as it is quite small.

## Setup

___Make sure you setup both your neovim and tmux.___

### Neovim

```lua
require("neovim-tmux-navigator").setup({
    use_default_keymap = true
})


```

### Tmux Config

This plugin works with `tmux`, so you should have some tmux configurations to make things work.

#### Wrapping(Default)

Wrapping is the __default behavior of tmux__, meaning that, when you are in the leftmost pane of a window, telling tmux to go to the left pane, it silently __sends you back to the rightmost pane.__

```tmux
is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
    | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?|fzf)(diff)?$'"

bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U'
bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'

bind-key -T copy-mode-vi 'C-h' select-pane -L
bind-key -T copy-mode-vi 'C-j' select-pane -D
bind-key -T copy-mode-vi 'C-k' select-pane -U
bind-key -T copy-mode-vi 'C-l' select-pane -R

bind C-l send-keys 'C-l'
```

To work with this tmux configuration, you should do this in lua

```lua
-- this is the default behavior, so in fact
-- you don't have to set it up
-- I am here to point out you can set these options
-- __anytime__ when neovim is running to change its behavior
vim.g.tmux_navigator_pane_nowrap = false
vim.g.tmux_navigater_cross_win = false
```

#### Only Nowrap

So you want to control everything, no more implicit wraps around, and you can do more!

We use `#{pane_at_left}` and so, called `FORMATS` in tmux, to do simple condition checking. Quite straightforward in fact.

```tmux
is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
    | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?|fzf)(diff)?$'"

bind-key -n 'C-j' if-shell "$is_vim" { send-keys C-j } { if-shell -F '#{pane_at_bottom}' {} { select-pane -D } }
bind-key -n 'C-k' if-shell "$is_vim" { send-keys C-k } { if-shell -F '#{pane_at_top}'    {} { select-pane -U } }
bind-key -T copy-mode-vi 'C-j' if-shell -F '#{pane_at_bottom}' {} { select-pane -D }
bind-key -T copy-mode-vi 'C-k' if-shell -F '#{pane_at_top}'    {} { select-pane -U }

bind-key -n 'C-h' if-shell "$is_vim" { send-keys C-h } { if-shell -F '#{pane_at_left}'   {} { select-pane -L } }
bind-key -n 'C-l' if-shell "$is_vim" { send-keys C-l } { if-shell -F '#{pane_at_right}'  {} { select-pane -R } }
bind-key -T copy-mode-vi 'C-h' if-shell -F '#{pane_at_left}'   {} { select-pane -L }
bind-key -T copy-mode-vi 'C-l' if-shell -F '#{pane_at_right}'  {} { select-pane -R }

# bonus, leader <C-L> to clear your shell's screen
bind C-l send-keys 'C-l'
```

The needed lua code:

```lua
vim.g.tmux_navigator_pane_nowrap = true
vim.g.tmux_navigater_cross_win = false
```

#### Nowrap and Cross_win

Full power I've promised comes with this settings. Instead of empty bracket meaning do nothing in previous tmux configuration, we do `next-window` when `pane_at_right` is true, and the opposite when we are at the leftmost pane.

Now you can navigate all of these crazy glossary/abstractions with the same keybindings. How amazing it is.

```tmux
is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
    | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?|fzf)(diff)?$'"

bind-key -n 'C-j' if-shell "$is_vim" { send-keys C-j } { if-shell -F '#{pane_at_bottom}' {} { select-pane -D } }
bind-key -n 'C-k' if-shell "$is_vim" { send-keys C-k } { if-shell -F '#{pane_at_top}'    {} { select-pane -U } }
bind-key -T copy-mode-vi 'C-j' if-shell -F '#{pane_at_bottom}' {} { select-pane -D }
bind-key -T copy-mode-vi 'C-k' if-shell -F '#{pane_at_top}'    {} { select-pane -U }

bind-key -n 'C-h' if-shell "$is_vim" { send-keys C-h } { if-shell -F '#{pane_at_left}'   { previous-window } { select-pane -L } }
bind-key -n 'C-l' if-shell "$is_vim" { send-keys C-l } { if-shell -F '#{pane_at_right}'  { next-window } { select-pane -R } }
bind-key -T copy-mode-vi 'C-h' if-shell -F '#{pane_at_left}'   { previous-window } { select-pane -L }
bind-key -T copy-mode-vi 'C-l' if-shell -F '#{pane_at_right}'  { next-window } { select-pane -R }

# bonus, leader <C-L> to clear your shell's screen
bind C-l send-keys 'C-l'
```

The needed lua code:

```lua
vim.g.tmux_navigator_pane_nowrap = true
vim.g.tmux_navigater_cross_win = true
```

#### More Bonus

For dear `nnn` user.

If you are using applications like `nnn`, a terminal file manager, which makes use of tmux split pane for file previewing.

It doesn't make sense most of times to navigate into that split pane.

Here is a workaround:

```tmux
bind-key -n 'C-h' if-shell "$is_vim" { send-keys C-h } {
	if-shell -F '#{pane_at_left}'   { previous-window }  { if-shell '[[ #W =~ nnn ]]' { previous-window } { select-pane -L }}}
bind-key -n 'C-l' if-shell "$is_vim" { send-keys C-l } {
	if-shell -F '#{pane_at_right}'   { next-window }  { if-shell '[[ #W =~ nnn ]]' { next-window } { select-pane -R }}}

bind-key -T copy-mode-vi 'C-h' if-shell -F '#{pane_at_left}'   { previous-window }  { if-shell '[[ #W =~ nnn ]]' { previous-window } { select-pane -L }}
bind-key -T copy-mode-vi 'C-l' if-shell -F '#{pane_at_right}'   { next-window }  { if-shell '[[ #W =~ nnn ]]' { next-window } { select-pane -R }}
```

We check whether `#W`, expanding to current window's name in tmux, matches a POSIX compliant regex pattern, for me, `nnn`. By default, tmux automatically renames window to application running inside, if it doesn't work, just write a wrapper script to rename that application to what it should be like so:

```bash
if [ "$TMUX" ];then
  tmux rename-window nnn
end
exec nnn "$@"
```

If we are in such window, `C-H` and `C-L` won't takes us to adjacent pane. Instead, it goes to previous/next window, which makes more sense.

Note that we don't need a neovim counterpart here, when we switching window, tmux put us back to last visited pane in that window. As normally, we never visit the split pane created by `preview-tui`, so we won't get into it back from neovim.

You can use this technique to jump over all panes you are not interested in!

## API

Just enable and use the default keymap, nothing to worry about most of time.

### USER COMMAND

neovim-tmux-navigator creates these user command by default.

(__I won't tell you it is a good idea to search for them with `require('telescope.builtins').commands`.__)

```vim

:NTmuxDown<CR>
:NTmuxLeft<CR>
:NTmuxRight<CR>
:NTmuxUp<CR>

:NTmuxEnable<CR>
:NTmuxDisable<CR>
:NTmuxToggle<CR>

:NTPaneNoWrapEnable<CR>
:NTPaneNoWrapDisable<CR>
:NTPaneNoWrapToggle<CR>

:NTCrossWinEnable<CR>
:NTCrossWinDisable<CR>
:NTCrossWinToggle<CR>
```

### LUA FUNCTIONS

```lua
local nt = require('neovim-tmux-navigator')

-- why not `call print(vim.inspect(nt))``
-- to see what you get?

-- nt.nvim_tmux_navigate_left
-- nt.nvim_tmux_navigate_right
-- nt.nvim_tmux_navigate_up
-- nt.nvim_tmux_navigate_down
-- nt.enable
-- nt.disable
-- nt.toggle

vim.keymap.set('n', 'whatever you like', function()
  -- NOTE: you can pass a option with two fields below or nil
  nt.nvim_tmux_navigate_left({
    pane_nowrap = true,
    cross_win = false,
  })
end)

```
