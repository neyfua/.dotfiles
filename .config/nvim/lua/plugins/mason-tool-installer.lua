return {
	"WhoIsSethDaniel/mason-tool-installer.nvim",
	dependencies = { "williamboman/mason.nvim" },
	config = function()
		require("mason-tool-installer").setup({
			ensure_installed = {
				-- lsp
				"ansiblels",
				"ast_grep",
				"bashls",
				"cssls",
				"docker_compose_language_service",
				"docker_language_server",
				"fish_lsp",
				"dockerls",
				"gopls",
				"html",
				"jdtls",
				"jsonls",
				"lua_ls",
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
