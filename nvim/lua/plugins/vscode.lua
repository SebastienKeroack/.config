return {
  {
    "Mofiqul/vscode.nvim",
    priority = 1000,
    opts = {
      style = vim.o.background,
      transparent = false,
      italic_comments = true,
      underline_links = true,
      disable_nvimtree_bg = true,
      terminal_colors = true,
    },
    keys = {
      { "<F5>", "<cmd>ToggleTheme<cr>", desc = "Toggle light/dark theme" },
    },
    init = function()
      vim.api.nvim_create_user_command("ToggleTheme", function()
        local style = vim.o.background == "dark" and "light" or "dark"
        require("vscode").setup({})
        vim.cmd.colorscheme("vscode")
        vim.notify("Switched to " .. style .. " theme")
        vim.o.background = style
      end, {})
    end,
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "vscode",
    },
  },
}
