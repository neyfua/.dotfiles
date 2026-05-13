return {
	"WhoIsSethDaniel/mason-tool-installer.nvim",
	dependencies = { "williamboman/mason.nvim" },
	config = function()
		require("mason-tool-installer").setup({
			ensure_installed = {
				-- lsp
				"ast_grep",
				"bashls",
				"cssls",
				"gopls",
				"html",
				"jdtls",
				"jsonls",
				"lua_ls",
				"luau_lsp",
				"pyright",

				-- formatters
				"beautysh",
				"black",
				"clang-format",
				"gofumpt",
				"prettierd",
				"stylua",
			},
			auto_update = true,
			run_on_start = true,
		})
	end,
}
