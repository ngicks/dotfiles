vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function(args)
    local clients = vim.lsp.get_clients { name = "gopls" }
    if #clients == 0 then
      return
    end

    local client = clients[1]

    local pos_encoding = vim.lsp.get_client_by_id(client.id).offset_encoding or "utf-16"

    local params = vim.lsp.util.make_range_params(vim.fn.bufwinid(args.buf), pos_encoding)
    params = vim.tbl_deep_extend("force", params, { context = { only = { "source.organizeImports" } } })

    -- buf_request_sync defaults to a 1000ms timeout. Depending on your
    -- machine and codebase, you may want longer. Add an additional
    -- argument after params if you find that you have to write the file
    -- twice for changes to be saved.
    -- E.g., vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 3000)
    local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params)
    for cid, res in pairs(result or {}) do
      for _, r in pairs(res.result or {}) do
        if r.edit then
          local enc = (vim.lsp.get_client_by_id(cid) or {}).offset_encoding or "utf-16"
          vim.lsp.util.apply_workspace_edit(r.edit, enc)
        end
      end
    end
    vim.lsp.buf.format { async = false }
  end,
})

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
        ST1003 = true,
        fieldalignment = false,
        fillreturns = true,
        nilness = true,
        nonewvars = true,
        shadow = true,
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
