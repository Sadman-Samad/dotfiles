-- Rose Pine - Beautiful, muted colorscheme
-- Alternative to Catppuccin with excellent transparency support
--
--

return {
  "rose-pine/neovim",
  name = "rose-pine",
  lazy = false, -- Load during startup
  priority = 1000, -- Load before other plugins
  opts = {
    variant = "moon", -- Options: 'main', 'moon', 'dawn'
    dark_variant = "moon",
    dim_inactive_windows = false,
    extend_background_behind_borders = true,

    -- Transparency settings
    styles = {
      bold = true,
      italic = true,
      transparency = true, -- Enable transparency
    },

    -- Disable backgrounds for transparency
    disable_background = true,
    disable_float_background = true,
    disable_italics = false,

    -- Highlight groups customization
    groups = {
      border = "muted",
      link = "iris",
      panel = "surface",

      error = "love",
      hint = "iris",
      info = "foam",
      warn = "gold",

      git_add = "foam",
      git_change = "rose",
      git_delete = "love",
      git_dirty = "rose",
      git_ignore = "muted",
      git_merge = "iris",
      git_rename = "pine",
      git_stage = "iris",
      git_text = "rose",
      git_untracked = "subtle",

      headings = {
        h1 = "iris",
        h2 = "foam",
        h3 = "rose",
        h4 = "gold",
        h5 = "pine",
        h6 = "foam",
      },
    },

    -- Highlight specific groups for better integration
    highlight_groups = {
      -- Transparent backgrounds
      Normal = { bg = "none" },
      NormalFloat = { bg = "none" },
      NormalNC = { bg = "none" },

      -- Telescope transparency
      TelescopeBorder = { fg = "overlay", bg = "none" },
      TelescopeNormal = { fg = "subtle", bg = "none" },
      TelescopeSelection = { fg = "text", bg = "overlay" },
      TelescopeSelectionCaret = { fg = "love", bg = "overlay" },
      TelescopeMultiSelection = { fg = "text", bg = "highlight_high" },
      TelescopePromptPrefix = { bg = "none" },
      TelescopePromptNormal = { bg = "none" },
      TelescopeResultsNormal = { bg = "none" },
      TelescopePreviewNormal = { bg = "none" },
      TelescopePromptBorder = { bg = "none", fg = "overlay" },
      TelescopeResultsBorder = { bg = "none", fg = "overlay" },
      TelescopePreviewBorder = { bg = "none", fg = "overlay" },
      TelescopePromptTitle = { fg = "base", bg = "love" },
      TelescopeResultsTitle = { fg = "base", bg = "love" },
      TelescopePreviewTitle = { fg = "base", bg = "love" },

      -- Which-key transparency
      WhichKey = { fg = "iris" },
      WhichKeyGroup = { fg = "foam" },
      WhichKeyDesc = { fg = "gold" },
      WhichKeySeperator = { fg = "subtle" },
      WhichKeySeparator = { fg = "subtle" },
      WhichKeyFloat = { bg = "none" },
      WhichKeyValue = { fg = "rose" },

      -- LSP and diagnostics
      DiagnosticVirtualTextError = { bg = "none" },
      DiagnosticVirtualTextWarn = { bg = "none" },
      DiagnosticVirtualTextInfo = { bg = "none" },
      DiagnosticVirtualTextHint = { bg = "none" },

      -- Pmenu (completion menu)
      Pmenu = { fg = "subtle", bg = "overlay" },
      PmenuSel = { fg = "text", bg = "highlight_med" },
      PmenuSbar = { bg = "overlay" },
      PmenuThumb = { bg = "muted" },

      -- Status line integration
      StatusLine = { fg = "subtle", bg = "none" },
      StatusLineNC = { fg = "muted", bg = "none" },

      -- Tab line
      TabLine = { bg = "none", fg = "subtle" },
      TabLineFill = { bg = "none" },
      TabLineSel = { fg = "text", bg = "overlay" },

      -- Git signs
      GitSignsAdd = { fg = "foam", bg = "none" },
      GitSignsChange = { fg = "rose", bg = "none" },
      GitSignsDelete = { fg = "love", bg = "none" },

      -- Neo-tree transparency
      NeoTreeNormal = { bg = "none" },
      NeoTreeNormalNC = { bg = "none" },
      NeoTreeEndOfBuffer = { bg = "none" },

      -- Noice transparency
      NoicePopup = { bg = "none" },
      NoicePopupBorder = { fg = "overlay", bg = "none" },
      NoiceCmdlinePopup = { bg = "none" },
      NoiceCmdlinePopupBorder = { fg = "overlay", bg = "none" },

      -- Obsidian.nvim integration (if using)
      ObsidianTodo = { bold = true, fg = "gold" },
      ObsidianDone = { bold = true, fg = "foam" },
      ObsidianRightArrow = { bold = true, fg = "rose" },
      ObsidianTilde = { bold = true, fg = "love" },
      ObsidianRefText = { underline = true, fg = "iris" },
      ObsidianExtLinkIcon = { fg = "iris" },
      ObsidianTag = { italic = true, fg = "foam" },
      ObsidianHighlightText = { bg = "highlight_med" },
    },

    -- Better syntax highlighting
    before_highlight = function(group, highlight, palette)
      -- Customize specific groups before they're applied
    end,
  },

  config = function(_, opts)
    require("rose-pine").setup(opts)

    -- Uncomment the line below to activate Rose Pine by default
    -- vim.cmd("colorscheme rose-pine")

    -- Or create a command to easily switch between themes
    vim.api.nvim_create_user_command("RosePine", function()
      vim.cmd("colorscheme rose-pine")
    end, {})

    vim.api.nvim_create_user_command("RosePineMain", function()
      vim.o.background = "dark"
      require("rose-pine").setup({ variant = "main" })
      vim.cmd("colorscheme rose-pine")
    end, {})

    vim.api.nvim_create_user_command("RosePineMoon", function()
      vim.o.background = "dark"
      require("rose-pine").setup({ variant = "moon" })
      vim.cmd("colorscheme rose-pine")
    end, {})

    vim.api.nvim_create_user_command("RosePineDawn", function()
      vim.o.background = "light"
      require("rose-pine").setup({ variant = "dawn" })
      vim.cmd("colorscheme rose-pine")
    end, {})
  end,
}
