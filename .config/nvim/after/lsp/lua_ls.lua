local library = { vim.env.VIMRUNTIME }
-- ponytail: chỉ thêm blink.cmp; đổi thành vim.api.nvim_get_runtime_file("lua", true) nếu cần type cho plugin khác
for _, path in ipairs(vim.api.nvim_get_runtime_file("lua/blink/cmp/init.lua", false)) do
	library[#library + 1] = path:match("^(.*)/lua/blink/cmp/init%.lua$")
end

---@type vim.lsp.Config
return {
	single_file_support = true,
	settings = {
		Lua = {
			workspace = {
				checkThirdParty = false,
				library = library,
			},
			misc = {
				parameters = {
					-- "--log-level=trace",
				},
			},
			hint = {
				enable = true,
				setType = false,
				paramType = true,
				paramName = "Disable",
				semicolon = "Disable",
				arrayIndex = "Disable",
			},
			doc = {
				privateName = { "^_" },
			},
			type = {
				castNumberToInteger = true,
			},
			diagnostics = {
				disable = { "incomplete-signature-doc", "trailing-space" },
				-- enable = false,
				groupSeverity = {
					strong = "Warning",
					strict = "Warning",
				},
				groupFileStatus = {
					["ambiguity"] = "Opened",
					["await"] = "Opened",
					["codestyle"] = "None",
					["duplicate"] = "Opened",
					["global"] = "Opened",
					["luadoc"] = "Opened",
					["redefined"] = "Opened",
					["strict"] = "Opened",
					["strong"] = "Opened",
					["type-check"] = "Opened",
					["unbalanced"] = "Opened",
					["unused"] = "Opened",
				},
				unusedLocalExclude = { "_*" },
			},
		},
	},
}
