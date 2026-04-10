---@alias NgPackPhase "core"|"ui"|"lazy"
---@alias NgPackOpts any

---@class NgPackPluginConfigModule
---@field init? fun(spec: NgPackSpecPlain)
---@field opts? NgPackOpts|fun(spec: NgPackSpecPlain): NgPackOpts
---@field config? boolean|fun(spec: NgPackSpecPlain, opts: NgPackOpts)
---@field main? string
---@field build? string|fun(ev: vim.api.keyset.create_autocmd.callback_args)

---@class NgPackSpecPlain: NgPackPluginConfigModule
---@field src string
---@field name? string
---@field version? vim.VersionRange|string
---@field branch? string
---@field commit? string
---@field data? any
---@field phase? NgPackPhase
---@field dep? string[] Full src URLs of dependent plugins.
