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
