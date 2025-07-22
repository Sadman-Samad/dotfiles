-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

local function run_code_actions_on_save()
  local params = vim.lsp.util.make_range_params()
  params.context = {
    only = {
      "source.organizeImports",
      "source.fixAll",
    },
    diagnostics = {},
  }

  local clients = vim.lsp.get_clients({ bufnr = 0 })
  for _, client in ipairs(clients) do
    if client.name == "dartls" then
      local result = client.request_sync("textDocument/codeAction", params, 1000, 0)
      if result and result.result then
        for _, action in ipairs(result.result) do
          if action.edit then
            vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
          end
        end
      end
    end
  end
end

-- Run code actions on Dart file save
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.dart",
  callback = function()
    run_code_actions_on_save()
  end,
  desc = "Run Dart code actions on save",
})
