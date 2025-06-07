local M = {}

M.tool = {}

M.dap = function()
  local dap = require "dap"
  -- Node.js debugging
  dap.adapters.node2 = {
    type = "executable",
    command = "node",
    args = { vim.fn.stdpath "data" .. "/mason/packages/node-debug2-adapter/out/src/nodeDebug.js" },
  }

  dap.configurations.javascript = {
    {
      name = "Launch",
      type = "node2",
      request = "launch",
      program = "${file}",
      cwd = vim.fn.getcwd(),
      sourceMaps = true,
      protocol = "inspector",
      console = "integratedTerminal",
    },
    {
      name = "Attach to process",
      type = "node2",
      request = "attach",
      processId = require("dap.utils").pick_process,
    },
  }

  dap.configurations.typescript = dap.configurations.javascript
end

return M
