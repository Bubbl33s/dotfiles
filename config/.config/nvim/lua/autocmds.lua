require "nvchad.autocmds"

local autocmd = vim.api.nvim_create_autocmd

-- Configuración para Web (JS, TS, HTML, CSS, YAML, JSON) -> 2 Espacios
autocmd("FileType", {
  pattern = { "javascript", "typescript", "typescriptreact", "html", "css", "scss", "json", "yaml", "python" },
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.expandtab = true
  end,
})

