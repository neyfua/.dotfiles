return {
	"numToStr/FTerm.nvim",
	config = function()
		local fterm = require("FTerm")

		-- FTerm setup
		fterm.setup({
			border = "double",
			dimensions = {
				height = 0.95,
				width = 0.9,
				x = 0.5,
				y = 0.5,
			},
		})

		vim.keymap.set({ "n", "i", "v", "t" }, "<A-`>", function()
			fterm.toggle()
		end, { noremap = true, silent = true })

		vim.keymap.set("t", "<C-x>", function()
			local bufnr = vim.api.nvim_get_current_buf()
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes([[<C-\><C-n>]], true, false, true), "n", false)
			vim.keymap.set(
				"n",
				"<C-x>",
				"i",
				vim.tbl_extend("force", { noremap = true, silent = true }, { buffer = bufnr })
			)
			vim.keymap.set("n", "q", function()
				fterm.toggle()
			end, vim.tbl_extend("force", { noremap = true, silent = true }, { buffer = bufnr }))
		end, { noremap = true, silent = true })
	end,
}
