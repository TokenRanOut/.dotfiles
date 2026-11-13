vim.opt.number = true
vim.opt.signcolumn = "yes"
vim.opt.undofile = true
vim.opt.scrolloff = 5
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99

require("config.lsp")
require("config.lazy")
