require("mason").setup()
require("mason-tool-installer").setup({
	ensure_installed = {
		-- lsp
		"ansible-language-server",
		"ast-grep",
		"bash-language-server",
		"css-lsp",
		"docker-compose-language-service",
		"docker-language-server",
		"fish-lsp",
		"dockerfile-language-server",
		"gopls",
		"html-lsp",
		"jdtls",
		"json-lsp",
		"lua-language-server",
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

local capabilities = {
	workspace = {
		fileOperations = {
			didRename = true,
			willRename = true,
		},
	},
}
vim.lsp.config("*", {
	capabilities = require("blink.cmp").get_lsp_capabilities(capabilities),
})

vim.lsp.enable({
	"eslint",
	"oxlint",
	"lua_ls",
	"cssls",
	"vtsls",
	"tailwindcss",
	"glsl_analyzer",
	"rust_analyzer",
})
