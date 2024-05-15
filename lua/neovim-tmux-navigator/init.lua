-- TODO: better docs
local M = {}

local default_nav_opts = {
	pane_nowrap = false,
	-- NOTE: note that only when pane_nowrap is set to true, cross_win takes effects
	cross_win = false,
}

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

--- function to send tmux command
--- @param direction string
--- @param navi_opts table | nil
local function tmux_aware_navigate(direction, navi_opts)
	navi_opts = navi_opts or default_nav_opts
	if navi_opts.pane_nowrap == nil then
		navi_opts.pane_nowrap = false
	end
	if navi_opts.cross_win == nil then
		navi_opts.cross_win = false
	end

	-- NOTE: after calling navigate, we are still in the same window
	-- meaning that we should turn to tmux now
	local should_go_tmux = vim_navigate(direction)

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
	cross_win = false,
	pane_nowrap = false,
}

---setup neovim-tmux-navigator
---@param opts table | nil
M.setup = function(opts)
	opts = opts or default_opts
	if opts.pane_nowrap ~= nil and type(opts.pane_nowrap) == "boolean" then
		default_nav_opts.pane_nowrap = opts.pane_nowrap
	end
	if opts.cross_win ~= nil and type(opts.cross_win) == "boolean" then
		default_nav_opts.cross_win = opts.cross_win
	end

	-- TODO: navigate command can receive args
	vim.api.nvim_create_user_command("NTmuxLeft", M.nvim_tmux_navigate_left, {})
	vim.api.nvim_create_user_command("NTmuxRight", M.nvim_tmux_navigate_right, {})
	vim.api.nvim_create_user_command("NTmuxUp", M.nvim_tmux_navigate_up, {})
	vim.api.nvim_create_user_command("NTmuxDown", M.nvim_tmux_navigate_down, {})

	if opts.use_default_keymap then
		vim.keymap.set("n", "<c-h>", M.nvim_tmux_navigate_left)
		vim.keymap.set("n", "<c-l>", M.nvim_tmux_navigate_right)
		vim.keymap.set("n", "<c-j>", M.nvim_tmux_navigate_down)
		vim.keymap.set("n", "<c-k>", M.nvim_tmux_navigate_up)
	end
end

return M
