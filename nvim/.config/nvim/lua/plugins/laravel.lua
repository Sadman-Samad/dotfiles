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

    -- Override the find_controllers function to support module architecture
    local navigate = require("laravel.navigate")
    local original_find_controllers = navigate.find_controllers

    navigate.find_controllers = function()
      local function get_project_root()
        return _G.laravel_nvim and _G.laravel_nvim.project_root
      end

      local root = get_project_root()
      if not root then return {} end

      local controllers = {}

      -- Define controller paths for different module structures
      local controller_paths = {
        -- Standard Laravel
        { path = root .. '/app/Http/Controllers', namespace = 'App\\Http\\Controllers' },
        -- nwidart/laravel-modules
        { path = root .. '/Modules', pattern = 'Modules/*/Http/Controllers', namespace_pattern = 'Modules\\%s\\Http\\Controllers' },
        -- Alternative module structure
        { path = root .. '/modules', pattern = 'modules/*/Http/Controllers', namespace_pattern = 'Modules\\%s\\Http\\Controllers' },
        -- Custom module structure
        { path = root .. '/app/Modules', pattern = 'app/Modules/*/Controllers', namespace_pattern = 'App\\Modules\\%s\\Controllers' },
      }

      local function scan_directory(dir, namespace)
        if vim.fn.isdirectory(dir) ~= 1 then return end

        local items = vim.fn.readdir(dir)
        if not items then return end

        for _, item in ipairs(items) do
          local full_path = dir .. '/' .. item

          if vim.fn.isdirectory(full_path) == 1 then
            -- Recursively scan subdirectories
            scan_directory(full_path, namespace .. '\\' .. item)
          elseif item:match('%.php$') and item:match('Controller%.php$') then
            local class_name = item:gsub('%.php$', '')
            controllers[#controllers + 1] = {
              name = class_name,
              namespace = namespace .. '\\' .. class_name,
              path = full_path,
            }
          end
        end
      end

      -- Scan standard Laravel controllers
      if vim.fn.isdirectory(controller_paths[1].path) == 1 then
        scan_directory(controller_paths[1].path, controller_paths[1].namespace)
      end

      -- Scan module controllers
      for i = 2, #controller_paths do
        local base_path = controller_paths[i].path
        if vim.fn.isdirectory(base_path) == 1 then
          local modules = vim.fn.readdir(base_path)
          if modules then
            for _, module in ipairs(modules) do
              local module_controllers_path = base_path .. '/' .. module .. '/Http/Controllers'
              if controller_paths[i].pattern:match('app/Modules') then
                module_controllers_path = base_path .. '/' .. module .. '/Controllers'
              end

              if vim.fn.isdirectory(module_controllers_path) == 1 then
                local namespace = string.format(controller_paths[i].namespace_pattern, module)
                scan_directory(module_controllers_path, namespace)
              end
            end
          end
        end
      end

      return controllers
    end
  end,
}
