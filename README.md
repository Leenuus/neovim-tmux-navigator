# Neovim-Tmux-Navigator

A __REWRITE__ [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) in pure __lua__, just because I hate __VimScript__ so much, also so more features to fit into my workflow in tmux.

## Features

- Pure lua, minimal simple file module, no more than 140 lines.
- If you disable `wrapping` in panes, then you can enable `cross_win`, which allows you to go to previous window with the same keybinding you have to navigate around panes. That is, when you are at leftmost neovim window in the leftmost tmux pane, pressing `<C-h>`, the default keybinding to go left, you __go to previous window.__

## Not-Implemented

- `zoom` support in tmux, I never use this tmux features before; It doesn't make sense to me.
- `previous` commands support. In tmux and neovim, one can go to previous visited pane or window. In tmux, it is `last-window`; in neovim, it is `:wincmd p`. But I never use these two commands, so I just remove that.

## Install

- Use your favorite plugin manager.
- Or simply copy the file somewhere in your neovim config as a module as it is quite small.

## Setup

___Make sure you setup both your neovim and tmux.___

### Neovim

This snippets enable __cross_win__ and __no_wrap__.

```lua
require("neovim-tmux-navigator").setup({
  -- create that classic keymap for lazy you?
  use_default_keymap = true,
  -- default to false, as it is default behavior of tmux and neovim
  pane_nowrap = true,
  -- NOTE:
  -- default to false, as it is default behavior of tmux and neovim
  -- only works when pane_nowrap is set to true
  cross_win = true,
})
```

### Tmux

#### Wrapping(Default)

```tmux.conf
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

#### Only Nowrap

```tmux.conf
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

#### Nowrap and Cross_win

```tmux.conf
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

## Usage

- enable and use the default keymap, nothing to worry about.

- use user commands `neovim-tmux-navigator` creates.

```vim
:NTmuxDown<cr>
:NTmuxLeft<cr>
:NTmuxRight<cr>
:NTmuxUp<cr>
```

- use lua functions `neovim-tmux-navigator` exports.

```lua
local nt = require('neovim-tmux-navigator')

-- you get:
-- nt.nvim_tmux_navigate_left
-- nt.nvim_tmux_navigate_right 
-- nt.nvim_tmux_navigate_up 
-- nt.nvim_tmux_navigate_down

vim.keymap.set('n', 'keybinding you like', function()
  -- NOTE: you can pass a option with two fields below or nil
  -- if nil, use opts passed when calling setup(), or the defalt
  nt.nvim_tmux_navigate_left({
    pane_nowrap = true,
    cross_win = false,
  })
end)

```


## TODO

- maybe I will implement those in [Not-implemented](#Not-Implemented)
- Currently, __user commands don't yet receive args__ like their function counterparts do. Hope one day I will implement it after reading neovim manuals. I am lazy though.