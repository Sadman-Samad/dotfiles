return {
  "adibhanna/laravel.nvim",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
  ft = { "php", "blade" },
  keys = {
    { "<leader>Lc", "<cmd>Composer<cr>", desc = "Composer Commands" },
    { "<leader>Lm", "<cmd>LaravelMake<cr>", desc = "Laravel Make" },
    { "<leader>Lr", "<cmd>LaravelRoute<cr>", desc = "Laravel Routes" },
    { "<leader>Ld", "<cmd>LaravelDumps<cr>", desc = "Laravel Dumps" },
    { "<leader>Li", "<cmd>LaravelIdeHelper all<cr>", desc = "Laravel IDE Helper" },
    { "<leader>Lgd", "<cmd>LaravelGoto<cr>", desc = "Laravel Goto" },
    {
      "<leader>La",
      function()
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")

        -- Get artisan commands
        local handle = io.popen("php artisan list --format=json 2>/dev/null")
        local result = handle:read("*a")
        handle:close()

        local commands = {}
        if result and result ~= "" then
          local ok, data = pcall(vim.fn.json_decode, result)
          if ok and data.commands then
            for _, cmd in pairs(data.commands) do
              if not cmd.hidden then
                table.insert(commands, {
                  name = cmd.name,
                  description = cmd.description or "",
                })
              end
            end
          end
        end

        -- Fallback if json parsing fails
        if #commands == 0 then
          local common_commands = {
            { name = "make:controller", description = "Create a new controller class" },
            { name = "make:model", description = "Create a new Eloquent model class" },
            { name = "make:migration", description = "Create a new database migration" },
            { name = "make:seeder", description = "Create a new seeder class" },
            { name = "make:factory", description = "Create a new model factory" },
            { name = "make:middleware", description = "Create a new middleware class" },
            { name = "make:request", description = "Create a new form request class" },
            { name = "migrate", description = "Run the database migrations" },
            { name = "migrate:rollback", description = "Rollback the last database migration" },
            { name = "migrate:refresh", description = "Reset and re-run all migrations" },
            { name = "tinker", description = "Interact with your application" },
            { name = "serve", description = "Serve the application on the PHP development server" },
            { name = "queue:work", description = "Start processing jobs on the queue" },
            { name = "cache:clear", description = "Flush the application cache" },
          }
          commands = common_commands
        end

        pickers
          .new({}, {
            prompt_title = "Laravel Artisan Commands",
            finder = finders.new_table({
              results = commands,
              entry_maker = function(entry)
                return {
                  value = entry,
                  display = entry.name .. " - " .. entry.description,
                  ordinal = entry.name .. " " .. entry.description,
                }
              end,
            }),
            sorter = conf.generic_sorter({}),
            attach_mappings = function(prompt_bufnr, map)
              actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                local cmd = "php artisan " .. selection.value.name
                vim.ui.input({ prompt = "Artisan command: ", default = cmd }, function(input)
                  if input then
                    vim.cmd("!" .. input)
                  end
                end)
              end)
              return true
            end,
          })
          :find()
      end,
      desc = "Artisan Commands (Fuzzy)",
    },
  },
  config = function()
    require("laravel").setup({
      notifications = true,
      debug = false,
      keymaps = true, -- Enable default keymaps
      sail = {
        enabled = true,
        auto_detect = true,
      },
      -- Enhanced settings for module architecture
      artisan = {
        environment = vim.fn.getcwd(),
        executable = "./vendor/bin/sail artisan",
        options = {},
      },
      route_info = {
        enable = true,
        position = "top",
        middlewares = true,
        method = true,
        uri = true,
      },
    })

    -- Override the find_controllers function using ripgrep for high performance
    local navigate = require("laravel.navigate")
    local original_find_controllers = navigate.find_controllers

    navigate.find_controllers = function()
      local function get_project_root()
        return _G.laravel_nvim and _G.laravel_nvim.project_root
      end

      local root = get_project_root()
      if not root then
        return {}
      end

      local controllers = {}

      -- Use ripgrep to find all classes extending Controller
      local rg_command = string.format(
        "rg --type php --no-heading --line-number --column " ..
        "--glob '!vendor/**' --glob '!node_modules/**' --glob '!storage/**' " ..
        "--glob '!bootstrap/cache/**' --glob '!public/**' --glob '!tests/**' " ..
        "--glob '!database/**' --glob '!resources/lang/**' --glob '!resources/js/**' " ..
        "--glob '!resources/css/**' --glob '!resources/sass/**' --glob '!config/**' " ..
        "'class\\s+(\\w+)\\s+extends\\s+.*Controller' '%s' 2>/dev/null",
        root
      )

      local handle = io.popen(rg_command)
      if not handle then
        return {}
      end

      local rg_results = {}
      for line in handle:lines() do
        local file_path, line_num, col, content = line:match("^([^:]+):(%d+):(%d+):(.*)$")
        if file_path and content then
          -- Extract class name from the matched line
          local class_name = content:match("class%s+(%w+)%s+extends%s+.*Controller")
          if class_name then
            rg_results[file_path] = class_name
          end
        end
      end
      handle:close()

      -- For each file found by ripgrep, extract the namespace
      for file_path, class_name in pairs(rg_results) do
        local namespace = nil
        local file = io.open(file_path, "r")

        if file then
          -- Only read until we find the namespace (much faster)
          for line in file:lines() do
            local ns = line:match("namespace%s+([^;]+)")
            if ns then
              namespace = ns:gsub("%s+", "")
              break
            end
            -- Stop reading after reasonable number of lines if no namespace found
            if file:seek() > 2048 then -- First 2KB should contain namespace
              break
            end
          end
          file:close()
        end

        -- Build controller entry
        if namespace then
          local full_namespace = namespace .. "\\" .. class_name
          controllers[#controllers + 1] = {
            name = class_name,
            namespace = full_namespace,
            path = file_path,
          }
        end
      end

      -- Sort controllers by name for better UX
      table.sort(controllers, function(a, b)
        return a.name < b.name
      end)

      return controllers
    end
  end,
}
