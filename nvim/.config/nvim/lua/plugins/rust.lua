return {
  {
    "mrcjkb/rustaceanvim",
    opts = {
      server = {
        default_settings = {
          ["rust-analyzer"] = {
            inlayHints = {
              bindingModeHints = { enable = false },
              closureReturnTypeHints = { enable = "never" },
              lifetimeElisionHints = { enable = "never" },
            },
          },
        },
      },
    },
    keys = {
      {
        "<leader>rt",
        function()
          local bufnr = vim.api.nvim_get_current_buf()
          vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
        end,
        desc = "Toggle inlay hints",
        ft = "rust",
      },
    },
  },
  {
    "Saecki/crates.nvim",
    keys = {
      { "<leader>rc", "<cmd>Crates toggle<CR>", desc = "Toggle crates", ft = "toml" },
      { "<leader>ru", "<cmd>Crates upgrade_crate<CR>", desc = "Upgrade crate", ft = "toml" },
      { "<leader>rU", "<cmd>Crates upgrade_all_crates<CR>", desc = "Upgrade all crates", ft = "toml" },
      { "<leader>rf", "<cmd>Crates show_features_popup<CR>", desc = "Crate features", ft = "toml" },
    },
  },
}
