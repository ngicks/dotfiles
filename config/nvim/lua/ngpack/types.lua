---@alias NgPackPhase "core"|"ui"|"lazy"
---@alias NgPackOpts any

---@class NgPackPluginConfigModule
---@field init? fun(spec: NgPackSpecPlain)
---@field opts? NgPackOpts|fun(spec: NgPackSpecPlain): NgPackOpts
---@field config? boolean|fun(spec: NgPackSpecPlain, opts: NgPackOpts)
---@field main? string
---@field build? string|fun(ev: vim.api.keyset.create_autocmd.callback_args)

---@class NgPackSpecPlain: NgPackPluginConfigModule
---@field src string src URL
---@field name? string name of module. will be used as a directory name under packpath.
---@field version? vim.VersionRange|string version range, revision(git commit hash) or branch name.
---@field data? any Any arbitrary user data tied to NgPackSpecPlain as well as vim.pack.Spec.
---@field phase? NgPackPhase
---@field dep? string[] Full src URLs of dependent plugins.
