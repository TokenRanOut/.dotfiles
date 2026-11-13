vim.diagnostic.config({
  severity_sort = true,
  float = { border = "rounded", source = "if_many" },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "󰅚 ",
      [vim.diagnostic.severity.WARN] = "󰀪 ",
      [vim.diagnostic.severity.INFO] = "󰋽 ",
      [vim.diagnostic.severity.HINT] = "󰌶 ",
    },
  },
  underline = true,
  update_in_insert = false,
  virtual_text = { spacing = 2, source = "if_many" },
})

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if not client then
      return
    end

    local map = function(keys, action, description, method)
      if method and not client:supports_method(method, event.buf) then
        return
      end
      vim.keymap.set("n", keys, action, { buffer = event.buf, desc = description })
    end

    map("gd", vim.lsp.buf.definition, "Go to definition", "textDocument/definition")
    map("gD", vim.lsp.buf.declaration, "Go to declaration", "textDocument/declaration")
    map("gi", vim.lsp.buf.implementation, "Go to implementation", "textDocument/implementation")
    map("gy", vim.lsp.buf.type_definition, "Go to type definition", "textDocument/typeDefinition")
    map("gC", function()
      require("config.incoming-calls").open()
    end, "查看调用方（带预览）", "textDocument/prepareCallHierarchy")
    map("K", vim.lsp.buf.hover, "Hover documentation", "textDocument/hover")
    map("<leader>ca", vim.lsp.buf.code_action, "Code action", "textDocument/codeAction")
    map("<leader>cd", vim.diagnostic.open_float, "Line diagnostics")
    map("<leader>cf", function()
      vim.lsp.buf.format({ async = true })
    end, "Format buffer", "textDocument/formatting")
    map("<leader>cr", vim.lsp.buf.rename, "Rename symbol", "textDocument/rename")
    map("[d", function()
      vim.diagnostic.jump({ count = -1, float = true })
    end, "Previous diagnostic")
    map("]d", function()
      vim.diagnostic.jump({ count = 1, float = true })
    end, "Next diagnostic")
    map("<leader>th", function()
      local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf })
      vim.lsp.inlay_hint.enable(not enabled, { bufnr = event.buf })
    end, "Toggle inlay hints", "textDocument/inlayHint")
  end,
})
