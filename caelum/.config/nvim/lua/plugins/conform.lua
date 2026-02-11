return {
  'stevearc/conform.nvim',
  opts = function ()
    require('conform').setup({
      formatters_by_ft = {
        lua = { "stylua" },
        rust = { "bacon" },
      },
      format_on_save = {
        lsp_format = "fallback",
        timeout_ms = 500,
      },
    })
  end,
}
