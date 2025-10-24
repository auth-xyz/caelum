return {
  "nvim-tree/nvim-tree.lua",
  version = "*",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = { "NvimTreeToggle", "NvimTreeFocus" },
  keys = {
    { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Toggle File Tree" },
    { "<leader>f", "<cmd>NvimTreeFocus<cr>",  desc = "Focus File Tree" },
  },
  config = function()
    require("nvim-tree").setup({
      sort_by = "case_sensitive",
      view = {
        width = 35,
        side = "left",
        preserve_window_proportions = true,
      },
      renderer = {
        group_empty = true,
        highlight_git = true,
        indent_markers = {
          enable = true,
        },
        icons = {
          glyphs = {
            folder = {
              arrow_closed = "",
              arrow_open = "",
            },
          },
        },
      },
      filters = {
        dotfiles = false,
        custom = { "^.git$" },
      },
      git = {
        enable = true,
        ignore = false,
      },
      update_focused_file = {
        enable = true,
        update_root = true,
      },
      actions = {
        open_file = {
          quit_on_open = false,
          resize_window = true,
        },
      },
    })
  end,
}

