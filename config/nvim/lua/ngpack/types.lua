---@alias NgPackPhase "core"|"ui"|"lazy"
---@alias NgPackOpts any

---@class NgPackPluginConfigModule
---@field init? fun(spec: NgPackSpec)
---@field opts? NgPackOpts|fun(spec: NgPackSpec): NgPackOpts
---@field config? boolean|fun(spec: NgPackSpec, opts: NgPackOpts)
---@field main? string
---@field enable? boolean|fun(spec: NgPackSpec): boolean when false (or returns false), the plugin is skipped: not added to vim.pack, no init/setup, no pack_changed hooks. Defaults to true.
---@field pack_changed_pre? fun(spec: NgPackSpec, data: EventDataPackChanged, ev: vim.api.keyset.create_autocmd.callback_args) invoked at "PackChangedPre"
---@field pack_changed? fun(spec: NgPackSpec, data: EventDataPackChanged, ev: vim.api.keyset.create_autocmd.callback_args) invoked at "PackChanged"

---@class NgPackSpecPlain: NgPackPluginConfigModule
---@field src string src URL
---@field name? string name of module. will be used as a directory name under packpath.
---@field version? vim.VersionRange|string version range, revision(git commit hash) or branch name.
---@field data? any Any arbitrary user data tied to NgPackSpecPlain as well as vim.pack.Spec.
---@field phase? NgPackPhase
---@field dep? string[] Full src URLs of dependent plugins. Currently unused; maybe later be used order hint.

---@class EventDataPackChanged wrapper for event data type. see https://neovim.io/doc/user/pack/#PackChangedPre
---@field active boolean whether plugin was added via vim.pack.add() to current session.
---@field kind "install"|"update"|"delete" "install"(install on disk; before loading), "update" (update already installed plugin; might be not loaded), "delete" (delete from disk).
---@field spec vim.pack.Spec plugin's specification with defaults made explicit.
---@field path string full path to plugin's directory.
