local M = {}

M.insert_unique = function(dst, src)
  if not dst then
    dst = {}
  end
  assert(vim.islist(dst), "dst is not list")
  local has = {}
  for _, val in ipairs(dst) do
    has[val] = true
  end
  for _, val in ipairs(src) do
    if not has[val] then
      table.insert(dst, val)
      has[val] = true
    end
  end
  return dst
end

return M
