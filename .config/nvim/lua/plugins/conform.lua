return {
	"stevearc/conform.nvim",
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
				cshtml = { "prettierd", "csharpier" },
				scss = { "prettierd" },
				python = { "black", "autoflake", stop_after_first = true },
				c = { "clang-format" },
				cpp = { "clang-format" },
				cs = { "csharpier", "clang-format", stop_after_first = true },
				java = { "clang-format" },
				javascript = { "prettierd" },
				json = { "clang-format" },
				php = { "pretty-php" },
				toml = { "taplo" },
			},

			format_on_save = {
				timeout_ms = 1000,
				lsp_fallback = true,
			},
		})
	end,
}
