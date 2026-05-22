return {
	"roobert/search-replace.nvim",

	keys = {
		{
			"<leader>r",
			"<cmd>SearchReplaceWithinVisualSelection<CR>",
			mode = "v",
			desc = "Search Replace Within Selection",
		},
	},

	config = function()
		require("search-replace").setup({
			default_replace_single_buffer_options = "gcI",
			default_replace_multi_buffer_options = "egcI",
		})
	end,
}
