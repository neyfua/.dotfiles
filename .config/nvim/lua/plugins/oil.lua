return {
	"stevearc/oil.nvim",
	dependencies = { { "nvim-mini/mini.icons", opts = {} } },
	lazy = false,
	opts = {
		default_file_explorer = true,
		columns = {
			"icon",
			"size",
			"mtime",
		},
		delete_to_trash = false,
		skip_confirm_for_simple_edits = true,
		lsp_file_methods = {
			-- Enable or disable LSP file operations
			enabled = true,
			-- Time to wait for LSP file operations to complete before skipping
			timeout_ms = 1000,
			-- Set to true to autosave buffers that are updated with LSP willRenameFiles
			-- Set to "unmodified" to only save unmodified buffers
			autosave_changes = false,
		},
		watch_for_changes = true,
		view_options = {
			-- Show files and directories that start with "."
			show_hidden = true,
			-- Sort file and directory names case insensitive
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
	vim.api.nvim_set_hl(0, "OilBorder", { fg = "#ebbcba", bg = "#1f1d2e" }),
}
