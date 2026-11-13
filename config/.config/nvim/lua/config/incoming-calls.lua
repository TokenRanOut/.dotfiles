local M = {}

local function show_calls(locations)
  local items, seen = {}, {}
  for _, location in ipairs(locations) do
    local item = vim.lsp.util.locations_to_items({ location.value }, location.encoding)[1]
    local key = table.concat({ item.filename, item.lnum, item.col }, ":")
    if not seen[key] then
      seen[key] = true
      item.text = location.name
      item.is_test = item.filename:match("/src/test/") ~= nil
        or item.filename:match("/src/integrationTest/") ~= nil
        or item.filename:match("/tests?/") ~= nil
      items[#items + 1] = item
    end
  end

  if #items == 0 then
    vim.notify("未找到调用方", vim.log.levels.INFO)
    return
  end

  table.sort(items, function(a, b)
    if a.is_test ~= b.is_test then return not a.is_test end
    if a.filename ~= b.filename then return a.filename < b.filename end
    if a.lnum ~= b.lnum then return a.lnum < b.lnum end
    return a.col < b.col
  end)

  local entries = {}
  for _, item in ipairs(items) do
    entries[#entries + 1] = string.format("%s:%d:%d: [%s] %s",
      vim.fn.fnamemodify(item.filename, ":."), item.lnum, item.col,
      item.is_test and "测试" or "源码", item.text)
  end

  local fzf = require("fzf-lua")
  fzf.fzf_exec(entries, {
    prompt = "调用方> ",
    previewer = "builtin",
    winopts = { preview = { hidden = false } },
    fzf_opts = { ["--no-sort"] = true },
    actions = { ["enter"] = fzf.actions.file_edit },
  })
end

function M.open()
  local bufnr = vim.api.nvim_get_current_buf()
  local winid = vim.api.nvim_get_current_win()
  vim.lsp.buf_request_all(bufnr, "textDocument/prepareCallHierarchy", function(client)
    return vim.lsp.util.make_position_params(winid, client.offset_encoding)
  end, function(responses)
    local requests = {}
    for client_id, response in pairs(responses) do
      local client = vim.lsp.get_client_by_id(client_id)
      if response.err then
        vim.notify(response.err.message, vim.log.levels.WARN)
      elseif client then
        for _, item in ipairs(response.result or {}) do
          requests[#requests + 1] = { client = client, item = item }
        end
      end
    end

    local remaining, locations = #requests, {}
    if remaining == 0 then
      vim.notify("未找到可查询调用方的符号", vim.log.levels.INFO)
      return
    end

    local function finish()
      remaining = remaining - 1
      if remaining == 0 then show_calls(locations) end
    end

    for _, request in ipairs(requests) do
      local client = request.client
      local sent = client:request("callHierarchy/incomingCalls", { item = request.item }, function(err, calls)
        if err then
          vim.notify(err.message, vim.log.levels.WARN)
        else
          for _, call in ipairs(calls or {}) do
            for _, range in ipairs(call.fromRanges) do
              locations[#locations + 1] = {
                value = { uri = call.from.uri, range = range },
                encoding = client.offset_encoding,
                name = call.from.name,
              }
            end
          end
        end
        finish()
      end, bufnr)
      if not sent then
        vim.notify("调用方请求发送失败：" .. client.name, vim.log.levels.WARN)
        finish()
      end
    end
  end)
end

return M
