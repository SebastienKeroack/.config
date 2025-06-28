-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Env settings
vim.env.USER = "Sebastien Keroack"

-- Shell settings
vim.opt.shell = "pwsh"
vim.opt.shellcmdflag = "-NoLogo -ExecutionPolicy RemoteSigned -Command"

-- Basic Neovim settings
vim.opt.spelllang = { "en" }
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.wrap = false

-- Global variables
vim.g.autoformat = true
vim.g.ai_cmp = false
vim.g.root_spec = { "lsp", { ".git", "lua" }, "cwd" }
