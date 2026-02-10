local M = {}

--- Open a file in the current Neovim instance and ensure it's loaded.
---@param filepath string
---@param timeout_ms? number (default 5000)
---@return number bufnr
local function open_file(filepath, timeout_ms)
  timeout_ms = timeout_ms or 5000
  local bufnr = vim.fn.bufadd(filepath)
  vim.fn.bufload(bufnr)
  -- Fire autocmds so LSP attaches
  vim.api.nvim_buf_call(bufnr, function()
    vim.api.nvim_exec_autocmds("BufReadPost", { buffer = bufnr })
    vim.api.nvim_exec_autocmds("FileType", { buffer = bufnr })
  end)
  return bufnr
end

--- Wait for an LSP client to attach to the buffer.
---@param bufnr number
---@param timeout_ms? number (default 10000)
---@return boolean
local function wait_for_client(bufnr, timeout_ms)
  timeout_ms = timeout_ms or 10000
  local interval = 100
  local elapsed = 0
  while elapsed < timeout_ms do
    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    if #clients > 0 then
      return true
    end
    vim.wait(interval, function() return false end)
    elapsed = elapsed + interval
  end
  return false
end

--- Make a synchronous LSP request.
---@param bufnr number
---@param method string
---@param params table
---@param timeout_ms? number
---@return table|nil results
---@return string|nil err
local function lsp_request(bufnr, method, params, timeout_ms)
  timeout_ms = timeout_ms or 5000
  local results = vim.lsp.buf_request_sync(bufnr, method, params, timeout_ms)
  if not results or vim.tbl_isempty(results) then
    return nil, "no response from LSP server"
  end
  return results, nil
end

--- Normalize an LSP location to a simple table.
---@param loc table
---@return table
local function normalize_location(loc)
  local uri = loc.uri or loc.targetUri
  local range = loc.range or loc.targetSelectionRange or loc.targetRange
  local filename = uri and vim.uri_to_fname(uri) or ""
  local line = 0
  local col = 0
  if range and range.start then
    line = range.start.line
    col = range.start.character
  end
  return { filename = filename, line = line, col = col }
end

--- Extract results from LSP response, handling multiple clients.
---@param results table
---@return table[]
local function extract_lsp_results(results)
  local items = {}
  for _, res in pairs(results) do
    if res.result then
      if vim.islist(res.result) then
        for _, item in ipairs(res.result) do
          table.insert(items, item)
        end
      else
        table.insert(items, res.result)
      end
    end
  end
  return items
end

function M.get_definition(filepath, line, col)
  local bufnr = open_file(filepath)
  if not wait_for_client(bufnr) then
    return { ok = false, error = "no LSP client attached" }
  end

  local params = {
    textDocument = { uri = vim.uri_from_fname(filepath) },
    position = { line = line, character = col },
  }

  local results, err = lsp_request(bufnr, "textDocument/definition", params)
  if err then
    return { ok = false, error = err }
  end

  local items = extract_lsp_results(results)
  local locations = {}
  for _, item in ipairs(items) do
    table.insert(locations, normalize_location(item))
  end

  return { ok = true, result = locations }
end

function M.get_references(filepath, line, col)
  local bufnr = open_file(filepath)
  if not wait_for_client(bufnr) then
    return { ok = false, error = "no LSP client attached" }
  end

  local params = {
    textDocument = { uri = vim.uri_from_fname(filepath) },
    position = { line = line, character = col },
    context = { includeDeclaration = true },
  }

  local results, err = lsp_request(bufnr, "textDocument/references", params)
  if err then
    return { ok = false, error = err }
  end

  local items = extract_lsp_results(results)
  local locations = {}
  for _, item in ipairs(items) do
    table.insert(locations, normalize_location(item))
  end

  return { ok = true, result = locations }
end

function M.get_hover(filepath, line, col)
  local bufnr = open_file(filepath)
  if not wait_for_client(bufnr) then
    return { ok = false, error = "no LSP client attached" }
  end

  local params = {
    textDocument = { uri = vim.uri_from_fname(filepath) },
    position = { line = line, character = col },
  }

  local results, err = lsp_request(bufnr, "textDocument/hover", params)
  if err then
    return { ok = false, error = err }
  end

  local items = extract_lsp_results(results)
  if #items == 0 then
    return { ok = true, result = "" }
  end

  -- Extract markdown content from hover result
  local hover = items[1]
  local content = ""
  if type(hover) == "table" and hover.contents then
    if type(hover.contents) == "string" then
      content = hover.contents
    elseif type(hover.contents) == "table" then
      if hover.contents.value then
        content = hover.contents.value
      elseif hover.contents.kind then
        content = hover.contents.value or ""
      end
    end
  end

  return { ok = true, result = content }
end

function M.get_document_symbols(filepath)
  local bufnr = open_file(filepath)
  if not wait_for_client(bufnr) then
    return { ok = false, error = "no LSP client attached" }
  end

  local params = {
    textDocument = { uri = vim.uri_from_fname(filepath) },
  }

  local results, err = lsp_request(bufnr, "textDocument/documentSymbol", params)
  if err then
    return { ok = false, error = err }
  end

  local items = extract_lsp_results(results)

  -- Recursively flatten symbols with string-keyed tables
  local function flatten_symbols(symbols, prefix)
    prefix = prefix or ""
    local flat = {}
    for _, sym in ipairs(symbols) do
      local name = prefix ~= "" and (prefix .. "." .. sym.name) or sym.name
      local range = sym.range or (sym.location and sym.location.range)
      local start_line = range and range.start and range.start.line or 0
      local end_line = range and range["end"] and range["end"].line or 0
      table.insert(flat, {
        name = name,
        kind = sym.kind,
        start_line = start_line,
        end_line = end_line,
      })
      if sym.children then
        local child_symbols = flatten_symbols(sym.children, name)
        for _, cs in ipairs(child_symbols) do
          table.insert(flat, cs)
        end
      end
    end
    return flat
  end

  return { ok = true, result = flatten_symbols(items) }
end

function M.get_diagnostics(filepath)
  local bufnr = open_file(filepath)
  -- Wait briefly for diagnostics to populate
  if not wait_for_client(bufnr) then
    return { ok = false, error = "no LSP client attached" }
  end
  -- Give LSP a moment to send diagnostics
  vim.wait(500, function() return false end)

  local diags = vim.diagnostic.get(bufnr)
  local result = {}
  for _, d in ipairs(diags) do
    table.insert(result, {
      line = d.lnum,
      col = d.col,
      severity = d.severity,
      message = d.message,
      source = d.source or "",
    })
  end

  return { ok = true, result = result }
end

function M.health()
  local bufs = vim.api.nvim_list_bufs()
  local loaded_bufs = 0
  for _, b in ipairs(bufs) do
    if vim.api.nvim_buf_is_loaded(b) then
      loaded_bufs = loaded_bufs + 1
    end
  end

  local clients = vim.lsp.get_clients()
  local client_info = {}
  for _, c in ipairs(clients) do
    table.insert(client_info, {
      id = c.id,
      name = c.name,
      root_dir = c.config and c.config.root_dir or "",
    })
  end

  return {
    ok = true,
    result = {
      pid = vim.fn.getpid(),
      loaded_buffers = loaded_bufs,
      lsp_clients = client_info,
    },
  }
end

return M
