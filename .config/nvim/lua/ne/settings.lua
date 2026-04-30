vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.nu = true
-- vim.opt.relativenumber = true

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2

-- vim.opt.signcolumn = "yes"
vim.opt.scrolloff = 3

-- vim.opt.showmode = false

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

vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		local yanked = vim.v.event
		local regtype = yanked.regtype

		if regtype ~= "V" then
			return
		end

		local start_line = yanked.regcontents and #yanked.regcontents or 0
		if start_line == 0 then
			return
		end

		vim.notify(start_line .. " lines yanked", vim.log.levels.INFO, {
			title = "Yank",
		})
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = "*",
	callback = function()
		vim.opt.formatoptions:remove({ "o", "r" })
	end,
})
