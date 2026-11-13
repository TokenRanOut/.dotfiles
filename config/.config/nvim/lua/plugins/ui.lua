return {
  {
    "j-hui/fidget.nvim",
    opts = {},
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      spec = {
        { "<leader>c", group = "代码操作" },
        { "<leader>d", group = "调试" },
        { "<leader>f", group = "搜索" },
        { "<leader>j", group = "Java / Kotlin" },
        { "<leader>t", group = "测试与提示" },
        { "<leader>u", group = "界面" },
      },
    },
  },
  {
    "tris203/precognition.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "<leader>up", function() require("precognition").toggle() end, desc = "切换移动提示" },
    },
  },
}
