return {
    'nvim-telescope/telescope.nvim', tag = 'v0.1.9',
    dependencies = { 'nvim-lua/plenary.nvim' },
    keys = {
        { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = 'Telescope find files' },
        { "<leader>fg", "<cmd>Telescope live_grep<cr>",  desc = 'Telescope live grep' },
        { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = 'Telescope recent files'},
    },
}
