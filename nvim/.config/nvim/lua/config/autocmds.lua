-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

local autosave = vim.api.nvim_create_augroup("user_autosave", { clear = true })

vim.api.nvim_create_autocmd({ "InsertLeave", "BufLeave", "FocusLost" }, {
  group = autosave,
  desc = "Automatically format and save modified files",
  callback = function(args)
    local buffer = args.buf
    if
      vim.api.nvim_buf_is_valid(buffer)
      and vim.bo[buffer].modified
      and vim.bo[buffer].modifiable
      and not vim.bo[buffer].readonly
      and vim.bo[buffer].buftype == ""
      and vim.api.nvim_buf_get_name(buffer) ~= ""
    then
      vim.api.nvim_buf_call(buffer, function()
        if vim.g.autoformat ~= false and vim.b[buffer].autoformat ~= false then
          LazyVim.format.format({ buf = buffer })
        end
        vim.cmd("silent update")
      end)
    end
  end,
})
