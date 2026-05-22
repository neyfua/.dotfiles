return {
	"mbbill/undotree",
	keys = {
		{
			"<leader>u",
			"<cmd>UndotreeToggle<CR>",
			desc = "Toggle Undotree",
		},
	},
	config = function()
		vim.g.undotree_DiffpanelHeight = 5
	end,
}
