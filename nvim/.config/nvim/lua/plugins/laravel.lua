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

    -- Override the find_controllers function to search for classes extending Controller
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

      -- Directories to exclude from search
      local exclude_patterns = {
        "vendor/",
        "node_modules/",
        "storage/",
        "bootstrap/cache/",
        "public/",
        ".git/",
        "tests/",
        "database/",
        "resources/lang/",
        "resources/js/",
        "resources/css/",
        "resources/sass/",
        "config/",
        ".env",
        "artisan",
      }

      -- Function to check if path should be excluded
      local function should_exclude(path)
        local rel_path = path:gsub("^" .. vim.pesc(root) .. "/?", "")
        for _, pattern in ipairs(exclude_patterns) do
          if rel_path:match("^" .. vim.pesc(pattern)) then
            return true
          end
        end
        return false
      end

      -- Function to extract namespace from PHP file
      local function extract_namespace_and_class(file_path)
        local file = io.open(file_path, "r")
        if not file then
          return nil, nil
        end

        local namespace = nil
        local class_name = nil
        local found_class = false

        -- Read file line by line for better performance on large files
        for line in file:lines() do
          -- Skip comments and empty lines
          if not line:match("^%s*//") and not line:match("^%s*%*") and not line:match("^%s*$") then
            -- Extract namespace
            if not namespace then
              local ns = line:match("namespace%s+([^;]+)")
              if ns then
                namespace = ns:gsub("%s+", "")
              end
            end

            -- Extract class name and check if it extends Controller
            if not found_class then
              -- Match various Controller extension patterns
              local cn = line:match("class%s+(%w+)%s+extends%s+[%w\\]*Controller")
                or line:match("class%s+(%w+)%s+extends%s+Controller")
                or line:match("class%s+(%w+)%s+extends%s+BaseController")
                or line:match("class%s+(%w+)%s+extends%s+\\?Illuminate\\Routing\\Controller")

              if cn then
                class_name = cn
                found_class = true
              end
            end

            -- Break early if we found both
            if namespace and found_class then
              break
            end
          end
        end

        file:close()
        return namespace, class_name
      end

      -- Recursively scan directory for PHP files that extend Controller
      local function scan_directory(dir)
        if vim.fn.isdirectory(dir) ~= 1 then
          return
        end
        if should_exclude(dir) then
          return
        end

        local items = vim.fn.readdir(dir)
        if not items then
          return
        end

        for _, item in ipairs(items) do
          local full_path = dir .. "/" .. item

          if vim.fn.isdirectory(full_path) == 1 then
            -- Recursively scan subdirectories
            scan_directory(full_path)
          elseif item:match("%.php$") then
            local namespace, class_name = extract_namespace_and_class(full_path)

            if class_name and namespace then
              -- Build full class path
              local full_namespace = namespace .. "\\" .. class_name

              controllers[#controllers + 1] = {
                name = class_name,
                namespace = full_namespace,
                path = full_path,
              }
            end
          end
        end
      end

      -- Start scanning from project root
      scan_directory(root)

      -- Sort controllers by name for better UX
      table.sort(controllers, function(a, b)
        return a.name < b.name
      end)

      return controllers
    end
  end,
}
