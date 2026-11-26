---@type NgPackPluginConfigModule
local M = {}

M.opts = {
  mappings = true,
}

-- setup() enables lean.nvim's own `leanls` config (`lake serve` from the elan
-- toolchain), so no Lean server is listed in ngcfg.config.ls.
-- The latest tag (v2026.4.1) does not configure itself from vim.g.lean_config
-- the way upstream's README describes for newer revisions; the explicit call
-- is required.
M.config = function(_, opts)
  require("lean").setup(opts)
end

return M
