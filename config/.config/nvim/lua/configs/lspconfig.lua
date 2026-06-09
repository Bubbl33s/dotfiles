require("nvchad.configs.lspconfig").defaults()

local servers = { "html", "cssls", "clangd", "pyright", "vtsls", "prismals", "dockerls", "yamlls", "jsonls" }
vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers 
