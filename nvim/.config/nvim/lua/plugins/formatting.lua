return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        rust = { "rustfmt" },
        go = { "goimports", "gofumpt" },
        c = { "clang-format" },
        cpp = { "clang-format" },
        python = { "ruff_format" },
        dart = { "dart_format" },
      },
    },
  },
}
