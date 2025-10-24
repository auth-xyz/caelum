return {
    cmd = {
        "lua-language-server",
    },
    filetypes = {
        "lua",
    },
    root_markers = {
        ".git",
        ".luacheckrc",
    },

    single_file_support = true,
    log_level = vim.lsp.protocol.MessageType.Warning,
}
