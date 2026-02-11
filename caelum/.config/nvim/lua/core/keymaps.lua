local map = vim.keymap.set
local opts = { silent = true }

local function opt(desc, others)
  return vim.tbl_extend("force", opts, { desc = desc }, others or {})
end



vim.g.mapleader = " "
map("n", "<leader>w", ":w<CR>")
map("n", "<leader>q", ":q<CR>")

-- ident
map("v", "<", "<gv", opts)
map("v", ">", ">gv", opts)

-- move things up and down
map("n", "<A-k>", "<Esc>:m .-2<CR>==gi", opts)
map("n", "<A-j>", "<Esc>:m .+1<CR>==gi", opts)

-- remove highlight
map("n", "\\", "<Cmd>noh<CR>", opt("Remove highlight"))

-- lsp binds
map('n', 'gd', vim.lsp.buf.definition, { desc = 'Go to definition' })
map('n', 'gD', vim.lsp.buf.declaration, { desc = 'Go to declaration' })
map('n', 'gr', vim.lsp.buf.references, { desc = 'Find references' })
map('n', 'gi', vim.lsp.buf.implementation, { desc = 'Go to implementation' })
map('n', 'K', vim.lsp.buf.hover, { desc = 'Hover documentation' })
map('n', '<leader>rn', vim.lsp.buf.rename, { desc = 'Rename symbol' })
map('n', '<leader>ca', vim.lsp.buf.code_action, { desc = 'Code actions' })
map('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostics' })
map('n', '[d', vim.diagnostic.goto_prev, { desc = 'Previous diagnostic' })
map('n', ']d', vim.diagnostic.goto_next, { desc = 'Next diagnostic' })
