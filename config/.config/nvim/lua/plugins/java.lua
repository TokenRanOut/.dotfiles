return {
  {
    "nvim-java/nvim-java",
    config = function()
      local function maven_settings_from_env()
        local options = {}
        local args = vim.split(vim.env.MAVEN_ARGS or "", "%s+", { trimempty = true })

        for index, argument in ipairs(args) do
          local next_argument = args[index + 1]
          if argument == "-s" or argument == "--settings" then
            options.user_settings = next_argument
          elseif argument:match("^%-%-settings=") then
            options.user_settings = argument:sub(#"--settings=" + 1)
          elseif argument == "-gs" or argument == "--global-settings" then
            options.global_settings = next_argument
          elseif argument:match("^%-%-global%-settings=") then
            options.global_settings = argument:sub(#"--global-settings=" + 1)
          elseif argument == "-o" or argument == "--offline" then
            options.offline = true
          elseif argument == "-U" or argument == "--update-snapshots" then
            options.update_snapshots = true
          end
        end

        return options
      end

      local function java_home(version)
        local result = vim.system({ "/usr/libexec/java_home", "-v", version }, { text = true }):wait()
        if result.code == 0 then
          return vim.trim(result.stdout)
        end
      end

      local runtimes = {}
      for _, version in ipairs({ "1.8", "11", "17", "21" }) do
        local path = java_home(version)
        if path then
          local result = vim.system({ path .. "/bin/java", "-XshowSettings:properties", "-version" }, { text = true }):wait()
          local actual_version = result.stderr:match("java%.specification%.version = ([%d%.]+)")
          if actual_version == version then
            table.insert(runtimes, {
              name = "JavaSE-" .. version,
              path = path,
              default = version == "21",
            })
          end
        end
      end

      local jdk21 = java_home("21")
      if jdk21 then
        -- Spring Boot LS requires a modern JDK; this only affects Neovim's LSP process.
        vim.env.JAVA_HOME = jdk21
      end

      local maven = maven_settings_from_env()
      require("java").setup()
      vim.lsp.config("jdtls", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
        settings = {
          java = {
            configuration = {
              runtimes = runtimes,
              maven = {
                userSettings = maven.user_settings,
                globalSettings = maven.global_settings,
              },
            },
            import = {
              maven = {
                offline = {
                  enabled = maven.offline,
                },
              },
            },
            maven = {
              updateSnapshots = maven.update_snapshots,
            },
          },
        },
      })
      vim.lsp.enable("jdtls")

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(event)
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if not client or client.name ~= "jdtls" then
            return
          end

          local map = function(mode, keys, action, description)
            vim.keymap.set(mode, keys, action, { buffer = event.buf, desc = description })
          end

          map("n", "<leader>jb", "<cmd>JavaBuildBuildWorkspace<cr>", "Build Java workspace")
          map("n", "<leader>jc", "<cmd>JavaBuildCleanWorkspace<cr>", "Clean Java workspace")
          map("n", "<leader>jo", function()
            vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" } }, apply = true })
          end, "Organize imports")
          map("n", "<leader>jr", "<cmd>JavaRunnerRunMain<cr>", "Run Java main")
          map("n", "<leader>jx", "<cmd>JavaRunnerStopMain<cr>", "Stop Java main")
          map("n", "<leader>jl", "<cmd>JavaRunnerToggleLogs<cr>", "Toggle Java runner logs")
          map("n", "<leader>jv", "<cmd>JavaSettingsChangeRuntime<cr>", "Change Java runtime")

          map("n", "<leader>tt", "<cmd>JavaTestRunCurrentMethod<cr>", "Run Java test method")
          map("n", "<leader>tT", "<cmd>JavaTestRunCurrentClass<cr>", "Run Java test class")
          map("n", "<leader>td", "<cmd>JavaTestDebugCurrentMethod<cr>", "Debug Java test method")
          map("n", "<leader>tD", "<cmd>JavaTestDebugCurrentClass<cr>", "Debug Java test class")
          map("n", "<leader>ta", "<cmd>JavaTestRunAllTests<cr>", "Run all Java tests")
          map("n", "<leader>tr", "<cmd>JavaTestViewLastReport<cr>", "View Java test report")

          map({ "n", "v" }, "<leader>je", "<cmd>JavaRefactorExtractVariable<cr>", "Extract variable")
          map({ "n", "v" }, "<leader>jE", "<cmd>JavaRefactorExtractVariableAllOccurrence<cr>", "Extract all variables")
          map({ "n", "v" }, "<leader>jk", "<cmd>JavaRefactorExtractConstant<cr>", "Extract constant")
          map({ "n", "v" }, "<leader>jm", "<cmd>JavaRefactorExtractMethod<cr>", "Extract method")
          map({ "n", "v" }, "<leader>jf", "<cmd>JavaRefactorExtractField<cr>", "Extract field")
        end,
      })
    end,
  },
}
