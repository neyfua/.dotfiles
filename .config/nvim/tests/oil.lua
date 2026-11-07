-- Run: nvim --headless '+luafile tests/oil.lua' '+qa!'
local oil = require("oil")
local root = vim.fn.tempname()
local nested = root .. string.rep("/child", 10)
vim.fn.mkdir(nested, "p")
vim.fn.writefile({ "first" }, root .. "/first.txt")
vim.fn.writefile({ "second" }, root .. "/second.txt")
vim.fn.writefile({ "third" }, root .. "/third.txt")
vim.cmd.edit(root .. "/first.txt")
local first_win = vim.api.nvim_get_current_win()
local tabs = #vim.api.nvim_list_tabpages()

local function move_cursor(name)
	assert(vim.wait(5000, function()
		for line = 1, vim.api.nvim_buf_line_count(0) do
			local entry = oil.get_entry_on_line(0, line)
			if entry and entry.name == name then
				vim.api.nvim_win_set_cursor(0, { line, 0 })
				return true
			end
		end
		return false
	end), "Missing Oil entry: " .. name)
end

local function select_entry(name, done)
	move_cursor(name)
	vim.fn.maparg("<CR>", "n", false, true).callback()
	assert(vim.wait(5000, done), "Selection did not finish: " .. name)
end

local function check()
	oil.open_float(nested, { preview = {} })
	local float = vim.api.nvim_get_current_win()
	assert(vim.wait(5000, function() return require("oil.util").get_preview_win() ~= nil end), "Initial preview missing")
	for _ = 1, 10 do
		nested = vim.fs.dirname(nested)
		select_entry("..", function()
			return oil.get_current_dir() == nested .. "/"
		end)
		assert(#vim.api.nvim_list_tabpages() == tabs, "Parent navigation created a tab")
		assert(vim.api.nvim_get_current_win() == float, "Parent navigation left the float")
		assert(vim.api.nvim_win_get_config(float).relative ~= "", "Oil became fullscreen")
		assert(require("oil.util").get_preview_win() == nil, "Parent navigation retained duplicate preview")
	end
	move_cursor("child")
	vim.api.nvim_exec_autocmds("CursorMoved", { buffer = 0 })
	assert(vim.wait(5000, function()
		local preview = require("oil.util").get_preview_win()
		return preview and vim.w[preview].oil_entry_id == oil.get_cursor_entry().id
	end), "Cursor movement did not load preview")
	select_entry("child", function() return oil.get_current_dir() == root .. "/child/" end)
	assert(vim.api.nvim_get_current_win() == float, "Child navigation left the float")
	assert(#vim.api.nvim_list_tabpages() == tabs, "Child navigation created a tab")
	select_entry("..", function() return oil.get_current_dir() == root .. "/" end)
	select_entry("first.txt", function() return vim.api.nvim_get_current_win() == first_win end)
	assert(#vim.api.nvim_list_tabpages() == tabs, "Existing file created a tab")
	oil.open_float(root)
	select_entry("second.txt", function()
		return vim.api.nvim_buf_get_name(0) == root .. "/second.txt"
	end)
	assert(#vim.api.nvim_list_tabpages() == tabs + 1, "New file did not create one tab")
	oil.open_float(root)
	select_entry("first.txt", function() return vim.api.nvim_get_current_win() == first_win end)
	assert(#vim.api.nvim_list_tabpages() == tabs + 1, "Existing file duplicated across tabs")
	vim.cmd.tabclose()
	vim.cmd.edit(root)
	local fullscreen_win = vim.api.nvim_get_current_win()
	select_entry("third.txt", function() return vim.api.nvim_buf_get_name(0) == root .. "/third.txt" end)
	assert(vim.api.nvim_get_current_win() == fullscreen_win, "Fullscreen Oil did not reuse its window")
	assert(#vim.api.nvim_list_tabpages() == tabs, "Fullscreen Oil created a tab for a new file")
	vim.cmd.tabnew()
	vim.cmd.edit(root)
	select_entry("third.txt", function() return vim.api.nvim_get_current_win() == fullscreen_win end)
	assert(#vim.api.nvim_list_tabpages() == tabs, "Fullscreen Oil tab remained after selecting an existing file")

end

local ok, err = pcall(check)
vim.fn.delete(root, "rf")
assert(ok, err)
print("PASS: Oil directory navigation stays floating; file tabs stay unique")
