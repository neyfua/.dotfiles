return {
	{
		"nvim-mini/mini.nvim",
		Lazy = true,
		version = false,
		config = function()
			require("mini.snippets").setup()

			require("mini.statusline").setup()

			require("mini.pairs").setup()

			require("mini.move").setup({
				mappings = {
					left = "<M-C-Left>",
					right = "<M-C-Right>",
					down = "<M-C-Down>",
					up = "<M-C-Up>",

					line_left = "<M-C-Left>",
					line_right = "<M-C-Right>",
					line_down = "<M-C-Down>",
					line_up = "<M-C-Up>",
				},
			})

			require("mini.surround").setup({})

			require("mini.icons").setup({})
		end,
	},
}
