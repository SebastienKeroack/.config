return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "justinhj/battery.nvim" },
  opts = function(_, opts)
    table.insert(opts.sections.lualine_y, {
      function()
        return require("battery").get_status_line()
      end,
      cond = function()
        return package.loaded["battery"] ~= nil
      end,
      color = function()
        return { fg = Snacks.util.color("Constant") }
      end,
    })
  end,
}
