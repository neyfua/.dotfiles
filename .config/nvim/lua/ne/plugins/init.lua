gh = function(x)
	return "https://github.com/" .. x
end

vim.api.nvim_create_autocmd("PackChanged", {
	callback = function(ev)
		if ev.data.spec.name == "markdown-preview.nvim" and (ev.data.kind == "install" or ev.data.kind == "update") then
			local result = vim.system({ "npx", "--yes", "yarn", "install" }, { cwd = ev.data.path .. "/app", text = true }):wait()
			if result.code ~= 0 then
				vim.notify("Markdown Preview build failed: " .. (result.stderr or ""), vim.log.levels.ERROR)
			end
		end
	end,
})

vim.pack.add({
	-- UI
	{ src = gh("rose-pine/neovim"), name = "rose-pine" },
	{ src = gh("nvim-mini/mini.icons") },
	{ src = gh("folke/snacks.nvim") },
	{ src = gh("folke/trouble.nvim") },
	{ src = gh("nvim-lualine/lualine.nvim") },
	{ src = gh("esmuellert/codediff.nvim") },
	{ src = gh("rachartier/tiny-cmdline.nvim") },
	-- Editor
	{ src = gh("stevearc/conform.nvim") },
	{ src = gh("nvim-treesitter/nvim-treesitter") },
	{ src = gh("mks-h/treesitter-autoinstall.nvim") },
	{ src = gh("nvim-mini/mini.pairs") },
	{ src = gh("nvim-mini/mini.move") },
	{ src = gh("nvim-mini/mini.surround") },
	{ src = gh("craftzdog/mini.diff"), version = "feat/grouping" },
	{ src = gh("saghen/blink.cmp"), version = vim.version.range("^1") },
	{ src = gh("folke/todo-comments.nvim") },
	{ src = gh("lewis6991/gitsigns.nvim") },
	{ src = gh("linrongbin16/gitlinker.nvim") },
	{ src = gh("brenoprata10/nvim-highlight-colors") },
	{ src = gh("iamcco/markdown-preview.nvim") },
	-- LSP
	{ src = gh("neovim/nvim-lspconfig") },
	{ src = gh("mason-org/mason.nvim") },
	{ src = gh("WhoIsSethDaniel/mason-tool-installer.nvim") },
	-- Util
	{ src = gh("stevearc/oil.nvim") },
	{ src = gh("Tim4c/tuios-nvim-navigator") },
	{ src = gh("roobert/search-replace.nvim") },
})

if #vim.api.nvim_get_runtime_file("lua/ne/plugins/local.lua", false) > 0 then
	require("ne.plugins.local")
end

require("ne.plugins.ui")
require("ne.plugins.treesitter")
require("ne.plugins.editor")
require("ne.plugins.lsp")
require("ne.plugins.util")
require("ne.plugins.keymaps")
