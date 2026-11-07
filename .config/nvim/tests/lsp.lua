-- Run: nvim --headless -c 'luafile tests/lsp.lua'
local ok, err = pcall(function()
	for _, name in ipairs({
		"ansiblels", "ast_grep", "bashls", "cssls", "docker_compose_language_service",
		"docker_language_server", "dockerls", "emmet_language_server", "fish_lsp",
		"gopls", "html", "jdtls", "jsonls", "lua_ls", "pyright",
	}) do
		assert(vim.lsp.is_enabled(name), name .. " is disabled")
		assert(vim.lsp.config[name].capabilities.textDocument.completion.completionItem.snippetSupport,
			name .. " lacks snippet support")
	end

	vim.cmd.edit("/tmp/opencode/nvim-lsp-check.html")
	assert(vim.wait(15000, function()
		local ready = {}
		for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
			if client.initialized then ready[client.name] = true end
		end
		return ready.html and ready.emmet_language_server
	end), "HTML/Emmet did not attach")

	for name, text in pairs({ html = "<di", emmet_language_server = "html:5" }) do
		vim.api.nvim_buf_set_lines(0, 0, -1, false, { text })
		local client = assert(vim.lsp.get_clients({ bufnr = 0, name = name })[1])
		vim.wait(300, function() return false end)
		local response = assert(client:request_sync("textDocument/completion", {
			textDocument = vim.lsp.util.make_text_document_params(0),
			position = { line = 0, character = #text },
			context = { triggerKind = 1 },
		}, 5000, 0))
		assert(not response.err, vim.inspect(response.err))
		local result = assert(response.result, name .. " returned no result")
		local items = result.items or result
		assert(#items > 0, name .. " returned no completions")
		if name == "emmet_language_server" then
			local item = items[1]
			local snippet = item.textEdit and item.textEdit.newText or item.insertText
			assert(item.insertTextFormat == 2 and snippet, "Emmet did not return a snippet")
			vim.api.nvim_buf_set_lines(0, 0, -1, false, { "" })
			vim.api.nvim_win_set_cursor(0, { 1, 0 })
			vim.snippet.expand(snippet)
			local document = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
			assert(document:lower():find("<!doctype html>", 1, true), "Missing HTML5 doctype")
			assert(document:find("<body>", 1, true), "Missing HTML body")
			vim.snippet.stop()
		end
	end
end)
if not ok then
	io.stderr:write(tostring(err) .. "\n")
	vim.cmd("cquit 1")
end
print("PASS: installed LSPs enabled; HTML completion; Emmet HTML5 expansion")
vim.cmd("qa!")
