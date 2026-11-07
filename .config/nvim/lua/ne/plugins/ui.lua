local icons = Ne.icons
local lualine_utils = require("ne.utils.lualine")
local lazygit_utils = require("ne.utils.lazygit")

local cursor_group = vim.api.nvim_create_augroup("CursorColor", { clear = true })
vim.api.nvim_create_autocmd("ColorScheme", {
	group = cursor_group,
	callback = function()
		vim.api.nvim_set_hl(0, "Cursor", { fg = "#191724", bg = "#e0def4" })
		vim.api.nvim_set_hl(0, "lCursor", { fg = "#191724", bg = "#e0def4" })
	end,
})

require("rose-pine").setup()
vim.cmd.colorscheme("rose-pine")

require("mini.icons").setup()
require("mini.icons").mock_nvim_web_devicons()

-- Custom tabline setup
require("ne.utils.tabline").setup()
vim.o.showtabline = 1
vim.o.tabline = "%!v:lua.require('ne.utils.tabline').render()"

require("snacks").setup({
	indent = { enabled = true },
	scroll = { enabled = false },
	picker = {
		enabled = true,
		win = { input = { keys = { ["<Esc>"] = { "close", mode = { "n", "i" } } } } },
		layout = { preset = "default" },
		sources = {
			files = { hidden = true },
			grep = { hidden = true },
		},
	},
	notifier = { enabled = true },
	statuscolumn = { enabled = true },
	words = { enabled = true },
	lazygit = {
		enabled = true,
		configure = true, -- auto-sets nvim-remote preset & syncs theme
		config = {
			-- Open files selected in lazygit in the pane it was launched from,
			-- instead of the nvim-remote preset's new tab. See utils/lazygit.lua.
			os = {
				edit = lazygit_utils.edit_command(),
				editAtLine = lazygit_utils.edit_command({ at_line = true }),
			},
		},
		theme = {
			activeBorderColor = { fg = "WarningMsg", bold = true },
		},
	},
})

require("tiny-cmdline").setup({
	position = {
		y = "20%",
	},
})

require("lualine").setup({
	options = {
		theme = "auto",
		globalstatus = true,
		disabled_filetypes = { statusline = { "dashboard", "alpha", "ministarter", "snacks_dashboard" } },
		refresh = {
			events = {
				"WinEnter",
				"BufEnter",
				"BufWritePost",
				"SessionLoadPost",
				"FileChangedShellPost",
				"VimResized",
				"Filetype",
				"CursorMoved",
				"CursorMovedI",
				"ModeChanged",
				-- Macro
				"RecordingEnter",
				"RecordingLeave",
			},
		},
	},
	sections = {
		lualine_a = { "mode" },
		lualine_b = { "branch" },

		lualine_c = {
			lualine_utils.root_dir(),
			{ "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
			{
				lualine_utils.pretty_path({
					length = 0,
					relative = "cwd",
					modified_hl = "MatchParen",
					directory_hl = "",
					filename_hl = "Bold",
					modified_sign = "",
					readonly_icon = " 󰌾 ",
				}),
			},
		},
		lualine_x = {
			lualine_utils.macro_recording(),
			{
				"diagnostics",
				symbols = {
					error = icons.diagnostics.Error,
					warn = icons.diagnostics.Warn,
					info = icons.diagnostics.Info,
					hint = icons.diagnostics.Hint,
				},
			},
			{
				"diff",
				symbols = {
					added = icons.git.added,
					modified = icons.git.modified,
					removed = icons.git.removed,
				},
				source = function()
					local gitsigns = vim.b.gitsigns_status_dict
					if gitsigns then
						return {
							added = gitsigns.added,
							modified = gitsigns.changed,
							removed = gitsigns.removed,
						}
					end
				end,
			},
		},
		lualine_y = {
			{ "progress", separator = " ", padding = { left = 1, right = 1 } },
		},
		lualine_z = {
			{ "location", padding = { left = 1, right = 1 } },
		},
	},
})

require("codediff").setup({
	explorer = {
		width = 50,
		auto_open_on_cursor = true,
		view_mode = "tree", -- "list" or "tree"
		line_stats = {
			enabled = true,
		},
	},
	diff = {
		compact = true,
		compact_context_lines = 8,
		compact_sync_folds = true, -- open/close folds in both panes together
	},
	keymaps = {
		view = {},
	},
})

-- LSP word-reference backgrounds cover diagnostic underlines on matching text.
local function keep_diagnostic_underlines_visible()
	for _, group in ipairs({ "LspReferenceText", "LspReferenceRead", "LspReferenceWrite" }) do
		vim.api.nvim_set_hl(0, group, { bg = "NONE" })
	end
end

keep_diagnostic_underlines_visible()
vim.api.nvim_create_autocmd("ColorScheme", { callback = keep_diagnostic_underlines_visible })

vim.diagnostic.config({
	underline = true,
	update_in_insert = false,
	virtual_text = false,
	severity_sort = true,
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = icons.diagnostics.Error,
			[vim.diagnostic.severity.WARN] = icons.diagnostics.Warn,
			[vim.diagnostic.severity.HINT] = icons.diagnostics.Hint,
			[vim.diagnostic.severity.INFO] = icons.diagnostics.Info,
		},
	},
})
