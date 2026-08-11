-- Tailwind CSS v4 support: the default LazyVim tailwind extra only detects
-- projects with tailwind.config.{js,ts,cjs,mjs}. Tailwind v4 uses CSS-based
-- config (@theme in app.css/main.css), so we add root markers for detection.
return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- Add Tailwind v4 CSS-based root markers
      if opts.servers.tailwindcss then
        opts.servers.tailwindcss.root_markers = vim.list_extend(
          opts.servers.tailwindcss.root_markers or {},
          { "app.css", "main.css", "index.css", "globals.css" }
        )
      end
    end,
  },
}
