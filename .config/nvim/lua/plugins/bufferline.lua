return {
	{
		"akinsho/bufferline.nvim",
		version = "*",
		dependencies = "nvim-tree/nvim-web-devicons",

		config = function()
			vim.opt.termguicolors = true
			local bufferline = require("bufferline")
			bufferline.setup({
				options = {
					mode = "buffers",
					themable = true,
					numbers = "none",
					indicator = {
						style = "none",
					},
					max_prefix_length = 8,
					tab_size = 1,
					diagnostics = "nvim_lsp",
					diagnostics_indicator = function(count, level, diagnostics_dict, context)
						if context.buffer:current() then
							return "(" .. count .. ")"
						end

						return " "
					end,
					modified_icon = "●",
					groups = {
						items = {
							require("bufferline.groups").builtin.pinned:with({ icon = " " }),
						},
					},
					show_buffer_close_icons = false,
					show_close_icon = false,
					show_tab_indicators = false,
					separator_style = { "" },
					style_preset = {
						bufferline.style_preset.no_italic,
						bufferline.style_preset.no_bold,
					},

					sort_by = nil,
				},
			})
		end,
	},
}
