return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",

		-- Autocompletion
		"hrsh7th/nvim-cmp",
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",
		"hrsh7th/cmp-cmdline",
		"saadparwaiz1/cmp_luasnip",
		"hrsh7th/cmp-nvim-lsp",
		"hrsh7th/cmp-nvim-lua",

		-- Snippets
		{ "L3MON4D3/LuaSnip", build = "make install_jsregexp" },
		"rafamadriz/friendly-snippets",
	},
	config = function()
		-- Diagnostic UI setup
		vim.diagnostic.config({
			virtual_text = false,
			severity_sort = true,
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = "E",
					[vim.diagnostic.severity.WARN] = "W",
					[vim.diagnostic.severity.HINT] = "H",
					[vim.diagnostic.severity.INFO] = "I",
				},
			},
			underline = {
				severity = { min = vim.diagnostic.severity.HINT },
			},
			update_in_insert = false,
		})

		-- Extend LSP capabilities
		local lspconfig_defaults = require("lspconfig").util.default_config
		lspconfig_defaults.capabilities = vim.tbl_deep_extend(
			"force",
			lspconfig_defaults.capabilities,
			require("cmp_nvim_lsp").default_capabilities()
		)

		-- LSP keymaps
		vim.api.nvim_create_autocmd("LspAttach", {
			callback = function(event)
				local opts = { buffer = event.buf }
				vim.keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<cr>", opts)
				vim.keymap.set("n", "<leader>e", "<cmd>lua vim.diagnostic.open_float()<cr>", opts)
				vim.keymap.set("n", "<F2>", "<cmd>lua vim.lsp.buf.rename()<cr>", opts)
			end,
		})

		-- Mason setup
		require("mason").setup({
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		})

		-- Mason-LSPConfig setup
		require("mason-lspconfig").setup({
			handlers = {
				function(server_name)
					require("lspconfig")[server_name].setup({})
				end,
			},
		})

		-- Lua LSP special setup
		vim.lsp.config("lua_ls", {
			settings = {
				Lua = {
					runtime = { version = "LuaJIT" },
					diagnostics = { globals = { "vim" } },
					workspace = { library = { vim.env.VIMRUNTIME } },
				},
			},
		})

		-- Load snippets
		require("luasnip.loaders.from_vscode").lazy_load()

		-- nvim-cmp setup
		local cmp = require("cmp")
		vim.opt.completeopt = { "menu", "menuone", "noselect" }

		cmp.setup({
			preselect = cmp.PreselectMode.Item,
			completion = {
				completeopt = "menu,menuone,noinsert",
			},
			window = {
				completion = cmp.config.window.bordered({
					scrollbar = false, -- optional, hides scrollbar
					winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,Search:None",
				}),
			},
			mapping = cmp.mapping.preset.insert({
				["<C-b>"] = cmp.mapping.scroll_docs(-2),
				["<C-f>"] = cmp.mapping.scroll_docs(2),
				["<C-s>"] = cmp.mapping.abort(),
				["<CR>"] = cmp.mapping.confirm({ select = true }),
				["<Down>"] = cmp.mapping.select_next_item(),
				["<Up>"] = cmp.mapping.select_prev_item(),
			}),
			snippet = {
				expand = function(args)
					require("luasnip").lsp_expand(args.body)
				end,
			},
			sources = cmp.config.sources({
				{ name = "nvim_lsp" },
				{ name = "luasnip", keyword_length = 2 },
				{ name = "buffer" },
				{ name = "path" },
			}),
			formatting = {
				fields = { "abbr", "menu", "kind" },
				format = function(entry, item)
					local n = entry.source.name
					if n == "nvim_lsp" then
						item.menu = "[LSP]"
					else
						item.menu = string.format("[%s]", n)
					end
					return item
				end,
			},
		})

		-- Cmdline completion
		cmp.setup.cmdline(":", {
			mapping = cmp.mapping.preset.cmdline({
				["<Down>"] = { c = cmp.mapping.select_next_item() },
				["<Up>"] = { c = cmp.mapping.select_prev_item() },
				["<Tab>"] = { c = cmp.mapping.confirm({ select = true }) },
				["<M-BS>"] = {
					c = function()
						vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-w>", true, true, true), "c", true)
					end,
				},
			}),
			sources = cmp.config.sources({
				{ name = "path" },
			}, {
				{ name = "cmdline" },
			}),
			matching = { disallow_symbol_nonprefix_matching = false },
		})
	end,
}
