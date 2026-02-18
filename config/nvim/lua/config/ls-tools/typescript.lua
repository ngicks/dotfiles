local M = {}

M.dap = function()
  local dap = require "dap"

  -- Node.js debugging via vscode-js-debug (pwa-node)
  dap.adapters["pwa-node"] = {
    type = "server",
    host = "localhost",
    port = "${port}",
    executable = {
      command = "js-debug", -- from nixpkgs vscode-js-debug
      args = { "${port}" },
    },
  }

  dap.configurations.javascript = {
    {
      name = "Launch",
      type = "pwa-node",
      request = "launch",
      program = "${file}",
      cwd = vim.fn.getcwd(),
      sourceMaps = true,
      console = "integratedTerminal",
    },
    {
      name = "Attach to process",
      type = "pwa-node",
      request = "attach",
      processId = require("dap.utils").pick_process,
    },
  }

  dap.configurations.typescript = vim.list_extend(vim.deepcopy(dap.configurations.javascript), {
    {
      name = "Deno: Launch",
      type = "pwa-node",
      request = "launch",
      runtimeExecutable = "deno",
      runtimeArgs = { "run", "--inspect-brk", "--allow-all" },
      program = "${file}",
      cwd = vim.fn.getcwd(),
      attachSimplePort = 9229,
    },
  })
end

return M
