require("core.keymaps");
require("core.options");
require("core.swap");
require("core.lazy");

vim.api.nvim_create_autocmd({"InsertEnter"}, {
    callback = function()
        vim.opt.relativenumber = false
        vim.opt.number = true
    end
})

vim.api.nvim_create_autocmd({"InsertLeave"}, {
    callback = function()
        vim.opt.relativenumber = true
        vim.opt.number = true
    end
})

vim.api.nvim_create_autocmd({"VimEnter"}, {
    callback = function()
        vim.opt.relativenumber = true
        vim.opt.number = true
    end
})


