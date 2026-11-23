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

---Plain title for a tab (no highlight markup)
---@param tabnr number
---@return string?
local function tab_title(tabnr)
	local buflist = vim.fn.tabpagebuflist(tabnr)
	local winnr = vim.fn.tabpagewinnr(tabnr)
	local bufnr = buflist[winnr]

	if not bufnr then
		return nil
	end

	local filename, icon = get_buf_info(bufnr)
	local modified = vim.bo[bufnr].modified

	if modified then
		return "   [+] " .. icon .. " " .. filename .. "   "
	end
	return "   " .. icon .. " " .. filename .. "   "
end

---Pick the slice of tabs to show so the active tab is always visible
---@param widths number[] display width per tab
---@param active number
---@param avail number
---@return number first, number last
local function visible_range(widths, active, avail)
	local total = 0
	for _, w in ipairs(widths) do
		total = total + w
	end
	if total <= avail then
		return 1, #widths
	end

	-- Leave room for the "<" / ">" overflow markers
	local budget = avail - 2 - widths[active]
	local first, last = active, active

	for i = active - 1, 1, -1 do
		if widths[i] > budget then
			break
		end
		budget = budget - widths[i]
		first = i
	end
	for i = active + 1, #widths do
		if widths[i] > budget then
			break
		end
		budget = budget - widths[i]
		last = i
	end

	return first, last
end

---Render the complete tabline
---@return string
function M.render()
	local ok, result = pcall(function()
		local current_tab = vim.fn.tabpagenr()
		local tab_count = vim.fn.tabpagenr("$")

		local titles, widths = {}, {}
		for tabnr = 1, tab_count do
			titles[tabnr] = tab_title(tabnr) or ""
			widths[tabnr] = vim.fn.strdisplaywidth(titles[tabnr])
		end

		local first, last = visible_range(widths, current_tab, vim.o.columns)

		local parts = {}
		if first > 1 then
			parts[#parts + 1] = "%#TabLineInactive#<"
		end
		for tabnr = first, last do
			local tab_hl = tabnr == current_tab and "%#TabLineActive#" or "%#TabLineInactive#"
			parts[#parts + 1] = string.format("%%%dT%s%s%%T", tabnr, tab_hl, titles[tabnr])
		end
		if last < tab_count then
			parts[#parts + 1] = "%#TabLineInactive#>"
		end

		return table.concat(parts) .. "%#TabLineFill#"
	end)

	if not ok then
		return "%#TabLineFill#"
	end
	return result
end

return M
