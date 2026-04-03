return {
	"lukas-reineke/indent-blankline.nvim",
	lazy = true,
	cond = not vim.g.vscode,
	main = "ibl",
	---@module "ibl"
	opts = {
		scope = {
			enabled = false,
		},
	},
}
