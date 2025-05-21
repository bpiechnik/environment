return {
	{ -- Autoformat
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		keys = {
			{
				"<leader>f",
				function()
					require("conform").format({ async = true, lsp_format = "fallback" })
				end,
				mode = "",
				desc = "[F]ormat buffer",
			},
		},
		opts = {
			notify_on_error = true,
			-- format_on_save = function(bufnr)
			--   local disable_filetypes = { c = true, cpp = true, go = true }
			--   local lsp_format_opt
			--   if disable_filetypes[vim.bo[bufnr].filetype] then
			--     lsp_format_opt = 'never'
			--   else
			--     lsp_format_opt = 'fallback'
			--   end
			--   return {
			--     async = true,
			--     lsp_format = lsp_format_opt,
			--   }
			-- end,
			async = true,
			format_on_save = {
				timeout_ms = 1500,
			},
			formatters_by_ft = {
				lua = { "stylua" },
				go = { "gofumpt", "goimports-reviser", "staticchek", async = true, lsp_format = "never" },
				sql = { "pg_format" },
				yaml = { "yq" },
				json = { "yq" },
				-- python = { "isort", "black" },
			},
		},
	},
}
