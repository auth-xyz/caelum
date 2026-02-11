return {
  {
    "hinell/lsp-timeout.nvim",
    dependencies = { "neovim/nvim-lspconfig" }
  },
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "clangd" },
        automatic_installation = true,
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      local caps = require("cmp_nvim_lsp").default_capabilities()
      require("mason-lspconfig").setup({
        function(server_name)
          vim.lsp.config(server_name, { capabilities = caps })
        end,
      })
    end,
  },
}
