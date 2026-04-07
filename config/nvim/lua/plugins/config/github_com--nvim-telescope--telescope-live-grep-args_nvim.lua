local M = {}

M.config = function()
  local telescope = require "telescope"
  local telescope_config = require "telescope.config".values
  local lga_actions = require "telescope-live-grep-args.actions"
  local unpack = table.unpack or unpack
  local extra_glob_args = { "--hidden", "--glob", "!.git/**" }

  local function vimgrep_with_hidden()
    local args = { unpack(telescope_config.vimgrep_arguments) }
    for _, flag in ipairs(extra_glob_args) do
      table.insert(args, flag)
    end
    return args
  end

  local function hidden_args()
    return { unpack(extra_glob_args) }
  end

  telescope.setup {
    defaults = {
      vimgrep_arguments = vimgrep_with_hidden(),
    },
    extensions = {
      live_grep_args = {
        auto_quoting = true, -- enable/disable auto-quoting
        additional_args = hidden_args,
        -- define mappings, e.g.
        mappings = { -- extend mappings
          i = {
            ["<C-k>"] = lga_actions.quote_prompt(),
            ["<C-i>"] = lga_actions.quote_prompt { postfix = " --iglob " },
            -- freeze the current list and start a fuzzy search in the frozen list
            ["<C-space>"] = lga_actions.to_fuzzy_refine,
          },
        },
        -- ... also accepts theme settings, for example:
        -- theme = "dropdown", -- use dropdown theme
        -- theme = { }, -- use own theme spec
        -- layout_config = { mirror=true }, -- mirror preview pane
      },
    },
  }
  telescope.load_extension "live_grep_args"
end

return M
