local M = {}

-- return the root directory for fname if **it is a deno project**
-- Otherwise nil.
--
-- Rules:
-- 1. presence of deno.json[c] determines it is a deno project:
-- deno has package.json support, which means mixes of these *.json
-- should indicate the project is in transition from node to deno.
-- 2. presence of package.json[c] determines it is a node project.
-- 3. then it is a deno oriented single typescript file:
-- I have a strong option that every single-typescript file must be run by deno.
--
-- Yes you can check buffer contents and see if it has lines that is accessing to Deno global object.
-- But you know that there's fair chance of false-positive.
-- Multi-runtime projects may check runtime types by presence of certain objects.
-- That's why bascially you do not want to do that.
--
-- I know there's alot more javascript runtime out there like Bun, cloudflare edge something something, etc.
-- TODO: expand if I have to do that?
local deno_root_dir = function(fname)
  local droot = vim.fs.root(fname, { "deno.json", "deno.jsonc" })
  if droot then
    return droot
  end
  if vim.fs.root(fname, { "package.json", "package.jsonc" }) then
    return nil
  end
  return vim.fn.getcwd() -- Use the current working directory
end

-- returns the root directory for fname if it is pointing to node.js typescript/javascript.
-- It is an opposite of deno_root_dir
local node_root_dir = function(fname)
  if deno_root_dir(fname) then
    return nil
  end
  return vim.fs.root(fname, { "package.json", "package.jsonc" })
end

-- switches lsp client for typescript.
-- If active_if_deno is truthy value then stops the given client if
-- buffer is pointing file that deno_root_dir returns non nil value.
-- and vice verca.
--
-- This function is useful because if multiple clients are activated
-- simultaneously for a file, it can confuse readers.
-- The typescript is confusion format that it has multiple lsp for it.
-- This setup activates only either of ts_ls or denols.
local switch_ts_lsp_client = function(active_if_deno, default_on_attach)
  return function(client, bufnr)
    local is_deno_root = (deno_root_dir(vim.api.nvim_buf_get_name(bufnr)) ~= nil)
    if active_if_deno and is_deno_root then
      default_on_attach(client, bufnr)
    elseif not active_if_deno and not is_deno_root then
      default_on_attach(client, bufnr)
    else
      client.stop(true)
    end
  end
end

local function virtual_text_document(params)
  local bufnr = params.buf
  local actual_path = params.match:sub(1)

  local clients = vim.lsp.get_clients { name = "denols" }
  if #clients == 0 then
    return
  end

  local client = clients[1]
  local method = "deno/virtualTextDocument"
  local req_params = { textDocument = { uri = actual_path } }
  local response = client.request_sync(method, req_params, 2000, 0)
  if not response or type(response.result) ~= "string" then
    return
  end

  local lines = vim.split(response.result, "\n")
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_set_option_value("readonly", true, { buf = bufnr })
  vim.api.nvim_set_option_value("modified", false, { buf = bufnr })
  vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
  vim.api.nvim_buf_set_name(bufnr, actual_path)
  vim.lsp.buf_attach_client(bufnr, client.id)

  local filetype = "typescript"
  if actual_path:sub(-3) == ".md" then
    filetype = "markdown"
  end
  vim.api.nvim_set_option_value("filetype", filetype, { buf = bufnr })
end

M.config = function(servers, defaults)
  servers.ts_ls = {
    root_dir = node_root_dir,
    on_attach = switch_ts_lsp_client(false, defaults.on_attach),
  }
  servers.denols = {
    root_dir = deno_root_dir,
    on_attach = switch_ts_lsp_client(true, defaults.on_attach),
    init_options = {
      lint = true,
      unstable = true,
      suggest = {
        imports = {
          hosts = {
            ["https://deno.land"] = true,
            ["https://cdn.nest.land"] = true,
            ["https://crux.land"] = true,
          },
        },
      },
    },
  }
end

M.post_setup = function()
  vim.api.nvim_create_autocmd({ "BufReadCmd" }, {
    pattern = { "deno:/*" },
    callback = virtual_text_document,
  })
end

return M
