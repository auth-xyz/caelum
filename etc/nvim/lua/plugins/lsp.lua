return { -- language support
	"neovim/nvim-lspconfig",
	config = function()
		vim.lsp.config("*", {})
		vim.lsp.enable({
			"gopls",
			"jdtls",
			"kotlin_language_server",
			"lua_ls",
			"pylsp",
			"rust_analyzer",
			"ts_ls",
		})
	end,
}
