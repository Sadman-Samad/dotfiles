return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ async = true, lsp_fallback = true })
        end,
        mode = "",
        desc = "Format buffer",
      },
    },
    opts = {
      formatters_by_ft = {
        dart = { "dart_format" },
      },
      format_on_save = function(bufnr)
        -- Skip formatting for Dart files since we handle it with code actions
        if vim.bo[bufnr].filetype == "dart" then
          return false
        end
        return {
          timeout_ms = 500,
          lsp_fallback = true,
        }
      end,
      formatters = {
        dart_format = {
          command = "dart",
          args = { "format", "--stdin-name", "$FILENAME" },
          stdin = true,
        },
      },
    },
  },
}