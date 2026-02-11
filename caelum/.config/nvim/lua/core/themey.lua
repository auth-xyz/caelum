vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = vim.fn.expand("~/.config/nvim/colors/themey.lua"),
  callback = function()
    vim.cmd('colorscheme themey')
  end,
})

vim.cmd.colorscheme("themey")
