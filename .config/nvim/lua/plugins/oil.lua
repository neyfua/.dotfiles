return {
	"stevearc/oil.nvim",
	cond = not vim.g.vscode and not vim.g.antigravity,

	dependencies = {
		{ "nvim-mini/mini.icons", opts = {} },
	},

	opts = {
		default_file_explorer = true,

		columns = {
			"icon",
			-- "size",
			"mtime",
		},

		delete_to_trash = true,
		skip_confirm_for_simple_edits = true,
		watch_for_changes = true,

		lsp_file_methods = {
			enabled = true,
			timeout_ms = 1000,
			autosave_changes = false,
		},

		view_options = {
			show_hidden = true,
			case_insensitive = true,
		},

		confirmation = {
			border = "double",

			win_options = {
				winblend = 0,
				winhighlight = "Normal:NormalFloat,FloatBorder:OilBorder",
			},
		},
	},

	keys = {
		{
			"<leader>w",
			function()
				local found = false

				for _, win in ipairs(vim.api.nvim_list_wins()) do
					local buf = vim.api.nvim_win_get_buf(win)
					local name = vim.api.nvim_buf_get_name(buf)

					if name:match("oil://") then
						found = true

						if #vim.api.nvim_list_wins() > 1 then
							vim.api.nvim_win_close(win, true)
						else
							vim.api.nvim_buf_delete(buf, { force = true })
						end

						break
					end
				end

				if not found then
					if vim.fn.exists(":Oil") == 2 then
						vim.cmd("Oil")
					end
				end
			end,
			desc = "Toggle Oil",
		},
	},

	config = function(_, opts)
		require("oil").setup(opts)

		vim.api.nvim_set_hl(0, "OilBorder", {
			fg = "#ebbcba",
			bg = "#1f1d2e",
		})
	end,
}
