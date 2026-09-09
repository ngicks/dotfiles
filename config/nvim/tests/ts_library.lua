-- Run from the repository root: nvim --headless -u NONE -i NONE -l config/nvim/tests/ts_library.lua
vim.opt.runtimepath:prepend "config/nvim"
local tmp = vim.fn.tempname()
vim.fn.mkdir(tmp .. "/compiler", "p")
vim.fn.writefile({}, tmp .. "/compiler/lib.d.ts")
vim.fn.writefile({ "#!/bin/sh" }, tmp .. "/compiler/tsgo")
vim.fn.setfperm(tmp .. "/compiler/tsgo", "rwx------")

local clients, attached, requests = {}, {}, {}
local discoveries = 0
vim.system = function(cmd)
  assert(vim.deep_equal(cmd, { "deno", "info", "--json" }))
  discoveries = discoveries + 1
  return {
    wait = function()
      return { code = 0, stdout = vim.json.encode { npmCache = tmp .. "/cache/npm" } }
    end,
  }
end
local executable = vim.fn.executable
vim.fn.executable = function(cmd)
  return cmd == "deno" and 1 or executable(cmd)
end
vim.lsp.get_clients = function(filter)
  filter = filter or {}
  return vim.tbl_filter(function(client)
    return not client.stopped
      and (not filter.name or client.name == filter.name)
      and (not filter.bufnr or (attached[filter.bufnr] or {})[client.id])
  end, clients)
end
vim.lsp.get_client_by_id = function(id)
  for _, client in ipairs(clients) do
    if client.id == id then
      return client
    end
  end
end
vim.lsp.buf_attach_client = function(buf, id)
  attached[buf] = attached[buf] or {}
  attached[buf][id] = true
  return true
end
vim.lsp.buf_detach_client = function(buf, id)
  attached[buf][id] = nil
end

local library = require "ngcfg.func.ts_library"
local function client(id, name, root)
  local c = {
    id = id,
    name = name,
    root_dir = root,
    config = { cmd = { tmp .. "/compiler/tsgo" } },
    is_stopped = function(self)
      return self.stopped
    end,
    rpc = {
      request = function(method, params, callback, notify)
        requests[id] = { method = method, params = params, callback = callback, notify = notify }
        return true, 42
      end,
    },
  }
  table.insert(clients, c)
  library.track(c)
  return c
end
local node = client(1, "tsgo", tmp .. "/project")
local deno = client(2, "denols", tmp .. "/project/nested")
assert(not library.is_library_file(tmp .. "/project/lib.custom.d.ts"))
assert(library.is_library_file(tmp .. "/project/node_modules/pkg/index.d.ts"))
assert(library.is_library_file(tmp .. "/cache/npm/pkg/index.d.ts"))
assert(not library.is_library_file(tmp .. "/cache/npm-other/index.d.ts"))
assert(library.is_library_file(tmp .. "/compiler/lib.es5.d.ts"))
assert(library.is_library_file "deno:/asset/lib.deno.ns.d.ts")
assert(library.is_library_file "bundled:///libs/lib.es5.d.ts")
assert(discoveries == 1)

local target = tmp .. "/project/nested/node_modules/pkg/index.d.ts"
assert(library.find_client(target) == deno)
local buf = vim.fn.bufadd(target)
assert(library.attach_if_library("tsgo", buf))
assert(not attached[buf])
assert(library.attach_if_library("denols", buf))
assert(attached[buf][deno.id])

local result = { { targetUri = vim.uri_from_fname(target), targetRange = {} } }
local called = false
local success, request_id = node.rpc.request("textDocument/definition", {}, function(err, response, id)
  assert(not err and response == result and id == 42)
  assert(library.find_client(target) == node)
  called = true
end)
assert(success and request_id == 42)
requests[1].callback(nil, result, 42)
assert(called)
library.attach_if_library("denols", buf)
library.attach_if_library("tsgo", buf)
assert(attached[buf][node.id] and not attached[buf][deno.id])

-- A jump into an already loaded library must replace the previous owner too.
vim.fn.bufload(buf)
deno.rpc.request("textDocument/definition", {}, function() end)
requests[2].callback(nil, { uri = vim.uri_from_fname(target), range = {} })
assert(attached[buf][deno.id] and not attached[buf][node.id])
node.rpc.request("textDocument/definition", {}, function() end)
requests[1].callback(nil, result)
assert(attached[buf][node.id] and not attached[buf][deno.id])

local virtual = "deno:/asset/lib.deno.ns.d.ts"
deno.rpc.request("textDocument/typeDefinition", {}, function() end)
requests[2].callback(nil, { uri = virtual, range = {} })
assert(library.find_client(virtual) == deno)

-- Normal source locations must still use project root detection.
local source = tmp .. "/elsewhere/lib.project.d.ts"
node.rpc.request("textDocument/typeDefinition", {}, function() end)
requests[1].callback(nil, { uri = vim.uri_from_fname(source), range = {} })
assert(not library.find_client(source))

-- Preserve callbacks and transport return values for unrelated requests and errors.
local callback = function() end
local notify = function() end
node.rpc.request("textDocument/hover", {}, callback, notify)
assert(requests[1].callback == callback and requests[1].notify == notify)
node.rpc.request("textDocument/definition", {}, function(err)
  assert(err.code == -1)
end)
requests[1].callback({ code = -1 }, nil)
node.stopped = true
assert(library.find_client(target) == deno)

client(3, "tsgo", deno.root_dir)
assert(not library.find_client(target))
assert(not library.find_client(tmp .. "/cache/npm/pkg/index.d.ts"))
clients = {}

-- Failed discovery must leave ordinary source files eligible for root detection.
package.loaded["ngcfg.func.ts_library"] = nil
vim.system = function()
  return {
    wait = function()
      return { code = 1, stdout = "invalid json" }
    end,
  }
end
local unavailable = require "ngcfg.func.ts_library"
assert(not unavailable.is_library_file(tmp .. "/project/lib.custom.d.ts"))
assert(unavailable.is_library_file(tmp .. "/node_modules/pkg/index.d.ts"))
vim.fn.delete(tmp, "rf")
print "ts_library: all checks passed"
