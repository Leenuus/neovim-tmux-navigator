-- TODO: in fact, we can extend this command
-- to go to any tmux window in vim
-- but maybe not that useful
local M = {}

local directions = {
	h = "L",
	j = "D",
	k = "U",
	l = "R",
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
--- @param pane_nowrap boolean | nil default to false in tmux, true in neovim
--- @param cross_win boolean | nil default to false(in tmux), should navigate between windows
--- @param win_wrap boolean | nil default to true(both in tmux and neovim), navigation between windows should wrap
local function tmux_aware_navigate(direction, pane_nowrap, cross_win, win_wrap)
	local win = vim.fn.winnr()
	if pane_nowrap == nil then
		pane_nowrap = true
	end
	if cross_win == nil then
		cross_win = false
	end
	if win_wrap == nil then
		win_wrap = true
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

	-- TODO: deal with nowrap
	local cmd = "tmux " .. "select-pane -t " .. vim.env["TMUX_PANE"] .. " -" .. directions[direction]
	vim.notify(cmd, vim.log.levels.DEBUG)
	vim.fn.system(cmd)
end

M.vim_tmux_navigate_left = function()
	tmux_aware_navigate("h", true)
end
M.vim_tmux_navigate_right = function()
	tmux_aware_navigate("l", true)
end
M.vim_tmux_navigate_up = function()
	tmux_aware_navigate("k", true)
end
M.vim_tmux_navigate_down = function()
	tmux_aware_navigate("j", true)
end

return M
