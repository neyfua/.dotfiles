if vim.loader then
	vim.loader.enable()
end

-- _G.dd = function(...)
--     require("util.debug").dump(...)
-- end
-- vim.print = _G.dd

_G.Ne = require("ne.utils")
require("ne.config.options")
require("ne.config.keymaps")
require("ne.config.autocmds")
require("ne.config.commands")
require("ne.config.workarounds")
require("ne.plugins")
