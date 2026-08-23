return {
  "yetone/avante.nvim",
  opts = {
    provider = "groq",

    behaviour = {
      auto_add_current_file = false,
      auto_check_diagnostics = false,
    },

    vendors = {
      groq = {
        __inherited_from = "openai",
        api_key_name = "XAI_API_KEY",
        endpoint = "https://api.groq.com/openai/v1",
        model = "qwen/qwen3.6-8b",
      },
    },
  },
}
