-- TODO: better docs
local M = {}

vim.g.tmux_navigater_enabled = true
vim.g.tmux_navigator_pane_nowrap = false
vim.g.tmux_navigater_cross_win = false

local vim_to_tmux_directions = {
	h = "L",
	j = "D",
	k = "U",
	l = "R",
}

local locations = {
	h = "#{pane_at_left}",
	l = "#{pane_at_right}",
	j = "#{pane_at_bottom}",
	k = "#{pane_at_top}",
}

--- function wrapping navigation in vim
--- @param direction string
local function vim_navigate(direction)
	local win = vim.fn.winnr()
	if vim_to_tmux_directions[direction] ~= nil then
		vim.cmd("wincmd " .. direction)
		return win == vim.fn.winnr()
	end
end

local function tmux_is_zoom()
	return vim.fn.system("tmux display -pF '#{window_zoomed_flag}'") == "1\n"
end

--- function to send tmux command
--- @param direction string
--- @param navi_opts table | nil
local function tmux_aware_navigate(direction, navi_opts)
	navi_opts = navi_opts
	    or {
		    pane_nowrap = vim.g.tmux_navigator_pane_nowrap,
		    cross_win = vim.g.tmux_navigater_cross_win,
	    }

	-- NOTE: after calling navigate, we are still in the same window
	-- meaning that we should turn to tmux now
	local should_go_tmux = vim_navigate(direction)
	should_go_tmux = should_go_tmux and vim.g.tmux_navigater_enabled and not tmux_is_zoom()

	if not should_go_tmux then
		return
	end

	-- NOTE: it makes no sense to call tmux command if
	-- we are not in tmux
	if vim.env["TMUX"] == nil or vim.env["TMUX_PANE"] == nil then
		return
	end

	local cmd_list = {
		"tmux",
	}

	local s = {
		"select-pane",
		"-t",
		vim.env["TMUX_PANE"],
		"-" .. vim_to_tmux_directions[direction],
	}

	if navi_opts.pane_nowrap then
		local c = '""'
		if navi_opts.cross_win then
			if direction == "h" then
				c = '"previous-window"'
			elseif direction == "l" then
				c = '"next-window"'
			end
		end
		vim.list_extend(cmd_list, {
			"if",
			"-F",
			"'" .. locations[direction] .. "'",
			c,
		})

		table.insert(cmd_list, '"' .. vim.fn.join(s, " ") .. '"')
	else
		vim.list_extend(cmd_list, s)
	end

	local cmd = vim.fn.join(cmd_list, " ")
	vim.fn.system(cmd)
end

M.nvim_tmux_navigate_left = function(opts)
	tmux_aware_navigate("h", opts)
end
M.nvim_tmux_navigate_right = function(opts)
	tmux_aware_navigate("l", opts)
end
M.nvim_tmux_navigate_up = function(opts)
	tmux_aware_navigate("k", opts)
end
M.nvim_tmux_navigate_down = function(opts)
	tmux_aware_navigate("j", opts)
end

local default_opts = {
	use_default_keymap = true,
}

---setup neovim-tmux-navigator
---@param opts table | nil
M.setup = function(opts)
	opts = opts or default_opts

	-- TODO: navigate command can receive args
	vim.api.nvim_create_user_command("NTmuxLeft", M.nvim_tmux_navigate_left, {})
	vim.api.nvim_create_user_command("NTmuxRight", M.nvim_tmux_navigate_right, {})
	vim.api.nvim_create_user_command("NTmuxUp", M.nvim_tmux_navigate_up, {})
	vim.api.nvim_create_user_command("NTmuxDown", M.nvim_tmux_navigate_down, {})
	vim.api.nvim_create_user_command("NTmuxToggle", function()
		vim.g.tmux_navigater_enabled = not vim.g.tmux_navigater_enabled
	end, {})
	vim.api.nvim_create_user_command("NTmuxDisable", function()
		vim.g.tmux_navigater_enabled = false
	end, {})
	vim.api.nvim_create_user_command("NTmuxEnable", function()
		vim.g.tmux_navigater_enabled = true
	end, {})

	if opts.use_default_keymap then
		vim.keymap.set("n", "<c-h>", M.nvim_tmux_navigate_left)
		vim.keymap.set("n", "<c-l>", M.nvim_tmux_navigate_right)
		vim.keymap.set("n", "<c-j>", M.nvim_tmux_navigate_down)
		vim.keymap.set("n", "<c-k>", M.nvim_tmux_navigate_up)
	end
end

return M
