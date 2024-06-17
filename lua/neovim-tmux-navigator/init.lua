local M = {}

-- NOTE: set default
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

--- go around between vim windows, and tell caller whether we move successfully
--- @param direction string
local function vim_navigate(direction)
	local win = vim.fn.winnr()
	if vim_to_tmux_directions[direction] ~= nil then
		vim.cmd("wincmd " .. direction)
		return win == vim.fn.winnr()
	end
end

--- tell whether current tmux window is zoomed in
local function tmux_is_zoom()
	return vim.fn.system("tmux display -pF '#{window_zoomed_flag}'") == "1\n"
end

--- tmux or not tmux? It is a problem.
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

local function toggler(var_name, cmd_prefix, buffer)
	local scope = buffer and "b" or "g"
	local funcs = {
		toggle = function()
			vim[scope][var_name] = not vim[scope][var_name]
		end,
		disable = function()
			vim[scope][var_name] = false
		end,
		enable = function()
			vim[scope][var_name] = true
		end,
	}
	vim.api.nvim_create_user_command(cmd_prefix .. "Disable", funcs.disable, {})
	vim.api.nvim_create_user_command(cmd_prefix .. "Enable", funcs.enable, {})
	vim.api.nvim_create_user_command(cmd_prefix .. "Toggle", funcs.toggle, {})
	return funcs
end

---setup neovim-tmux-navigator
---@param opts table | nil
M.setup = function(opts)
	opts = opts or default_opts

	vim.api.nvim_create_user_command("NTmuxLeft", M.nvim_tmux_navigate_left, {})
	vim.api.nvim_create_user_command("NTmuxRight", M.nvim_tmux_navigate_right, {})
	vim.api.nvim_create_user_command("NTmuxUp", M.nvim_tmux_navigate_up, {})
	vim.api.nvim_create_user_command("NTmuxDown", M.nvim_tmux_navigate_down, {})

	local plugin_funcs = toggler("tmux_navigater_enabled", "NTmux")
	M.enable = plugin_funcs.enable
	M.toggle = plugin_funcs.toggle
	M.disable = plugin_funcs.disable

	local pane_funcs = toggler("tmux_navigator_pane_nowrap", "NTPaneNoWrap")
	M.nowrap_enable = pane_funcs.enable
	M.nowrap_toggle = pane_funcs.toggle
	M.nowrap_disable = pane_funcs.disable

	local cross_win_funcs = toggler("tmux_navigater_cross_win", "NTCrossWin")
	M.cross_win_enable = cross_win_funcs.enable
	M.cross_win_toggle = cross_win_funcs.toggle
	M.cross_win_disable = cross_win_funcs.disable

	if opts.use_default_keymap then
		vim.keymap.set("n", "<c-h>", M.nvim_tmux_navigate_left)
		vim.keymap.set("n", "<c-l>", M.nvim_tmux_navigate_right)
		vim.keymap.set("n", "<c-j>", M.nvim_tmux_navigate_down)
		vim.keymap.set("n", "<c-k>", M.nvim_tmux_navigate_up)
	end
end

return M
