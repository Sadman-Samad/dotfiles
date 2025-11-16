return {

  "nvim-telescope/telescope.nvim",
  keys = {
    -- disable the keymap to grep files
    { "<leader>/", false },
    { "<leader>ss", false },
    { "<leader>sS", false },

    -- change a keymap
    { "<leader><space>", "<cmd>Telescope git_files<cr>", desc = "Find Files (git-files)" },
    { "<leader>fg", LazyVim.pick("files"), desc = "Find Files (Root Dir)" },
    { "<leader>cf", "<cmd>Telescope flutter commands<cr>", desc = "Show flutter commands" },
    -- New Keymap
    {
      "<leader>fW",
      function()
        require("telescope.builtin").live_grep({
          additional_args = function()
            return { "--no-ignore", "--hidden" }
          end,
        })
      end,
      desc = "Find word in File",
    },

    {
      "<leader>fw",
      function()
        require("telescope.builtin").live_grep({
          additional_args = function()
            return { "--no-ignore", "--hidden", "--glob", "!**/node_modules/*", "--glob", "!**/.git/*" }
          end,
        })
      end,
      desc = "Find word in git tracked files",
    },

    -- add a keymap to browse plugin files
    {
      "<leader>fp",
      function()
        require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root })
      end,
      desc = "Find Plugin File",
    },

    -- search for files of same type in root directory
    {
      "<leader>ft",
      function()
        local builtin = require("telescope.builtin")
        local utils = require("telescope.utils")

        -- Get current buffer's file extension
        local current_file = vim.api.nvim_buf_get_name(0)

        -- Check if we have a valid file
        if current_file == "" then
          vim.notify("No file active to determine type", vim.log.levels.WARN)
          return
        end

        -- Extract file extension
        local extension = current_file:match("^.+%.(.+)$")

        if not extension then
          vim.notify("Cannot determine file type - no extension found", vim.log.levels.WARN)
          return
        end

        -- Get project root directory
        local root_dir = utils.buffer_dir()

        -- Search for files with the same extension in root directory
        builtin.find_files({
          cwd = root_dir,
          search_dirs = { root_dir },
          glob_pattern = "*." .. extension,
          prompt_title = "Files of type (." .. extension .. ") in " .. utils.path_tail(root_dir),
        })
      end,
      desc = "Find Files of Same Type in Root",
    },
    {
      "<leader>sS",
      function()
        require("telescope.builtin").lsp_document_symbols({
          symbols = require("lazyvim.util").get_kind_filter(),
        })
      end,
      desc = "Goto Symbol",
    },

    -- {
    --   "<leader>ss",
    --   function()
    --     require("telescope.builtin").lsp_dynamic_workspace_symbols({
    --       symbols = require("lazyvim.util").config.get_kind_filter(),
    --     })
    --   end,
    --   desc = "Goto Symbol (Workspace)",
    -- },
  },
}
