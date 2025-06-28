return {
  "justinhj/battery.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  opts = {
    update_rate_seconds = 30,
    show_status_when_no_battery = true,
    show_plugged_icon = true,
    show_unplugged_icon = true,
    show_percent = true,
    vertical_icons = true,
    multiple_battery_selection = 1,
  },
}
