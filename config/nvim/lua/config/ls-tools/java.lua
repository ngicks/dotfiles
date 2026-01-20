local M = {}

M.tool = {
  "jdtls",
  "java-debug-adapter",
  "java-test",
}

M.dap = function()
  local dap = require "dap"

  -- Java debugging configuration
  dap.adapters.java = function(callback)
    local java_debug_adapter = vim.fn.glob(
      vim.fn.stdpath "data"
        .. "/mason/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar"
    )
    if java_debug_adapter == "" then
      vim.notify(
        "Java debug adapter not found. Install via Mason: :MasonInstall java-debug-adapter",
        vim.log.levels.ERROR
      )
      return
    end

    callback {
      type = "server",
      host = "127.0.0.1",
      port = 5005,
      executable = {
        command = "java",
        args = {
          "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005",
          "-Dlog.protocol=true",
          "-Dlog.level=ALL",
          "-jar",
          java_debug_adapter,
        },
      },
    }
  end

  dap.configurations.java = {
    {
      type = "java",
      request = "attach",
      name = "Debug (Attach) - Remote",
      hostName = "127.0.0.1",
      port = 5005,
    },
    {
      type = "java",
      request = "launch",
      name = "Debug (Launch) - Current File",
      cwd = "${workspaceFolder}",
      console = "internalConsole",
      stopOnEntry = false,
      mainClass = "",
      args = "",
    },
  }
end
return M
