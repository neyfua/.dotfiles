local opts = { noremap = true, silent = true }

-- Oil
vim.keymap.set("n", "<leader>w", function()
	local found = false

	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		local name = vim.api.nvim_buf_get_name(buf)
		if name:match("oil://") then
			found = true
			if #vim.api.nvim_list_wins() > 1 then
				-- Close Oil window if not the last window
				vim.api.nvim_win_close(win, true)
			else
				-- Last window: just wipe the buffer instead
				vim.api.nvim_buf_delete(buf, { force = true })
			end
			break
		end
	end

	if not found then
		vim.cmd("Oil")
	end
end, { noremap = true, silent = true })

-- Telescope
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>fa", builtin.find_files, {})
vim.keymap.set("n", "<leader>fg", builtin.git_files, {})
vim.keymap.set("n", "<leader>fl", builtin.live_grep, {})
vim.keymap.set("n", "<leader>fb", builtin.buffers, {})

-- Undotree
vim.keymap.set({ "n", "v" }, "<leader>u", vim.cmd.UndotreeToggle)

-- Bufferline
vim.keymap.set({ "n", "v" }, "<A-q>", vim.cmd.bdelete, opts)
vim.keymap.set({ "n", "v" }, "<A-Q>", vim.cmd.BufferLineCloseOthers, opts)

vim.keymap.set({ "n", "v" }, "<Tab>", vim.cmd.BufferLineCycleNext, opts)
vim.keymap.set({ "n", "v" }, "<S-Tab>", vim.cmd.BufferLineCyclePrev, opts)

vim.keymap.set({ "n", "v" }, "<A-p>", vim.cmd.BufferLineTogglePin, opts)

vim.keymap.set({ "n", "v" }, "<A-]>", vim.cmd.BufferLineMoveNext, opts)
vim.keymap.set({ "n", "v" }, "<A-[>", vim.cmd.BufferLineMovePrev, opts)

-- Comment.nvim
local toggle, comment = pcall(require, "Comment.api")
if not toggle then
	return
end

vim.keymap.set("n", "<leader>/", comment.toggle.linewise.current, opts)
vim.keymap.set("v", "<leader>/", function()
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
	comment.toggle.linewise(vim.fn.visualmode())
end)

-- Search & Replace
vim.api.nvim_set_keymap("v", "<leader>r", "<cmd>SearchReplaceWithinVisualSelection<CR>", opts)

-- Disable PageUp/PageDown keys
for _, mode in ipairs({ "n", "i", "v", "o", "t" }) do
	vim.keymap.set(mode, "<PageUp>", "<Nop>", opts)
	vim.keymap.set(mode, "<PageDown>", "<Nop>", opts)
	vim.keymap.set(mode, "<S-PageUp>", "<Nop>", opts)
	vim.keymap.set(mode, "<S-PageDown>", "<Nop>", opts)
end

-- Disable F1
vim.keymap.set({ "n", "i", "v", "t", "o" }, "<F1>", "<Nop>", opts)

-- Disable Ctrl + Z
vim.keymap.set({ "n", "i", "v", "t", "o" }, "<C-z>", "<Nop>", opts)

-- Clear highlight search
vim.keymap.set("n", "<Esc>", vim.cmd.nohlsearch, opts)

-- Select all
vim.keymap.set("n", "<C-a>", "ggVG", opts)

-- Split window horizontally & vertically
vim.keymap.set("n", "<A-h>", "<cmd>split<CR>", opts)
vim.keymap.set("n", "<A-v>", "<cmd>vsplit<CR>", opts)

-- Resize split
vim.keymap.set({ "n", "i", "v" }, "<A-=>", "<cmd>vertical resize +2<CR>", opts)
vim.keymap.set({ "n", "i", "v" }, "<A-->", "<cmd>vertical resize -2<CR>", opts)
