local n = require("navigate")

vim.api.nvim_create_user_command("Goleft", n.vim_tmux_navigate_left, {})
vim.api.nvim_create_user_command("Goright", n.vim_tmux_navigate_right, {})
vim.api.nvim_create_user_command("Goup", n.vim_tmux_navigate_up, {})
vim.api.nvim_create_user_command("Godown", n.vim_tmux_navigate_down, {})

vim.keymap.set("n", "<c-h>", "<cmd>Goleft<cr>")
vim.keymap.set("n", "<c-l>", "<cmd>Goright<cr>")
vim.keymap.set("n", "<c-j>", "<cmd>Godown<cr>")
vim.keymap.set("n", "<c-k>", "<cmd>Goup<cr>")
vim.keymap.set("n", "<space>q", "<cmd>x<cr>")
