return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "master",
		lazy = false,
		build = ":TSUpdate",
		cond = not vim.g.vscode,
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = {
					"html",
					"css",
					"scss",
					"python",
					"c",
					"cpp",
					"java",
					"json",
					"lua",
					"go",
					"bash",
					"vim",
					"query",
					"markdown",
					"markdown_inline",
				},
				sync_install = true,
				auto_install = true,
				highlight = { enable = true },
			})
		end,
	},
}
