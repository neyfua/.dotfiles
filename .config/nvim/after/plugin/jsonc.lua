-- nvim-treesitter's plugin/filetypes.lua maps jsonc -> json (which errors on trailing commas).
-- Override it after plugins load so JSONC files use the json5 parser.
vim.treesitter.language.register("json5", "jsonc")
