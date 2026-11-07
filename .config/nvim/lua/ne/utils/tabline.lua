local M = {}

-- Constants
local MAX_NAME_LENGTH = 20
local TRUNCATE_TO = 17

---Setup highlight groups for the tabline
function M.setup()
	local ok, colors = pcall(require, "rose-pine.palette")
	if not ok then
		vim.notify("tabline: rose-pine.palette not found", vim.log.levels.WARN)
		return
	end

	local function hex_to_int(hex)
		return tonumber(hex:gsub("#", ""), 16)
	end

	-- Active tab: gold background, base text
	vim.api.nvim_set_hl(0, "TabLineActive", {
		fg = hex_to_int(colors.base),
		bg = hex_to_int(colors.gold),
		bold = true,
	})

	-- Inactive tab: surface background, subtle text
	vim.api.nvim_set_hl(0, "TabLineInactive", {
		fg = hex_to_int(colors.subtle),
		bg = hex_to_int(colors.surface),
	})

	-- Fill area (transparent)
	vim.api.nvim_set_hl(0, "TabLineFill", {
		bg = "NONE",
	})
end

---Get file icon using MiniIcons with fallback
---@param filename string
---@return string icon, string hl
local function get_icon(filename)
	if MiniIcons and MiniIcons.get then
		return MiniIcons.get("file", filename)
	end
	return "", "Normal"
end

---Get display name for a buffer
---@param bufnr number
---@return string name, string icon
local function get_buf_info(bufnr)
	local bufname = vim.api.nvim_buf_get_name(bufnr)
	local buftype = vim.bo[bufnr].buftype
	local filetype = vim.bo[bufnr].filetype

	-- Handle special buffer types
	if buftype == "terminal" then
		return "[Terminal]", ""
	end

	if filetype == "oil" then
		local dir = bufname:gsub("^oil://", "")
		dir = vim.fn.fnamemodify(dir, ":~")
		if #dir > MAX_NAME_LENGTH then
			dir = "…" .. dir:sub(-TRUNCATE_TO)
		end
		return dir, ""
	end

	if bufname == "" then
		return "[No Name]", ""
	end

	local filename = vim.fn.fnamemodify(bufname, ":t")
	local icon = get_icon(filename)

	-- Truncate long filenames
	if #filename > MAX_NAME_LENGTH then
		filename = filename:sub(1, TRUNCATE_TO) .. "…"
	end

	return filename, icon
end

---Render a single tab
---@param tabnr number
---@param is_active boolean
---@return string
local function render_tab(tabnr, is_active)
	local buflist = vim.fn.tabpagebuflist(tabnr)
	local winnr = vim.fn.tabpagewinnr(tabnr)
	local bufnr = buflist[winnr]

	if not bufnr then
		return ""
	end

	local filename, icon = get_buf_info(bufnr)
	local modified = vim.bo[bufnr].modified

	-- Build the tab content
	local title = "   " .. icon .. " " .. filename
	if modified then
		title = "   [+] " .. icon .. " " .. filename
	end
	title = title .. "   "

	-- Select highlight groups based on active state
	local tab_hl = is_active and "%#TabLineActive#" or "%#TabLineInactive#"
	-- Build clickable rectangular tab
	return string.format("%%%dT%s%s%%T", tabnr, tab_hl, title)
end

---Render the complete tabline
---@return string
function M.render()
	local ok, result = pcall(function()
		local parts = {}
		local current_tab = vim.fn.tabpagenr()
		local tab_count = vim.fn.tabpagenr("$")

		for tabnr = 1, tab_count do
			local is_active = tabnr == current_tab
			parts[#parts + 1] = render_tab(tabnr, is_active)
		end

		return table.concat(parts) .. "%#TabLineFill#"
	end)

	if not ok then
		return "%#TabLineFill#"
	end
	return result
end

return M
