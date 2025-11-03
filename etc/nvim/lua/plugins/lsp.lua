return {
  {
    "hinell/lsp-timeout.nvim",
    dependencies={ "neovim/nvim-lspconfig" }
  },
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},
	{
		"mason-lspconfig.nvim",
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = { "lua_ls", "clangd" },
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		config = function()
			local caps = require("cmp_nvim_lsp").default_capabilities()

			-- Actual LSPs
			require("lspconfig").lua_ls.setup({ capabilities = caps })
			require("lspconfig").clangd.setup({ capabilities = caps })
			-- ===========

		end,
	},
}
