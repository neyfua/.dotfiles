-- Completion
---@module 'blink.cmp'
---@type blink.cmp.Config
require("blink.cmp").setup({
	snippets = {
		preset = "default",
	},
	completion = {
		accept = {
			-- experimental auto-brackets support
			auto_brackets = {
				enabled = true,
			},
		},
		menu = {
			border = "none",
			draw = {
				treesitter = { "lsp" },
			},
		},
		documentation = {
			auto_show = true,
			auto_show_delay_ms = 200,
		},
		ghost_text = { enabled = false },
		trigger = { prefetch_on_insert = false },
	},

	-- sources = {
	--   -- adding any nvim-cmp sources here will enable them
	--   -- with blink.compat
	--   compat = {},
	--   default = { "lsp", "path", "snippets", "buffer" },
	-- },

	cmdline = {
		enabled = true,
		keymap = {
			preset = "cmdline",
			["<Right>"] = false,
			["<Left>"] = false,
		},
		completion = {
			list = { selection = { preselect = false } },
			menu = {
				auto_show = function(ctx)
					return vim.fn.getcmdtype() == ":"
				end,
			},
			ghost_text = { enabled = true },
		},
	},

	keymap = {
		preset = "enter",
		["c-y"] = { "select_and_accept" },
	},

	appearance = {
		kind_icons = Ne.icons.kinds,
	},
})

require("mini.pairs").setup({
	modes = { insert = true, command = true, terminal = false },
})

require("mini.move").setup({
	mappings = {
		left = "<M-C-Left>",
		right = "<M-C-Right>",
		down = "<M-C-Down>",
		up = "<M-C-Up>",
		line_left = "<M-C-Left>",
		line_right = "<M-C-Right>",
		line_down = "<M-C-Down>",
		line_up = "<M-C-Up>",
	},
})

require("mini.surround").setup({})

require("mini.diff").setup({
	view = {
		-- show whole reference part above whole buffer part, as in `git diff`
		overlay_style = "hunk",
	},
	mappings = {
		-- same keymaps as codediff.nvim
		goto_next = "]c",
		goto_prev = "[c",
	},
})
-- Split / TUIOS pane navigation
require("tuios-nvim-navigator").setup({
	keymaps = {
		left = "<C-Left>",
		down = "<C-Down>",
		up = "<C-Up>",
		right = "<C-Right>",
	},
	modes = { "n", "i", "v", "x", "s" },
})

require("search-replace").setup({
	default_replace_single_buffer_options = "gcI",
	default_replace_multi_buffer_options = "egcI",
})

-- Comments
require("todo-comments").setup()

-- Git integration
require("gitsigns").setup()
require("gitlinker").setup()

-- Formatting
local oxfmtFormatter = { "oxfmt", "prettierd", "prettier", stop_after_first = true }
require("conform").setup({
	default_format_opts = {
		timeout_ms = 3000,
		async = false,
		quiet = false,
		lsp_format = "fallback",
	},
	formatters_by_ft = {
		go = { "gofumpt" },
		rust = { "ast_grep" },
		python = { "black" },
		bash = { "beautysh" },
		zsh = { "beautysh" },
		c = { "clang-format" },
		cpp = { "clang-format" },
		cs = { "clang-format" },
		java = { "clang-format" },
		javascript = oxfmtFormatter,
		typescript = oxfmtFormatter,
		javascriptreact = oxfmtFormatter,
		typescriptreact = oxfmtFormatter,
		json = oxfmtFormatter,
		css = oxfmtFormatter,
		html = oxfmtFormatter,
		markdown = oxfmtFormatter,
		yaml = oxfmtFormatter,
		less = oxfmtFormatter,
		scss = oxfmtFormatter,
		["markdown.mdx"] = oxfmtFormatter,
		lua = { "stylua" },
		sh = { "shfmt" },
		fish = { "fish_indent" },
	},
	formatters = {
		oxfmt = {
			-- Treat oxfmt as available only when the project has an oxfmt config
			-- (.oxfmtrc.json / .oxfmtrc.jsonc). Without it, oxfmt is skipped and the
			-- formatter list falls back to prettier.
			require_cwd = true,
		},
	},
})

-- Colors
vim.lsp.document_color.enable(false)
require("nvim-highlight-colors").setup({
	render = "background",
	enable_hex = true,
	enable_short_hex = true,
	enable_rgb = true,
	enable_hsl = true,
	enable_hsl_without_function = true,
	enable_ansi = true,
	enable_var_usage = true,
	enable_tailwind = false,
})
