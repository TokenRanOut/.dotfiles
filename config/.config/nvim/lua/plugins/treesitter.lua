return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local treesitter = require("nvim-treesitter")
      treesitter.setup()
      treesitter.install({ "java", "lua", "vim", "vimdoc", "query", "json", "yaml", "xml", "bash" })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "java", "lua", "vim", "json", "yaml", "xml", "sh" },
        callback = function()
          vim.treesitter.start()
          vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
          vim.wo.foldmethod = "expr"
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },
}
