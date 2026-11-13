return {
  {
    "AlexandrosAlexiou/intellij-server.nvim",
    ft = { "java", "kotlin" },
    dependencies = { "mfussenegger/nvim-dap", "rcarriga/nvim-dap-ui", "saghen/blink.cmp" },
    opts = function()
      return {
        connection = {
          mode = "socket",
          host = "127.0.0.1",
          port = 9999,
          autostart_server = false,
        },
        capabilities = require("blink.cmp").get_lsp_capabilities(),
        folding = { enabled = false },
        root_dir = function(bufnr)
          return vim.fs.root(bufnr, ".git")
            or vim.fs.root(bufnr, { "pom.xml", "settings.gradle", "settings.gradle.kts", "build.gradle", "build.gradle.kts" })
        end,
        on_attach = function(_, bufnr)
          local map = function(mode, keys, action, description)
            vim.keymap.set(mode, keys, action, { buffer = bufnr, desc = description })
          end

          map("n", "gS", function()
            vim.lsp.buf.typehierarchy("supertypes")
          end, "Go to supertype")

          map("n", "<leader>jo", function()
            vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" } }, apply = true })
          end, "Organize imports")
          map("n", "<leader>jr", "<cmd>IntellijServerRun<cr>", "Run Java or Kotlin main")
          map("n", "<leader>jd", "<cmd>IntellijServerRun!<cr>", "Debug Java or Kotlin main")
          map("n", "<leader>jx", function() require("dap").terminate() end, "Stop Java or Kotlin program")
          map("n", "<leader>jl", "<cmd>IntellijServerBuildLog<cr>", "View build and program logs")

          map("n", "<leader>tt", "<cmd>IntellijServerTest cursor<cr>", "Run test at cursor")
          map("n", "<leader>tT", "<cmd>IntellijServerTest file<cr>", "Run tests in file")
          map("n", "<leader>td", "<cmd>IntellijServerTest! cursor<cr>", "Debug test at cursor")
          map("n", "<leader>tD", "<cmd>IntellijServerTest! file<cr>", "Debug tests in file")
          map("n", "<leader>tm", "<cmd>IntellijServerTest module<cr>", "Run tests in module")
          map({ "n", "v" }, "<leader>je", function()
            vim.lsp.buf.code_action({ context = { only = { "refactor.extract" } } })
          end, "Extract refactoring")
        end,
      }
    end,
  },
}
