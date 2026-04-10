return {
	"lukas-reineke/indent-blankline.nvim",
	cond = not vim.g.vscode,
	main = "ibl",
	---@module "ibl"
	opts = {
		scope = {
			enabled = false,
		},
	},
}
