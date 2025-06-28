return {
  "folke/persistence.nvim",
  event = "BufReadPre",
  opts = {
    options = {
      "buffers",
      "curdir",
      "resize",
      "tabpages",
      "terminal",
      "winpos",
      "winsize",
    },
  },
}
