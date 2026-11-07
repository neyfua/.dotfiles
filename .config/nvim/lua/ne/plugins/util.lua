-- File explorer
require("oil").setup({
	constrain_cursor = "name",
	columns = {
		"icon",
		{ "permissions", highlight = "Type" },
		{ "size", highlight = "String" },
		{ "mtime", highlight = "Keyword" },
	},
	keymaps = {
		["<CR>"] = function()
			local oil = require("oil")
			local entry = oil.get_cursor_entry()
			if entry and require("oil.util").is_directory(entry) then
				if entry.name == ".." and vim.w.is_oil_win then
					local oil_win = vim.api.nvim_get_current_win()
					-- Close before select: Oil otherwise starts an async preview of the parent.
					local preview = require("oil.util").get_preview_win()
					if preview then
						vim.api.nvim_win_close(preview, true)
					end
					vim.api.nvim_win_set_config(oil_win, require("oil.layout").get_fullscreen_win_opts())
					return oil.select(nil, function(err)
						if err or not vim.api.nvim_win_is_valid(oil_win) then
							return
						end
						local oil_buf = vim.api.nvim_win_get_buf(oil_win)
						local line = vim.api.nvim_win_get_cursor(oil_win)[1]
						local group = vim.api.nvim_create_augroup("OilDeferredPreview", { clear = true })
						vim.api.nvim_create_autocmd("CursorMoved", {
							group = group,
							buffer = oil_buf,
							callback = function()
								if vim.api.nvim_get_current_win() ~= oil_win or vim.api.nvim_win_get_cursor(oil_win)[1] == line then
									return
								end
								vim.api.nvim_clear_autocmds({ group = group })
								vim.schedule(function()
									if vim.api.nvim_get_current_win() == oil_win and vim.api.nvim_get_current_buf() == oil_buf then
										oil.open_preview()
									end
								end)
							end,
						})
					end)
				end
				return oil.select()
			end
			local fullscreen = vim.api.nvim_win_get_config(0).relative == ""
			local oil_win = vim.api.nvim_get_current_win()
			oil.select({
				handle_buffer_callback = function(bufnr)
					local win = vim.fn.win_findbuf(bufnr)[1]
					if win then
						if fullscreen and win ~= oil_win and vim.api.nvim_win_is_valid(oil_win) then
							vim.api.nvim_win_close(oil_win, false)
						end
						vim.api.nvim_set_current_win(win)
						return
					end
					if fullscreen then
						return vim.cmd.buffer(bufnr)
					end
					vim.cmd.tabnew()
					vim.bo.bufhidden = "wipe"
					vim.cmd.buffer(bufnr)
				end,
			})
		end,
		["h"] = { "actions.parent", mode = "n" },
		["q"] = { "actions.close", mode = "n" },
		["<Esc>"] = { "actions.close", mode = "n" },
	},
	view_options = {
		show_hidden = true,
	},
	float = {
		border = "rounded",
		win_options = {
			winblend = 0,
		},
		max_width = 200,
	},
	preview_win = {
		update_on_cursor_moved = true,
	},
	lsp_file_methods = {
		enabled = true,
		timeout_ms = 1000,
		autosave_changes = true,
	},
})

