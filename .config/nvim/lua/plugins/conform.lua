return {
	"stevearc/conform.nvim",
	event = "BufWritePre",
	dependencies = { "williamboman/mason.nvim" },
	config = function()
		require("conform").setup({
			formatters_by_ft = {
				rust = { "ast_grep" },
				go = { "ast_grep" },
				python = { "black" },
				bash = { "beautysh" },
				sh = { "beautysh" },
				zsh = { "beautysh" },
				css = { "prettierd" },
				html = { "prettierd" },
				javascript = { "prettierd" },
				markdown = { "prettierd" },
				scss = { "prettierd" },
				c = { "clang-format" },
				cpp = { "clang-format" },
				cs = { "clang-format" },
				java = { "clang-format" },
				json = { "clang-format" },
				lua = { "stylua" },
			},

			format_on_save = {
				timeout_ms = 1000,
				lsp_fallback = true,
			},
		})
	end,
}
