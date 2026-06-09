vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"
vim.g.mapleader = " "

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end
vim.opt.rtp:prepend(lazypath)

local lazy_config = require "configs.lazy"

-- load plugins
require("lazy").setup({
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
    import = "nvchad.plugins",
  },
  {
    "shabaraba/yozakura.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("yozakura").setup({
        transparent = false,
        italic_comments = true,
        palette = "warm_gray",
        styles = {
          comments = { italic = true },
          keywords = { italic = false },
          functions = { italic = false },
          variables = { italic = false },
        },
      })
      vim.cmd.colorscheme("yozakura")
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
  },
  { import = "plugins" },
}, lazy_config)

-- COMENTA ESTAS LÍNEAS para desactivar el tema de NvChad
-- dofile(vim.g.base46_cache .. "defaults")
-- dofile(vim.g.base46_cache .. "statusline")

require "options"
require "autocmds"

vim.schedule(function()
  require "mappings"
end)

vim.opt.relativenumber = true

-- Asegurar que la línea actual muestre el número absoluto (Hybrid Numbering)
-- Esto es lo mejor de los dos mundos: ves dónde estás (línea 50) y cuánto falta para las otras.
vim.opt.number = true
