-- gopls from PATH, maybe maosn managed (= latest stable).
local lsCmd = { "gopls" }

if vim.env.GOPLS_PATH ~= nil and vim.env.GOPLS_PATH ~= "" then
  -- Can be changed arbitrarily, maybe latest unreleased.
  lsCmd = vim.env.GOPLS_PATH
end

return {
  cmd = lsCmd,
  settings = {
    gopls = { -- https://github.com/golang/tools/blob/master/gopls/doc/settings.md
      analyses = {
        -- https://staticcheck.dev/docs/checks
        ST1003 = false,
        fieldalignment = false,
        fillreturns = true,
        nilness = true,
        nonewvars = true,
        shadow = false,
        undeclaredname = true,
        unreachable = true,
        unusedparams = true,
        unusedwrite = true,
        useany = true,
      },
      codelenses = {
        generate = true, -- show the `go generate` lens.
        regenerate_cgo = true,
        test = true,
        tidy = true,
        upgrade_dependency = true,
        vendor = true,
      },
      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
      buildFlags = { "-tags", "integration" },
      completeUnimported = true,
      diagnosticsDelay = "500ms",
      gofumpt = true,
      matcher = "Fuzzy",
      semanticTokens = true,
      staticcheck = true,
      symbolMatcher = "fuzzy",
      -- I've used for a while with this option, and found it annoying.
      -- Great feature tho.
      usePlaceholders = false,
    },
  },
}
