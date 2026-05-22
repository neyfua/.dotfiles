return {
	"stevearc/conform.nvim",
	dependencies = { "williamboman/mason.nvim" },

	config = function()
		local conform = require("conform")

		conform.setup({
			formatters_by_ft = {
				go = { "gofumpt" },
				rust = { "ast_grep" },
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
				luau = { "stylua" },
			},
		})

		vim.keymap.set({ "n", "v", "o" }, "\\r", function()
			conform.format({
				timeout_ms = 1000,
				lsp_fallback = true,
			})
		end, { desc = "Format file" })
	end,
}
