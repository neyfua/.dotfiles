return {
	"stevearc/conform.nvim",
	lazy = false,
	event = "BufWritePre",
	dependencies = { "williamboman/mason.nvim" },
	config = function()
		require("conform").setup({
			formatters_by_ft = {
				sh = { "beautysh" },
				bash = { "beautysh" },
				zsh = { "beautysh" },
				lua = { "stylua" },
				html = { "prettierd" },
				css = { "prettierd" },
				scss = { "prettierd" },
				python = { "black", "autoflake", stop_after_first = true },
				c = { "clang-format" },
				cpp = { "clang-format" },
				cs = { "csharpier", "clang-format", stop_after_first = true },
				java = { "clang-format" },
				javascript = { "prettierd" },
				json = { "clang-format" },
				php = { "pretty-php" },
			},

			format_on_save = {
				timeout_ms = 1000,
				lsp_fallback = true,
			},
		})
	end,
}
