local opts = { noremap = true, silent = true }

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

-- Bufferline
vim.keymap.set({ "n", "v" }, "<Tab>", "<Cmd>BufferLineCycleNext<CR>", opts)
vim.keymap.set({ "n", "v" }, "<S-Tab>", "<Cmd>BufferLineCyclePrev<CR>", opts)
vim.keymap.set({ "n", "v" }, "<A-p>", vim.cmd.BufferLineTogglePin, opts)
vim.keymap.set({ "n", "v" }, "<A-]>", vim.cmd.BufferLineMoveNext, opts)
vim.keymap.set({ "n", "v" }, "<A-[>", vim.cmd.BufferLineMovePrev, opts)
