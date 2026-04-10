return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "master",
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
					"rust",
					"bash",
					"fish",
					"vim",
					"query",
					"markdown",
					"markdown_inline",
				},
				sync_install = false,
				auto_install = true,
				highlight = { enable = true },
			})
		end,
	},
}
