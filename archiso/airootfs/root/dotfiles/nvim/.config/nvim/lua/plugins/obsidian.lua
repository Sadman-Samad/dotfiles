-- Obsidian.nvim - Full Obsidian vault integration in Neovim
-- Provides note-taking, linking, templates, daily notes, and search

return {
  "epwalsh/obsidian.nvim",
  version = "*", -- Use latest release
  lazy = true,
  event = {
    -- Only load when opening markdown files in vault directories
    "BufReadPre */vault-*/**.md",
    "BufNewFile */vault-*/**.md",
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim", -- For searching notes
    "nvim-treesitter/nvim-treesitter", -- For syntax highlighting
  },
  opts = {
    -- Configure your Obsidian vaults
    -- NOTE: Create vaults first with: obsidian-vault-init <name> <type>
    workspaces = {
      {
        name = "personal",
        path = "~/Documents/vault-personal",
      },
      {
        name = "work",
        path = "~/Documents/vault-work",
      },
      {
        name = "public",
        path = "~/Documents/vault-public",
      },
      {
        name = "projects",
        path = "~/Documents/vault-projects",
      },
    },

    -- Don't try to auto-detect workspace if we're not in a vault
    detect_cwd = false,

    -- Daily notes configuration
    daily_notes = {
      folder = "Daily",
      date_format = "%Y-%m-%d",
      alias_format = "%B %-d, %Y",
      template = nil,
    },

    -- Templates configuration
    templates = {
      folder = "Templates",
      date_format = "%Y-%m-%d",
      time_format = "%H:%M",
      substitutions = {},
    },

    -- Note ID generation from title
    note_id_func = function(title)
      local suffix = ""
      if title ~= nil then
        -- Convert title to lowercase kebab-case
        suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
      else
        -- Use timestamp if no title
        suffix = tostring(os.time())
      end
      return suffix
    end,

    -- Note path function
    note_path_func = function(spec)
      local path = spec.dir / tostring(spec.id)
      return path:with_suffix(".md")
    end,

    -- Frontmatter management
    disable_frontmatter = false,

    -- Completion configuration
    completion = {
      nvim_cmp = true,
      min_chars = 2,
    },

    -- Mappings (only active in markdown buffers)
    mappings = {
      -- Follow link or open file under cursor
      ["gf"] = {
        action = function()
          return require("obsidian").util.gf_passthrough()
        end,
        opts = { noremap = false, expr = true, buffer = true },
      },
      -- Toggle checkbox
      ["<leader>ch"] = {
        action = function()
          return require("obsidian").util.toggle_checkbox()
        end,
        opts = { buffer = true },
      },
      -- Smart action: follow link or toggle checkbox
      ["<cr>"] = {
        action = function()
          return require("obsidian").util.smart_action()
        end,
        opts = { buffer = true, expr = true },
      },
    },

    -- Use advanced URI for Obsidian app links
    use_advanced_uri = false,
    open_app_foreground = false,

    -- Picker configuration (Telescope)
    picker = {
      name = "telescope.nvim",
      mappings = {
        new = "<C-x>",
        insert_link = "<C-l>",
      },
    },

    -- UI configuration
    ui = {
      enable = true,
      update_debounce = 200,
      -- Checkbox styles
      checkboxes = {
        [" "] = { char = "󰄱", hl_group = "ObsidianTodo" },
        ["x"] = { char = "", hl_group = "ObsidianDone" },
        [">"] = { char = "", hl_group = "ObsidianRightArrow" },
        ["~"] = { char = "󰰱", hl_group = "ObsidianTilde" },
      },
      -- Link and tag icons
      external_link_icon = { char = "", hl_group = "ObsidianExtLinkIcon" },
      reference_text = { hl_group = "ObsidianRefText" },
      highlight_text = { hl_group = "ObsidianHighlightText" },
      tags = { hl_group = "ObsidianTag" },
      hl_groups = {
        ObsidianTodo = { bold = true, fg = "#f78c6c" },
        ObsidianDone = { bold = true, fg = "#89ddff" },
        ObsidianRightArrow = { bold = true, fg = "#f78c6c" },
        ObsidianTilde = { bold = true, fg = "#ff5370" },
        ObsidianRefText = { underline = true, fg = "#c792ea" },
        ObsidianExtLinkIcon = { fg = "#c792ea" },
        ObsidianTag = { italic = true, fg = "#89ddff" },
        ObsidianHighlightText = { bg = "#75662e" },
      },
    },

    -- Attachments configuration
    attachments = {
      img_folder = "Assets",
    },

    -- Follow URL function
    follow_url_func = function(url)
      vim.fn.jobstart({ "xdg-open", url })
    end,
  },

  -- Keybindings (global, not buffer-specific)
  keys = {
    -- Note creation and navigation
    { "<leader>on", "<cmd>ObsidianNew<cr>", desc = "New Note" },
    { "<leader>oq", "<cmd>ObsidianQuickSwitch<cr>", desc = "Quick Switch Note" },
    { "<leader>oo", "<cmd>ObsidianSearch<cr>", desc = "Search Notes" },
    { "<leader>ob", "<cmd>ObsidianBacklinks<cr>", desc = "Show Backlinks" },

    -- Daily notes
    { "<leader>ot", "<cmd>ObsidianToday<cr>", desc = "Today's Note" },
    { "<leader>oy", "<cmd>ObsidianYesterday<cr>", desc = "Yesterday's Note" },
    { "<leader>oT", "<cmd>ObsidianTemplate<cr>", desc = "Insert Template" },

    -- Linking
    { "<leader>ol", "<cmd>ObsidianLink<cr>", desc = "Link to Note", mode = "v" },
    { "<leader>oL", "<cmd>ObsidianLinkNew<cr>", desc = "Link to New Note", mode = "v" },
    { "<leader>of", "<cmd>ObsidianFollowLink<cr>", desc = "Follow Link" },

    -- Workspace management
    { "<leader>ow", "<cmd>ObsidianWorkspace<cr>", desc = "Switch Workspace" },

    -- Tags and search
    { "<leader>os", "<cmd>ObsidianTags<cr>", desc = "Search Tags" },

    -- Open in Obsidian app
    { "<leader>oO", "<cmd>ObsidianOpen<cr>", desc = "Open in Obsidian App" },

    -- Rename note
    { "<leader>or", "<cmd>ObsidianRename<cr>", desc = "Rename Note" },
  },
}
