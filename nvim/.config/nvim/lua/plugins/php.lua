return {
  -- Blade syntax highlighting
  {
    "jwalton512/vim-blade",
    ft = "blade",
  },

  -- Treesitter support for Blade
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "php",
        "blade",
        "html",
        "css",
        "javascript",
      },
    },
  },

  -- Override LazyVim PHP extra to use Pint instead of php-cs-fixer
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        php = { "pint" },
        blade = { "blade-formatter" },
      },
      formatters = {
        pint = {
          command = "vendor/bin/pint",
          args = { "--quiet", "$FILENAME" },
          stdin = false,
          cwd = require("conform.util").root_file({ "composer.json" }),
        },
        ["blade-formatter"] = {
          command = "blade-formatter",
          args = { "--stdin" },
          stdin = true,
        },
      },
    },
  },

  -- Disable PHPCS linting (override LazyVim PHP extra)
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        php = {}, -- Empty table disables PHPCS linting
        blade = {},
      },
    },
  },

  -- Disable none-ls PHP sources if using none-ls
  {
    "nvimtools/none-ls.nvim",
    optional = true,
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      -- Remove PHP sources to prevent conflicts with Pint
      local nls = require("null-ls")
      for i = #opts.sources, 1, -1 do
        local source = opts.sources[i]
        if source == nls.builtins.formatting.phpcsfixer or source == nls.builtins.diagnostics.phpcs then
          table.remove(opts.sources, i)
        end
      end
    end,
  },

  -- Set Intelephense as preferred PHP LSP
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "intelephense",
      },
    },
  },

  -- Enhanced LSP settings for Laravel with Intelephense
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- Set Intelephense as the preferred PHP LSP
      vim.g.lazyvim_php_lsp = "intelephense"

      opts.servers = opts.servers or {}
      opts.servers.intelephense = {
        settings = {
          intelephense = {
            files = {
              maxSize = 5000000,
              associations = {
                "*.php",
                "*.blade.php",
              },
              exclude = {
                "**/node_modules/**",
                "**/vendor/**/Tests/**",
                "**/vendor/**/tests/**",
                "**/storage/framework/cache/**",
                "**/storage/framework/views/**",
              },
            },
            environment = {
              includePaths = {
                "vendor",
                "_ide_helper.php",
                ".phpstorm.meta.php",
              },
            },
            completion = {
              insertUseDeclaration = true,
              fullyQualifyGlobalConstantsAndFunctions = false,
              triggerParameterHints = true,
              maxItems = 100,
            },
            format = {
              enable = false, -- Use Pint instead
            },
            stubs = {
              "apache",
              "bcmath",
              "bz2",
              "calendar",
              "com_dotnet",
              "Core",
              "ctype",
              "curl",
              "date",
              "dba",
              "dom",
              "enchant",
              "exif",
              "FFI",
              "fileinfo",
              "filter",
              "fpm",
              "ftp",
              "gd",
              "gettext",
              "gmp",
              "hash",
              "iconv",
              "imap",
              "intl",
              "json",
              "ldap",
              "libxml",
              "mbstring",
              "meta",
              "mysqli",
              "oci8",
              "odbc",
              "openssl",
              "pcntl",
              "pcre",
              "PDO",
              "pdo_ibm",
              "pdo_mysql",
              "pdo_pgsql",
              "pdo_sqlite",
              "pgsql",
              "Phar",
              "posix",
              "pspell",
              "readline",
              "Reflection",
              "session",
              "shmop",
              "SimpleXML",
              "snmp",
              "soap",
              "sockets",
              "sodium",
              "SPL",
              "sqlite3",
              "standard",
              "superglobals",
              "sysvmsg",
              "sysvsem",
              "sysvshm",
              "tidy",
              "tokenizer",
              "xml",
              "xmlreader",
              "xmlrpc",
              "xmlwriter",
              "xsl",
              "Zend OPcache",
              "zip",
              "zlib",
              "laravel",
            },
          },
        },
      }

      -- Disable PHPActor to avoid conflicts
      opts.servers.phpactor = { enabled = false }

      return opts
    end,
  },
}

