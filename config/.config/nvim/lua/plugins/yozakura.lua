return {
  "shabaraba/yozakura.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    require("yozakura").setup({
      transparent = false,
      italic_comments = true,
      palette = "night_blue",
      styles = {
        comments = { italic = true },
        keywords = { italic = false },
        functions = { italic = false },
        variables = { italic = false },
      },
    })
    vim.cmd.colorscheme("yozakura")
  end,
}

