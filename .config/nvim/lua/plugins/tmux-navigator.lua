return {
	{
		"christoomey/vim-tmux-navigator",
		cmd = {
			"TmuxNavigateLeft",
			"TmuxNavigateDown",
			"TmuxNavigateUp",
			"TmuxNavigateRight",
		},
		keys = {
			-- Normal + Insert + Visual + Select + Terminal
			{ "<C-Left>", "<cmd>TmuxNavigateLeft<cr>", mode = { "n", "i", "v", "x", "s" } },
			{ "<C-Down>", "<cmd>TmuxNavigateDown<cr>", mode = { "n", "i", "v", "x", "s" } },
			{ "<C-Up>", "<cmd>TmuxNavigateUp<cr>", mode = { "n", "i", "v", "x", "s" } },
			{ "<C-Right>", "<cmd>TmuxNavigateRight<cr>", mode = { "n", "i", "v", "x", "s" } },
		},
	},
}
