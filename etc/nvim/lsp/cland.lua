return {
    cmd = { "clangd", },
    filetypes = {
        "c",
        "cpp",
    },
    single_file_support = true,
    log_level = vim.lsp.protocol.MessageType.Warning,
}
