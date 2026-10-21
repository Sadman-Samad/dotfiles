return {
  "okuuva/auto-save.nvim",
  version = "^1.0.0",
  event = { "InsertLeave", "TextChanged" },
  opts = {
    debounce_delay = 1000,
    condition = function(buf)
      if vim.fn.getbufvar(buf, "&buftype") ~= "" then
        return false
      end
      if vim.api.nvim_buf_get_name(buf) == "" then
        return false
      end
      return vim.fn.getbufvar(buf, "&modifiable") == 1
    end,
  },
  keys = {
    { "<leader>ua", "<cmd>ASToggle<CR>", desc = "Toggle autosave" },
  },
}
