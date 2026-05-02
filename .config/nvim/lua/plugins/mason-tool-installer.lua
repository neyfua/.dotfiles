return {
	"WhoIsSethDaniel/mason-tool-installer.nvim",
	dependencies = { "williamboman/mason.nvim" },
	config = function()
		require("mason-tool-installer").setup({
			ensure_installed = {
				-- lsp
				"ast_grep",
				"bashls",
				"lua_ls",
				"html",
				"cssls",
				"pyright",
				"jdtls",
				"ts_ls",
				"jsonls",

				-- formatters
				"beautysh",
				"stylua",
				"prettierd",
				"black",
				"autoflake",
				"clang-format",
			},
			auto_update = true,
			run_on_start = true,
		})
	end,
}
