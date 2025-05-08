return {
  root_dir = function(bufnr, on_dir)
    local root = require("func.switch_ts_ls").find_node_root_dir(bufnr)
    if root ~= nil and root ~= "" then
      on_dir(root)
    end
  end,
}
