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

    -- Navigation keybindings (ripgrep-powered)
    { "<leader>Lfc", "<cmd>LaravelController<cr>", desc = "Find Controllers" },
    { "<leader>Lfm", "<cmd>LaravelModel<cr>", desc = "Find Models" },
    {
      "<leader>Lfs",
      function()
        require("laravel.navigate").goto_service()
      end,
      desc = "Find Services",
    },
    {
      "<leader>Lfj",
      function()
        require("laravel.navigate").goto_job()
      end,
      desc = "Find Jobs",
    },
    {
      "<leader>Lfe",
      function()
        require("laravel.navigate").goto_event()
      end,
      desc = "Find Events",
    },
    {
      "<leader>Lfl",
      function()
        require("laravel.navigate").goto_listener()
      end,
      desc = "Find Listeners",
    },
    {
      "<leader>Lfx",
      function()
        require("laravel.navigate").goto_middleware()
      end,
      desc = "Find Middleware",
    },

    -- Database and schema navigation
    {
      "<leader>Lfg",
      function()
        local schema = require("laravel.schema")
        local migrations = schema.find_migrations()
        if #migrations == 0 then
          require("laravel.ui").warn("No migrations found")
          return
        end

        local items = vim.tbl_map(function(mig)
          return string.format("[migration] %s (%s)", mig.name, mig.timestamp)
        end, migrations)

        require("laravel.ui").select(items, {
          prompt = "Select migration:",
          kind = "laravel_migration",
        }, function(choice)
          if choice then
            for _, mig in ipairs(migrations) do
              local display = string.format("[migration] %s (%s)", mig.name, mig.timestamp)
              if display == choice then
                if vim.fn.filereadable(mig.path) == 1 then
                  vim.cmd("edit " .. vim.fn.fnameescape(mig.path))
                else
                  require("laravel.ui").error("Migration file not found: " .. mig.path)
                end
                break
              end
            end
          end
        end)
      end,
      desc = "Find Migrations",
    },

    {
      "<leader>Lfd",
      function()
        local schema = require("laravel.schema")
        local seeders = schema.find_seeders()
        if #seeders == 0 then
          require("laravel.ui").warn("No seeders found")
          return
        end

        local items = vim.tbl_map(function(seeder)
          return string.format("[seeder] %s", seeder.name)
        end, seeders)

        require("laravel.ui").select(items, {
          prompt = "Select seeder:",
          kind = "laravel_seeder",
        }, function(choice)
          if choice then
            for _, seeder in ipairs(seeders) do
              local display = string.format("[seeder] %s", seeder.name)
              if display == choice then
                if vim.fn.filereadable(seeder.path) == 1 then
                  vim.cmd("edit " .. vim.fn.fnameescape(seeder.path))
                else
                  require("laravel.ui").error("Seeder file not found: " .. seeder.path)
                end
                break
              end
            end
          end
        end)
      end,
      desc = "Find Seeders",
    },

    -- Route navigation
    {
      "<leader>Lfr",
      function()
        local navigate = require("laravel.navigate")
        local route_files = navigate.find_route_files()
        if #route_files == 0 then
          require("laravel.ui").warn("No route files found")
          return
        end

        local items = vim.tbl_map(function(route)
          return string.format("[route-file] %s", route.name)
        end, route_files)

        require("laravel.ui").select(items, {
          prompt = "Select route file:",
          kind = "laravel_route_file",
        }, function(choice)
          if choice then
            for _, route in ipairs(route_files) do
              local display = string.format("[route-file] %s", route.name)
              if display == choice then
                if vim.fn.filereadable(route.path) == 1 then
                  vim.cmd("edit " .. vim.fn.fnameescape(route.path))
                else
                  require("laravel.ui").error("Route file not found: " .. route.path)
                end
                break
              end
            end
          end
        end)
      end,
      desc = "Find Route Files",
    },

    {
      "<leader>LfR",
      function()
        local navigate = require("laravel.navigate")
        local route_definitions = navigate.find_route_definitions()
        if #route_definitions == 0 then
          require("laravel.ui").warn("No route definitions found")
          return
        end

        local items = vim.tbl_map(function(route)
          local module_prefix = route.module and "[" .. route.module .. "] " or ""
          local controller_info = route.controller and " → " .. route.controller or ""
          return string.format("[%s] %s%s %s%s",
            route.method, module_prefix, route.uri, route.controller or "", controller_info == "" and "" or controller_info)
        end, route_definitions)

        require("laravel.ui").select(items, {
          prompt = "Select route definition:",
          kind = "laravel_route_definition",
        }, function(choice)
          if choice then
            for _, route in ipairs(route_definitions) do
              local module_prefix = route.module and "[" .. route.module .. "] " or ""
              local controller_info = route.controller and " → " .. route.controller or ""
              local display = string.format("[%s] %s%s %s%s",
                route.method, module_prefix, route.uri, route.controller or "", controller_info == "" and "" or controller_info)

              if display == choice then
                if vim.fn.filereadable(route.file_path) == 1 then
                  vim.cmd("edit +" .. route.line_number .. " " .. vim.fn.fnameescape(route.file_path))
                else
                  require("laravel.ui").error("Route file not found: " .. route.file_path)
                end
                break
              end
            end
          end
        end)
      end,
      desc = "Find Route Definitions",
    },

    -- Unified Laravel architecture browser
    {
      "<leader>Lfa",
      function()
        local ui = require("laravel.ui")
        local navigate = require("laravel.navigate")

        local schema = require("laravel.schema")
        local component_types = {
          { name = "Controllers", finder = navigate.find_controllers },
          { name = "Models", finder = navigate.find_models },
          { name = "Services", finder = navigate.find_services },
          { name = "Jobs", finder = navigate.find_jobs },
          { name = "Events", finder = navigate.find_events },
          { name = "Listeners", finder = navigate.find_listeners },
          { name = "Middleware", finder = navigate.find_middleware },
          { name = "Migrations", finder = schema.find_migrations },
          { name = "Seeders", finder = schema.find_seeders },
          { name = "Route Files", finder = navigate.find_route_files },
          { name = "Route Definitions", finder = navigate.find_route_definitions },
        }

        ui.select(
          vim.tbl_map(function(ct)
            return ct.name
          end, component_types),
          {
            prompt = "Select component type:",
            kind = "laravel_architecture",
          },
          function(choice)
            if choice then
              for _, ct in ipairs(component_types) do
                if ct.name == choice then
                  local components = ct.finder()
                  if #components == 0 then
                    ui.warn("No " .. choice:lower() .. " found")
                    return
                  end

                  local items = vim.tbl_map(function(comp)
                    -- Handle different component types with appropriate display format
                    if comp.timestamp then -- Migration
                      return string.format("[migration] %s (%s)", comp.name, comp.timestamp)
                    elseif comp.namespace and comp.namespace:match("Seeders?") then -- Seeder
                      return string.format("[seeder] %s", comp.name)
                    elseif comp.method and comp.uri then -- Route Definition
                      local module_prefix = comp.module and "[" .. comp.module .. "] " or ""
                      local controller_info = comp.controller and " → " .. comp.controller or ""
                      return string.format("[%s] %s%s%s", comp.method, module_prefix, comp.uri, controller_info)
                    elseif comp.original_name or comp.relative_path then -- Route File
                      return string.format("[route-file] %s", comp.name)
                    else -- Regular class components
                      return string.format("[%s] %s", comp.type or "class", comp.name)
                    end
                  end, components)

                  ui.select(items, {
                    prompt = "Select " .. choice:sub(1, -2):lower() .. ":",
                    kind = "laravel_" .. choice:lower(),
                  }, function(selected)
                    if selected then
                      for _, comp in ipairs(components) do
                        -- Generate display string using same logic as items mapping
                        local display
                        if comp.timestamp then -- Migration
                          display = string.format("[migration] %s (%s)", comp.name, comp.timestamp)
                        elseif comp.namespace and comp.namespace:match("Seeders?") then -- Seeder
                          display = string.format("[seeder] %s", comp.name)
                        elseif comp.method and comp.uri then -- Route Definition
                          local module_prefix = comp.module and "[" .. comp.module .. "] " or ""
                          local controller_info = comp.controller and " → " .. comp.controller or ""
                          display = string.format("[%s] %s%s%s", comp.method, module_prefix, comp.uri, controller_info)
                        elseif comp.original_name or comp.relative_path then -- Route File
                          display = string.format("[route-file] %s", comp.name)
                        else -- Regular class components
                          display = string.format("[%s] %s", comp.type or "class", comp.name)
                        end

                        if display == selected then
                          -- Determine file path and line number for opening
                          local file_path = comp.path or comp.file_path
                          local line_number = comp.line_number

                          -- Safety check: ensure path exists and is a file
                          if vim.fn.filereadable(file_path) == 1 then
                            if line_number then
                              vim.cmd("edit +" .. line_number .. " " .. vim.fn.fnameescape(file_path))
                            else
                              vim.cmd("edit " .. vim.fn.fnameescape(file_path))
                            end
                          else
                            ui.error("File not found: " .. file_path)
                          end
                          break
                        end
                      end
                    end
                  end)
                  break
                end
              end
            end
          end
        )
      end,
      desc = "Laravel Architecture Browser",
    },
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

    -- Override Laravel navigation functions using ripgrep for high performance
    local navigate = require("laravel.navigate")

    -- Store original functions
    local original_find_controllers = navigate.find_controllers
    local original_find_models = navigate.find_models

    -- Common function to create ripgrep-powered class finder
    local function create_ripgrep_finder(class_patterns, exclude_patterns)
      return function()
        local function get_project_root()
          return _G.laravel_nvim and _G.laravel_nvim.project_root
        end

        local root = get_project_root()
        if not root then
          return {}
        end

        local components = {}
        local base_excludes = {
          "vendor/**",
          "node_modules/**",
          "storage/**",
          "bootstrap/cache/**",
          "public/**",
          "tests/**",
          "database/**",
          "resources/lang/**",
          "resources/js/**",
          "resources/css/**",
          "resources/sass/**",
          "config/**",
        }

        -- Add custom excludes
        if exclude_patterns then
          for _, pattern in ipairs(exclude_patterns) do
            table.insert(base_excludes, pattern)
          end
        end

        -- Build glob exclusions
        local glob_excludes = ""
        for _, pattern in ipairs(base_excludes) do
          glob_excludes = glob_excludes .. "--glob '!" .. pattern .. "' "
        end

        -- Try each pattern
        for _, pattern_info in ipairs(class_patterns) do
          local rg_command = string.format(
            "rg --type php --no-heading --line-number --column %s'%s' '%s' 2>/dev/null",
            glob_excludes,
            pattern_info.pattern,
            root
          )

          local handle = io.popen(rg_command)
          if handle then
            for line in handle:lines() do
              local file_path, line_num, col, content = line:match("^([^:]+):(%d+):(%d+):(.*)$")
              if file_path and content then
                local class_name = content:match(pattern_info.extract)
                if class_name then
                  -- Extract namespace
                  local namespace = nil
                  local file = io.open(file_path, "r")
                  if file then
                    for file_line in file:lines() do
                      local ns = file_line:match("namespace%s+([^;]+)")
                      if ns then
                        namespace = ns:gsub("%s+", "")
                        break
                      end
                      if file:seek() > 2048 then
                        break
                      end
                    end
                    file:close()
                  end

                  if namespace then
                    local full_namespace = namespace .. "\\" .. class_name
                    components[#components + 1] = {
                      name = class_name,
                      namespace = full_namespace,
                      path = file_path,
                      type = pattern_info.type or "class",
                    }
                  end
                end
              end
            end
            handle:close()
          end
        end

        -- Remove duplicates and sort
        local seen = {}
        local unique_components = {}
        for _, component in ipairs(components) do
          local key = component.namespace
          if not seen[key] then
            seen[key] = true
            unique_components[#unique_components + 1] = component
          end
        end

        table.sort(unique_components, function(a, b)
          return a.name < b.name
        end)

        return unique_components
      end
    end

    -- Override find_controllers with ripgrep
    navigate.find_controllers = create_ripgrep_finder({
      {
        pattern = "class\\s+(\\w+)\\s+extends\\s+.*Controller",
        extract = "class%s+(%w+)%s+extends%s+.*Controller",
        type = "controller",
      },
    })

    -- Override find_models with ripgrep
    navigate.find_models = create_ripgrep_finder({
      {
        pattern = "class\\s+(\\w+)\\s+extends\\s+Model",
        extract = "class%s+(%w+)%s+extends%s+Model",
        type = "model",
      },
      {
        pattern = "class\\s+(\\w+)\\s+extends\\s+.*Model",
        extract = "class%s+(%w+)%s+extends%s+.*Model",
        type = "model",
      },
      {
        pattern = "use\\s+Illuminate\\\\Database\\\\Eloquent\\\\Model;.*class\\s+(\\w+)",
        extract = "class%s+(%w+)",
        type = "model",
      },
    })

    -- Add new function to find Services
    navigate.find_services = create_ripgrep_finder({
      {
        pattern = "class\\s+(\\w+Service)\\s*\\{",
        extract = "class%s+(%w+Service)",
        type = "service",
      },
      {
        pattern = "class\\s+(\\w+)\\s+extends\\s+.*Service",
        extract = "class%s+(%w+)%s+extends%s+.*Service",
        type = "service",
      },
    })

    -- Add new function to find Jobs
    navigate.find_jobs = create_ripgrep_finder({
      {
        pattern = "class\\s+(\\w+)\\s+implements\\s+ShouldQueue",
        extract = "class%s+(%w+)%s+implements%s+ShouldQueue",
        type = "job",
      },
      {
        pattern = "class\\s+(\\w+)\\s+extends\\s+.*Job",
        extract = "class%s+(%w+)%s+extends%s+.*Job",
        type = "job",
      },
    })

    -- Add new function to find Events
    navigate.find_events = create_ripgrep_finder({
      {
        pattern = "class\\s+(\\w+)\\s*\\{.*use\\s+Dispatchable",
        extract = "class%s+(%w+)",
        type = "event",
      },
      {
        pattern = "class\\s+(\\w+)\\s+extends\\s+.*Event",
        extract = "class%s+(%w+)%s+extends%s+.*Event",
        type = "event",
      },
    })

    -- Add new function to find Listeners
    navigate.find_listeners = create_ripgrep_finder({
      {
        pattern = "class\\s+(\\w+)\\s*\\{.*public\\s+function\\s+handle",
        extract = "class%s+(%w+)",
        type = "listener",
      },
      {
        pattern = "class\\s+(\\w+Listener)\\s*\\{",
        extract = "class%s+(%w+Listener)",
        type = "listener",
      },
    })

    -- Add new function to find Middleware
    navigate.find_middleware = create_ripgrep_finder({
      {
        pattern = "class\\s+(\\w+)\\s*\\{.*public\\s+function\\s+handle.*Request.*next",
        extract = "class%s+(%w+)",
        type = "middleware",
      },
      {
        pattern = "class\\s+(\\w+Middleware)\\s*\\{",
        extract = "class%s+(%w+Middleware)",
        type = "middleware",
      },
    })

    -- Add goto functions for new component types
    local function create_goto_function(finder_func, component_type)
      return function(name)
        if not name or name == "" then
          local components = finder_func()
          if #components == 0 then
            require("laravel.ui").warn("No " .. component_type .. " found")
            return
          end

          local items = vim.tbl_map(function(comp)
            return comp.name
          end, components)
          require("laravel.ui").select(items, {
            prompt = "Select " .. component_type .. ":",
            kind = "laravel_" .. component_type,
          }, function(choice)
            if choice then
              for _, comp in ipairs(components) do
                if comp.name == choice then
                  -- Safety check: ensure path exists and is a file
                  if vim.fn.filereadable(comp.path) == 1 then
                    vim.cmd("edit " .. vim.fn.fnameescape(comp.path))
                  else
                    require("laravel.ui").error("File not found: " .. comp.path)
                  end
                  break
                end
              end
            end
          end)
        else
          local components = finder_func()
          local found = nil
          for _, comp in ipairs(components) do
            if comp.name:lower():match(name:lower()) then
              found = comp
              break
            end
          end

          if found then
            -- Safety check: ensure path exists and is a file
            if vim.fn.filereadable(found.path) == 1 then
              vim.cmd("edit " .. vim.fn.fnameescape(found.path))
            else
              require("laravel.ui").error("File not found: " .. found.path)
            end
          else
            require("laravel.ui").error(component_type:gsub("^%l", string.upper) .. " not found: " .. name)
          end
        end
      end
    end

    navigate.goto_service = create_goto_function(navigate.find_services, "service")
    navigate.goto_job = create_goto_function(navigate.find_jobs, "job")
    navigate.goto_event = create_goto_function(navigate.find_events, "event")
    navigate.goto_listener = create_goto_function(navigate.find_listeners, "listener")
    navigate.goto_middleware = create_goto_function(navigate.find_middleware, "middleware")

    -- Override architecture analysis functions to use our ripgrep-powered finders
    local architecture = require("laravel.architecture")

    -- Store original functions
    local original_analyze_controllers = architecture.analyze_controllers
    local original_analyze_models = architecture.analyze_models

    -- Enhanced analyze_controllers using our ripgrep finder
    architecture.analyze_controllers = function()
      local controllers = {}
      local controller_list = navigate.find_controllers()

      for _, controller in ipairs(controller_list) do
        local controller_info = {
          name = controller.name,
          namespace = controller.namespace,
          path = controller.path,
          methods = {},
          dependencies = {},
          routes = {},
          services = {},
        }

        -- Parse file to extract methods and dependencies
        local file = io.open(controller.path, "r")
        if file then
          local content = file:read("*a")
          file:close()

          -- Extract public methods
          for method in content:gmatch("public%s+function%s+(%w+)%s*%(") do
            if method ~= "__construct" then
              table.insert(controller_info.methods, method)
            end
          end

          -- Extract dependencies from constructor
          local constructor = content:match("public%s+function%s+__construct%s*%([^)]*%)")
          if constructor then
            for dep in constructor:gmatch("(%w+)%s+%$") do
              table.insert(controller_info.dependencies, dep)
            end
          end

          -- Extract service usage
          for service in content:gmatch("$this%->([%w_]+)") do
            if not vim.tbl_contains(controller_info.services, service) then
              table.insert(controller_info.services, service)
            end
          end
        end

        controllers[controller.name] = controller_info
      end

      return controllers
    end

    -- Enhanced analyze_models using our ripgrep finder
    architecture.analyze_models = function()
      local models = {}
      local model_list = navigate.find_models()

      for _, model in ipairs(model_list) do
        local model_info = {
          name = model.name,
          namespace = model.namespace,
          path = model.path,
          table = nil,
          fillable = {},
          relationships = {},
          scopes = {},
          accessors = {},
          mutators = {},
        }

        -- Parse file to extract model information
        local file = io.open(model.path, "r")
        if file then
          local content = file:read("*a")
          file:close()

          -- Extract table name
          local table_match = content:match("protected%s+%$table%s*=%s*['\"]([^'\"]+)['\"]")
          if table_match then
            model_info.table = table_match
          else
            -- Default Laravel table naming convention
            model_info.table = model.name:lower() .. "s"
          end

          -- Extract fillable fields
          local fillable_match = content:match("protected%s+%$fillable%s*=%s*%[([^%]]+)%]")
          if fillable_match then
            for field in fillable_match:gmatch("['\"]([^'\"]+)['\"]") do
              table.insert(model_info.fillable, field)
            end
          end

          -- Extract relationships
          for rel_type in
            content:gmatch("function%s+%w+%s*%(%s*%).-return%s+$this%->(hasOne|hasMany|belongsTo|belongsToMany)")
          do
            if not vim.tbl_contains(model_info.relationships, rel_type) then
              table.insert(model_info.relationships, rel_type)
            end
          end

          -- Extract scopes
          for scope in content:gmatch("function%s+scope(%w+)%s*%(") do
            table.insert(model_info.scopes, scope)
          end

          -- Extract accessors
          for accessor in content:gmatch("function%s+get(%w+)Attribute%s*%(") do
            table.insert(model_info.accessors, accessor)
          end

          -- Extract mutators
          for mutator in content:gmatch("function%s+set(%w+)Attribute%s*%(") do
            table.insert(model_info.mutators, mutator)
          end
        end

        models[model.name] = model_info
      end

      return models
    end

    -- Add new analysis functions for additional component types
    architecture.analyze_services = function()
      local services = {}
      local service_list = navigate.find_services()

      for _, service in ipairs(service_list) do
        local service_info = {
          name = service.name,
          namespace = service.namespace,
          path = service.path,
          methods = {},
          dependencies = {},
        }

        local file = io.open(service.path, "r")
        if file then
          local content = file:read("*a")
          file:close()

          -- Extract public methods
          for method in content:gmatch("public%s+function%s+(%w+)%s*%(") do
            if method ~= "__construct" then
              table.insert(service_info.methods, method)
            end
          end

          -- Extract dependencies
          local constructor = content:match("public%s+function%s+__construct%s*%([^)]*%)")
          if constructor then
            for dep in constructor:gmatch("(%w+)%s+%$") do
              table.insert(service_info.dependencies, dep)
            end
          end
        end

        services[service.name] = service_info
      end

      return services
    end

    architecture.analyze_jobs = function()
      local jobs = {}
      local job_list = navigate.find_jobs()

      for _, job in ipairs(job_list) do
        local job_info = {
          name = job.name,
          namespace = job.namespace,
          path = job.path,
          queue = nil,
          delay = nil,
          tries = nil,
        }

        local file = io.open(job.path, "r")
        if file then
          local content = file:read("*a")
          file:close()

          -- Extract queue configuration
          local queue_match = content:match("protected%s+%$queue%s*=%s*['\"]([^'\"]+)['\"]")
          if queue_match then
            job_info.queue = queue_match
          end

          local delay_match = content:match("protected%s+%$delay%s*=%s*(%d+)")
          if delay_match then
            job_info.delay = tonumber(delay_match)
          end

          local tries_match = content:match("public%s+%$tries%s*=%s*(%d+)")
          if tries_match then
            job_info.tries = tonumber(tries_match)
          end
        end

        jobs[job.name] = job_info
      end

      return jobs
    end

    architecture.analyze_events = function()
      local events = {}
      local event_list = navigate.find_events()

      for _, event in ipairs(event_list) do
        local event_info = {
          name = event.name,
          namespace = event.namespace,
          path = event.path,
          properties = {},
        }

        local file = io.open(event.path, "r")
        if file then
          local content = file:read("*a")
          file:close()

          -- Extract public properties
          for prop in content:gmatch("public%s+%$(%w+)") do
            table.insert(event_info.properties, prop)
          end
        end

        events[event.name] = event_info
      end

      return events
    end

    architecture.analyze_middleware = function()
      local middleware = {}
      local middleware_list = navigate.find_middleware()

      for _, mw in ipairs(middleware_list) do
        local middleware_info = {
          name = mw.name,
          namespace = mw.namespace,
          path = mw.path,
          handle_method = false,
        }

        local file = io.open(mw.path, "r")
        if file then
          local content = file:read("*a")
          file:close()

          -- Check if handle method exists
          if content:match("public%s+function%s+handle") then
            middleware_info.handle_method = true
          end
        end

        middleware[mw.name] = middleware_info
      end

      return middleware
    end

    -- Fix buffer name conflict in architecture diagrams
    local original_show_architecture_diagram = architecture.show_architecture_diagram
    architecture.show_architecture_diagram = function(diagram, diagram_type)
      -- Call original function but wrap it to handle buffer name conflicts
      local success, err = pcall(original_show_architecture_diagram, diagram, diagram_type)
      if not success and err:match("Buffer with this name already exists") then
        -- Generate unique buffer name with timestamp
        local timestamp = os.date("%H:%M:%S")
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(diagram, "\n"))
        vim.api.nvim_buf_set_option(buf, "filetype", "mermaid")
        local unique_name = string.format(
          "Laravel Architecture - %s (%s)",
          diagram_type:gsub("_", " "):gsub("^%l", string.upper),
          timestamp
        )
        vim.api.nvim_buf_set_name(buf, unique_name)
        vim.cmd("split")
        vim.api.nvim_set_current_buf(buf)
        require("laravel.ui").info("Architecture diagram displayed in buffer")
      elseif not success then
        -- Re-throw other errors
        error(err)
      end
    end

    -- Override schema analysis functions to support module migrations
    local schema = require("laravel.schema")
    local original_find_migrations = schema.find_migrations

    -- Enhanced find_migrations using ripgrep to find all migration files across modules
    schema.find_migrations = function()
      local function get_project_root()
        return _G.laravel_nvim and _G.laravel_nvim.project_root
      end

      local root = get_project_root()
      if not root then
        return {}
      end

      local migrations = {}

      -- Define migration directories for different module structures
      local migration_paths = {
        -- Standard Laravel
        root .. "/database/migrations",
        -- nwidart/laravel-modules pattern
        root .. "/Modules/*/Database/migrations",
        root .. "/Modules/*/database/migrations",
        -- Alternative module structures
        root .. "/modules/*/Database/migrations",
        root .. "/modules/*/database/migrations",
        root .. "/app/Modules/*/Database/migrations",
        root .. "/app/Modules/*/database/migrations",
      }

      -- Use ripgrep to find all PHP files that look like migrations
      local rg_command = string.format(
        "rg --type php --files --glob '*_*.php' "
          .. "--glob '!vendor/**' --glob '!node_modules/**' --glob '!storage/**' "
          .. "'%s' 2>/dev/null | grep -E '(migrations?|Migration)' | head -200",
        root
      )

      local handle = io.popen(rg_command)
      if handle then
        for file in handle:lines() do
          -- Check if this looks like a migration file by filename pattern
          local name = vim.fn.fnamemodify(file, ":t:r")
          local timestamp, migration_name = name:match("^(%d%d%d%d_%d%d_%d%d_%d+)_(.+)$")

          if timestamp and migration_name then
            -- Also check directory path to confirm it's in a migrations directory
            if file:match("/migrations?/") or file:match("/Migrations?/") then
              table.insert(migrations, {
                name = migration_name,
                full_name = name,
                timestamp = timestamp,
                path = file,
              })
            end
          end
        end
        handle:close()
      end

      -- Fallback to directory scanning for standard locations if ripgrep finds nothing
      if #migrations == 0 then
        for _, dir in ipairs(migration_paths) do
          if not dir:match("%*") and vim.fn.isdirectory(dir) == 1 then
            local files = vim.fn.glob(dir .. "/*.php", false, true)
            for _, file in ipairs(files) do
              local name = vim.fn.fnamemodify(file, ":t:r")
              local timestamp, migration_name = name:match("^(%d%d%d%d_%d%d_%d%d_%d+)_(.+)$")

              if timestamp and migration_name then
                table.insert(migrations, {
                  name = migration_name,
                  full_name = name,
                  timestamp = timestamp,
                  path = file,
                })
              end
            end
          end
        end
      end

      -- Sort migrations by timestamp for proper execution order
      table.sort(migrations, function(a, b)
        return a.timestamp < b.timestamp
      end)

      return migrations
    end

    -- Add function to find seeders across modules
    schema.find_seeders = function()
      local root = get_project_root()
      if not root then
        return {}
      end

      local seeders = {}

      -- Use ripgrep to find seeder files across modules
      local rg_command = string.format(
        "rg --type php --no-heading --line-number "
          .. "--glob '!vendor/**' --glob '!node_modules/**' "
          .. "'class\\s+(\\w+)\\s+extends\\s+.*Seeder' '%s' 2>/dev/null",
        root
      )

      local handle = io.popen(rg_command)
      if handle then
        for line in handle:lines() do
          local file_path, line_num, content = line:match("^([^:]+):(%d+):(.*)$")
          if file_path and content then
            local seeder_name = content:match("class%s+(%w+)%s+extends%s+.*Seeder")
            if seeder_name then
              -- Extract namespace
              local namespace = nil
              local file = io.open(file_path, "r")
              if file then
                for file_line in file:lines() do
                  local ns = file_line:match("namespace%s+([^;]+)")
                  if ns then
                    namespace = ns:gsub("%s+", "")
                    break
                  end
                  if file:seek() > 1024 then
                    break
                  end
                end
                file:close()
              end

              table.insert(seeders, {
                name = seeder_name,
                namespace = namespace or "Database\\Seeders",
                path = file_path,
              })
            end
          end
        end
        handle:close()
      end

      return seeders
    end

    -- Override route finding functions to support module routes
    local original_find_route_files = navigate.find_route_files

    -- Enhanced find_route_files using ripgrep to find all route files across modules
    navigate.find_route_files = function()
      local function get_project_root()
        return _G.laravel_nvim and _G.laravel_nvim.project_root
      end

      local root = get_project_root()
      if not root then
        return {}
      end

      local route_files = {}

      -- Use ripgrep to find PHP files that contain route definitions
      local rg_command = string.format(
        "rg --type php --files-with-matches " ..
        "--glob '!vendor/**' --glob '!node_modules/**' --glob '!storage/**' " ..
        "'(Route::|Router::|group\\(|get\\(|post\\(|put\\(|patch\\(|delete\\(|resource\\(|apiResource\\()' '%s' 2>/dev/null",
        root
      )

      local handle = io.popen(rg_command)
      if handle then
        for file in handle:lines() do
          -- Check if this looks like a route file by path and content patterns
          local is_route_file = false

          -- Common route file patterns
          if file:match('/routes/') or file:match('/Routes/') or
             file:match('routes%.php$') or file:match('Routes%.php$') or
             file:match('web%.php$') or file:match('api%.php$') then
            is_route_file = true
          end

          -- Also check if it's in a module structure with route-like content
          if file:match('/Modules/.*/[Rr]outes/') or
             file:match('/modules/.*/[Rr]outes/') or
             file:match('/app/Modules/.*/[Rr]outes/') then
            is_route_file = true
          end

          if is_route_file then
            local name = vim.fn.fnamemodify(file, ':t:r')
            local relative_path = file:gsub("^" .. vim.pesc(root) .. "/?", "")

            -- Extract module name if it's a module route
            local module_name = file:match('/Modules/([^/]+)/') or
                               file:match('/modules/([^/]+)/') or
                               file:match('/app/Modules/([^/]+)/')

            local display_name = name
            if module_name then
              display_name = module_name .. "/" .. name
            end

            table.insert(route_files, {
              name = display_name,
              original_name = name,
              path = file,
              relative_path = relative_path,
              module = module_name
            })
          end
        end
        handle:close()
      end

      -- Fallback to standard directory scanning if ripgrep finds nothing
      if #route_files == 0 then
        local standard_routes = root .. '/routes'
        if vim.fn.isdirectory(standard_routes) == 1 then
          local files = vim.fn.glob(standard_routes .. '/*.php', false, true)
          for _, file in ipairs(files) do
            local name = vim.fn.fnamemodify(file, ':t:r')
            table.insert(route_files, {
              name = name,
              original_name = name,
              path = file,
              relative_path = 'routes/' .. name .. '.php',
              module = nil
            })
          end
        end
      end

      -- Sort by name for better UX
      table.sort(route_files, function(a, b)
        return a.name < b.name
      end)

      return route_files
    end

    -- Add function to find specific route definitions across modules
    navigate.find_route_definitions = function()
      local root = get_project_root()
      if not root then
        return {}
      end

      local routes = {}

      -- Use ripgrep to find specific route definitions
      local route_patterns = {
        "Route::get\\(['\"]([^'\"]+)['\"]",
        "Route::post\\(['\"]([^'\"]+)['\"]",
        "Route::put\\(['\"]([^'\"]+)['\"]",
        "Route::patch\\(['\"]([^'\"]+)['\"]",
        "Route::delete\\(['\"]([^'\"]+)['\"]",
        "Route::resource\\(['\"]([^'\"]+)['\"]",
        "Route::apiResource\\(['\"]([^'\"]+)['\"]"
      }

      for _, pattern in ipairs(route_patterns) do
        local method = pattern:match("Route::(%w+)")
        local rg_command = string.format(
          "rg --type php --no-heading --line-number " ..
          "--glob '!vendor/**' --glob '!node_modules/**' " ..
          "'%s' '%s' 2>/dev/null",
          pattern, root
        )

        local handle = io.popen(rg_command)
        if handle then
          for line in handle:lines() do
            local file_path, line_num, content = line:match("^([^:]+):(%d+):(.*)$")
            if file_path and content then
              local uri = content:match(pattern)
              if uri then
                -- Extract controller/action if present
                local controller = content:match("['\"]([^'\"]*Controller[^'\"]*)['\"]")

                -- Extract module from file path
                local module_name = file_path:match('/Modules/([^/]+)/') or
                                   file_path:match('/modules/([^/]+)/') or
                                   file_path:match('/app/Modules/([^/]+)/')

                table.insert(routes, {
                  method = method:upper(),
                  uri = uri,
                  controller = controller,
                  file_path = file_path,
                  line_number = tonumber(line_num),
                  module = module_name
                })
              end
            end
          end
          handle:close()
        end
      end

      -- Sort by URI for better organization
      table.sort(routes, function(a, b)
        if a.module ~= b.module then
          return (a.module or "") < (b.module or "")
        end
        return a.uri < b.uri
      end)

      return routes
    end
  end,
}
