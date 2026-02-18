return {
	"WhoIsSethDaniel/mason-tool-installer.nvim",
	dependencies = { "williamboman/mason.nvim" },
	config = function()
		require("mason-tool-installer").setup({
			ensure_installed = {
				--LSP
				"bashls",
				"lua_ls",
				"html",
				"cssls",
				"pyright",
				"clangd",
				"omnisharp",
				"jdtls",
				"ts_ls",
				"jsonls",
				"stylua",
				"intelephense",
				"phpactor",

				-- Formatters
				"beautysh",
				"stylua",
				"prettierd",
				"black",
				"autoflake",
				"clang-format",
				"csharpier",
				"pretty-php",
				"taplo",
			},
			auto_update = true,
			run_on_start = true,
		})
	end,
}
