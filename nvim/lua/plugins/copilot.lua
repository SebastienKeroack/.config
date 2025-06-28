return {
  -- Completion
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      opts.sources.default = vim.tbl_filter(function(name)
        return name ~= "copilot"
      end, opts.sources.default)
    end,
  },

  -- GitHub Copilot
  {
    "zbirenbaum/copilot.lua",
    opts = {
      suggestion = {
        enabled = true,
        auto_trigger = false,
      },
      panel = { enabled = true },
    },
  },

  -- GitHub Copilot Chat
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    opts = {
      chat_autocomplete = true,
    },
  },
}
