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
				"html",
				"jdtls",
				"jsonls",
				"lua_ls",
				"pyright",

				-- formatters
				"black",
				"beautysh",
				"prettierd",
				"clang-format",
				"stylua",
			},
			auto_update = true,
			run_on_start = true,
		})
	end,
}
