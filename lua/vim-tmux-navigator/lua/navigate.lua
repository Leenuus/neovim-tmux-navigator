-- TODO: in fact, we can extend this command
-- to go to any tmux window in vim
-- but maybe not that useful
local M = {}

local default_opts = {
	pane_nowrap = true,
	-- TODO: implement cross_win
	cross_win = false,
	win_wrap = true,
}

local directions = {
	h = "L",
	j = "D",
	k = "U",
	l = "R",
}

local locations = {
	h = "#{pane_at_left}",
	l = "#{pane_at_rigft}",
	j = "#{pane_at_bottom}",
	k = "#{pane_at_top}",
}

--- function wrapping navigation in vim
--- @param direction string
local function vim_navigate(direction)
	if directions[direction] ~= nil then
		vim.cmd("wincmd " .. direction)
		return true
	else
		-- do nothing if direction is not valid
		return false
	end
end

--- function to send tmux commands
--- @param direction string
--- @param opts table | nil
local function tmux_aware_navigate(direction, opts)
	-- TODO: better default solution
	local win = vim.fn.winnr()
	if opts == nil then
		opts = default_opts
	end
	if opts.pane_nowrap == nil then
		opts.pane_nowrap = true
	end
	if opts.cross_win == nil then
		opts.cross_win = false
	end
	if opts.win_wrap == nil then
		opts.win_wrap = true
	end

	local res = vim_navigate(direction)
	-- NOTE: return early if direction is not valid
	if not res then
		return
	end

	-- NOTE: after calling navigate, we are still in the same window
	-- meaning that we should turn to tmux now
	local should_go_tmux = vim.fn.winnr() == win

	if not should_go_tmux then
		return
	end

	-- NOTE: it makes no sense to call tmux command if
	-- we are not in tmux
	if vim.env["TMUX"] == nil or vim.env["TMUX_PANE"] == nil then
		return
	end

	-- vim.notify("here", vim.log.levels.DEBUG)
	-- TODO: deal with nowrap
	--  { if-shell -F '#{pane_at_left}'   { previous-window } { select-pane -L } }
	--  { if-shell -F '#{pane_at_right}'  { next-window } { select-pane -R } }
	--  { if-shell -F '#{pane_at_bottom}' {} { select-pane -D } }
	--  { if-shell -F '#{pane_at_top}'    {} { select-pane -U } }
	-- bind-key -T copy-mode-vi 'C-h' if-shell -F '#{pane_at_left}'   {} { select-pane -L }
	-- bind-key -T copy-mode-vi 'C-j' if-shell -F '#{pane_at_bottom}' {} { select-pane -D }
	-- bind-key -T copy-mode-vi 'C-k' if-shell -F '#{pane_at_top}'    {} { select-pane -U }
	-- bind-key -T copy-mode-vi 'C-l' if-shell -F '#{pane_at_right}'  {} { select-pane -R }

	local cmd_list = {
		"tmux",
	}

	local s = {
		"select-pane",
		"-t",
		vim.env["TMUX_PANE"],
		"-" .. directions[direction],
	}

	if opts.pane_nowrap then
		vim.list_extend(cmd_list, {
			"if",
			"-F",
			"'" .. locations[direction] .. "'",
			'""',
			'"' .. vim.fn.join(s, " ") .. '"',
		})
	else
		vim.list_extend(cmd_list, s)
	end

	vim.notify(vim.inspect(cmd_list), vim.log.levels.DEBUG)
	local cmd = vim.fn.join(cmd_list, " ")
	vim.fn.system(cmd)
	vim.notify(cmd)
end

M.vim_tmux_navigate_left = function()
	tmux_aware_navigate("h")
end
M.vim_tmux_navigate_right = function()
	tmux_aware_navigate("l")
end
M.vim_tmux_navigate_up = function()
	tmux_aware_navigate("k")
end
M.vim_tmux_navigate_down = function()
	tmux_aware_navigate("j")
end

return M
