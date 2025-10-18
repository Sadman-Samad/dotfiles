-- Load omarchy theme dynamically
-- This allows the theme to change when omarchy theme is switched
local omarchy_theme_path = vim.fn.expand("~/.config/omarchy/current/theme/neovim.lua")

if vim.fn.filereadable(omarchy_theme_path) == 1 then
  return dofile(omarchy_theme_path)
else
  -- Fallback to default theme if omarchy is not available
  return {
    {
      "catppuccin/nvim",
      name = "catppuccin",
      opts = {
        flavour = "mocha",
      },
    },
    {
      "LazyVim/LazyVim",
      opts = {
        colorscheme = "catppuccin",
      },
    },
  }
end
