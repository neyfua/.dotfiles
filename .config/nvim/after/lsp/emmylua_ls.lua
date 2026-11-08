---@type vim.lsp.Config
return {
	on_init = function(client)
		local root = client.config.root_dir
		if root and vim.uv.fs_realpath(root) == vim.uv.fs_realpath(vim.fn.stdpath("config")) then
			local library = { vim.env.VIMRUNTIME }
			for _, path in ipairs(vim.api.nvim_get_runtime_file("lua/blink/cmp/init.lua", false)) do
				library[#library + 1] = path:match("^(.*)/lua/blink/cmp/init%.lua$")
			end
			client.config.settings.emmylua = {
				runtime = { version = "LuaJIT" },
				diagnostics = { globals = { "vim" }, disable = { "incomplete-signature-doc" } },
				doc = { privateName = { "_*" } },
				hint = { enable = true, localHint = false, paramHint = false, indexHint = false },
				workspace = { library = library },
			}
		end
	end,
}
