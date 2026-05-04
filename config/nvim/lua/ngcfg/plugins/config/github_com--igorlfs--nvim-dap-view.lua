---@type NgPackPluginConfigModule
local M = {}

M.main = "dap-view"

---@module 'dap-view'
---@type dapview.Config
M.opts = {
  winbar = {
    show = true,
    sections = { "watches", "scopes", "exceptions", "breakpoints", "threads", "repl" },
    default_section = "scopes",
    show_keymap_hints = true,
    controls = {
      -- Closest match to nvim-dap-ui's `controls` block.
      enabled = true,
      position = "right",
      buttons = { "play", "step_into", "step_over", "step_out", "step_back", "run_last", "terminate", "disconnect" },
    },
  },

  -- nvim-dap-ui's two-panel `layouts` collapses to a single split here.
  windows = {
    size = 0.4,
    position = "right",
  },

  -- Use `]v`/`[v` to cycle sections (replaces the per-element `expand/open/...` mappings).
  -- Press `g?` inside the view for per-section keymaps.
  keymaps = {
    hover = {
      quit = "q",
      toggle = { "<CR>", "<2-LeftMouse>" },
      jump_to_parent = "[[",
      set_value = "s",
    },
    help = {
      quit = "q",
    },
    console = {
      next_session = "]s",
      prev_session = "[s",
    },
    base = {
      next_view = "]v",
      prev_view = "[v",
      jump_to_first = "[V",
      jump_to_last = "]V",
      help = "g?",
    },
  },
  icons = {
    -- collapsed = "󰅂 ",
    -- disabled = "",
    -- disconnect = "",
    -- enabled = "",
    -- expanded = "󰅀 ",
    -- filter = "󰈲",
    -- negate = " ",
    -- pause = "",
    -- play = "",
    -- run_last = "",
    -- step_back = "",
    -- step_into = "",
    -- step_out = "",
    -- step_over = "",
    -- terminate = "",
  },
  help = {
    border = "single",
  },
  virtual_text = {
    -- Control with `DapViewVirtualTextToggle`
    enabled = true,
  },
  auto_toggle = true,
}

return M
