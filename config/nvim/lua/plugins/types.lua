---@alias NgPluginPhase "core"|"ui"|"ondemand"
---@alias NgPluginOpts any
---@alias NgPluginVersion any
---@alias NgPluginBuildEvent vim.api.keyset.create_autocmd.callback_args

---@class NgPackSpec
---@field src string
---@field name string
---@field version? NgPluginVersion

---@class NgPluginConfigModule
---@field init? fun()
---@field opts? NgPluginOpts|fun(spec: NgPluginSpec): NgPluginOpts
---@field config? boolean|fun(spec: NgPluginSpec, opts: NgPluginOpts)
---@field main? string
---@field build? string|fun(ev: NgPluginBuildEvent)

---@class NgPluginSpec: NgPluginConfigModule
---@field src string
---@field name? string
---@field phase? NgPluginPhase
---@field version? NgPluginVersion|string
---@field branch? string
---@field commit? string
---@field _pack_spec? NgPackSpec
---@field _loaded? boolean
---@field _initialized? boolean
---@field _configured? boolean

---@class NgPluginSpecDefaults: NgPluginConfigModule
---@field version NgPluginVersion|string
