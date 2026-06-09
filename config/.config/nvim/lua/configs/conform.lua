local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    typescript = { "prettier" },
    javascript = { "prettier" },
    json = { "prettier" },
    yaml = { "prettier" },
    html = { "prettier" },
    css = { "prettier" },
  },

  format_on_save = {
    timeout_ms = 500,
    lsp_fallback = true,
  },
}

return options
