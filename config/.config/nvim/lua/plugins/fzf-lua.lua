return {
  {
    "ibhagwan/fzf-lua",
    opts = {},
    keys = {
      { "<leader>ff", function() require("fzf-lua").files() end, desc = "Find files" },
      { "<leader>fg", function() require("fzf-lua").live_grep() end, desc = "Grep workspace" },
      { "<leader>fs", function() require("fzf-lua").lsp_document_symbols() end, desc = "Document symbols" },
      { "<leader>fS", function() require("fzf-lua").lsp_workspace_symbols() end, desc = "Workspace symbols" },
      { "<leader>fr", function() require("fzf-lua").lsp_references() end, desc = "References" },
      { "<leader>fd", function() require("fzf-lua").diagnostics_document() end, desc = "Document diagnostics" },
      { "<leader>fD", function() require("fzf-lua").diagnostics_workspace() end, desc = "Workspace diagnostics" },
    },
  },
}
