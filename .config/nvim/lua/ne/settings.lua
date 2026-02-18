vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.signcolumn = "yes"
vim.opt.scrolloff = 5
vim.opt.showmode = false
vim.opt.clipboard = "unnamedplus"
vim.opt.smartcase = true
vim.opt.ignorecase = true
vim.opt.backup = false
vim.opt.undofile = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.termguicolors = true
vim.opt.cursorline = true
vim.g.have_nerd_font = true
-- vim.opt.fillchars:append({ eob = " " })
vim.opt.guicursor = ""

vim.cmd([[
  highlight YankHighlight guibg=#403d52 guifg=#e0def4
]])
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
	callback = function()
		vim.hl.on_yank({
			higroup = "YankHighlight",
		})
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = "*",
	callback = function()
		vim.opt_local.formatoptions:remove({ "r", "o" })
	end,
})
