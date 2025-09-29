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

    -- Unified Laravel architecture browser
    {
      "<leader>Lfa",
      function()
        local ui = require("laravel.ui")
        local navigate = require("laravel.navigate")

        local component_types = {
          { name = "Controllers", finder = navigate.find_controllers },
          { name = "Models", finder = navigate.find_models },
          { name = "Services", finder = navigate.find_services },
          { name = "Jobs", finder = navigate.find_jobs },
          { name = "Events", finder = navigate.find_events },
          { name = "Listeners", finder = navigate.find_listeners },
          { name = "Middleware", finder = navigate.find_middleware },
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
                    return string.format("[%s] %s", comp.type or "class", comp.name)
                  end, components)

                  ui.select(items, {
                    prompt = "Select " .. choice:sub(1, -2):lower() .. ":",
                    kind = "laravel_" .. choice:lower(),
                  }, function(selected)
                    if selected then
                      for _, comp in ipairs(components) do
                        local display = string.format("[%s] %s", comp.type or "class", comp.name)
                        if display == selected then
                          vim.cmd("edit " .. comp.path)
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
                  vim.cmd("edit " .. comp.path)
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
            vim.cmd("edit " .. found.path)
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
        local file = io.open(controller.path, 'r')
        if file then
          local content = file:read('*a')
          file:close()

          -- Extract public methods
          for method in content:gmatch('public%s+function%s+(%w+)%s*%(') do
            if method ~= '__construct' then
              table.insert(controller_info.methods, method)
            end
          end

          -- Extract dependencies from constructor
          local constructor = content:match('public%s+function%s+__construct%s*%([^)]*%)')
          if constructor then
            for dep in constructor:gmatch('(%w+)%s+%$') do
              table.insert(controller_info.dependencies, dep)
            end
          end

          -- Extract service usage
          for service in content:gmatch('$this%->([%w_]+)') do
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
        local file = io.open(model.path, 'r')
        if file then
          local content = file:read('*a')
          file:close()

          -- Extract table name
          local table_match = content:match('protected%s+%$table%s*=%s*[\'"]([^\'"]+)[\'"]')
          if table_match then
            model_info.table = table_match
          else
            -- Default Laravel table naming convention
            model_info.table = model.name:lower() .. 's'
          end

          -- Extract fillable fields
          local fillable_match = content:match('protected%s+%$fillable%s*=%s*%[([^%]]+)%]')
          if fillable_match then
            for field in fillable_match:gmatch('[\'"]([^\'"]+)[\'"]') do
              table.insert(model_info.fillable, field)
            end
          end

          -- Extract relationships
          for rel_type in content:gmatch('function%s+%w+%s*%(%s*%).-return%s+$this%->(hasOne|hasMany|belongsTo|belongsToMany)') do
            if not vim.tbl_contains(model_info.relationships, rel_type) then
              table.insert(model_info.relationships, rel_type)
            end
          end

          -- Extract scopes
          for scope in content:gmatch('function%s+scope(%w+)%s*%(') do
            table.insert(model_info.scopes, scope)
          end

          -- Extract accessors
          for accessor in content:gmatch('function%s+get(%w+)Attribute%s*%(') do
            table.insert(model_info.accessors, accessor)
          end

          -- Extract mutators
          for mutator in content:gmatch('function%s+set(%w+)Attribute%s*%(') do
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

        local file = io.open(service.path, 'r')
        if file then
          local content = file:read('*a')
          file:close()

          -- Extract public methods
          for method in content:gmatch('public%s+function%s+(%w+)%s*%(') do
            if method ~= '__construct' then
              table.insert(service_info.methods, method)
            end
          end

          -- Extract dependencies
          local constructor = content:match('public%s+function%s+__construct%s*%([^)]*%)')
          if constructor then
            for dep in constructor:gmatch('(%w+)%s+%$') do
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

        local file = io.open(job.path, 'r')
        if file then
          local content = file:read('*a')
          file:close()

          -- Extract queue configuration
          local queue_match = content:match('protected%s+%$queue%s*=%s*[\'"]([^\'"]+)[\'"]')
          if queue_match then
            job_info.queue = queue_match
          end

          local delay_match = content:match('protected%s+%$delay%s*=%s*(%d+)')
          if delay_match then
            job_info.delay = tonumber(delay_match)
          end

          local tries_match = content:match('public%s+%$tries%s*=%s*(%d+)')
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

        local file = io.open(event.path, 'r')
        if file then
          local content = file:read('*a')
          file:close()

          -- Extract public properties
          for prop in content:gmatch('public%s+%$(%w+)') do
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

        local file = io.open(mw.path, 'r')
        if file then
          local content = file:read('*a')
          file:close()

          -- Check if handle method exists
          if content:match('public%s+function%s+handle') then
            middleware_info.handle_method = true
          end
        end

        middleware[mw.name] = middleware_info
      end

      return middleware
    end
  end,
}
