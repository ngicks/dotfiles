---@type NgPluginConfigModule
local M = {}

local configureSigns = function()
  -- Configure breakpoint signs
  vim.fn.sign_define("DapBreakpoint", {
    text = "🔴",
    texthl = "DapBreakpoint",
    linehl = "",
    numhl = "",
  })

  vim.fn.sign_define("DapBreakpointCondition", {
    text = "🟡",
    texthl = "DapBreakpointCondition",
    linehl = "",
    numhl = "",
  })

  vim.fn.sign_define("DapLogPoint", {
    text = "📝",
    texthl = "DapLogPoint",
    linehl = "",
    numhl = "",
  })

  vim.fn.sign_define("DapStopped", {
    text = "➡️",
    texthl = "DapStopped",
    linehl = "DapStoppedLine",
    numhl = "",
  })

  vim.fn.sign_define("DapBreakpointRejected", {
    text = "❌",
    texthl = "DapBreakpointRejected",
    linehl = "",
    numhl = "",
  })
end

M.config = function()
  configureSigns()

  local loaded = require("func.scan_conf_dir").load_local_dir("config/ls-tools", true)
  for _, ent in ipairs(loaded) do
    if ent.dap then
      ent.dap()
    end
  end
end

return M
