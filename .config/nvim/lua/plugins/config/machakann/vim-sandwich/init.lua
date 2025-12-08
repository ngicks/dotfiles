local M = {}

M.init = function()
  vim.g.sandwich_no_default_key_mappings = 1
  vim.g.operator_sandwich_no_default_key_mappings = 1
  vim.g.textobj_sandwich_no_default_key_mappings = 1
end

M.config = function()
  vim.cmd [[
silent! nmap <unique> <leader>sa <Plug>(sandwich-add)
silent! xmap <unique> <leader>sa <Plug>(sandwich-add)
silent! omap <unique> <leader>sa <Plug>(sandwich-add)

silent! nmap <unique> <leader>sd <Plug>(sandwich-delete)
silent! xmap <unique> <leader>sd <Plug>(sandwich-delete)
silent! nmap <unique> <leader>sdb <Plug>(sandwich-delete-auto)

silent! nmap <unique> <leader>sr <Plug>(sandwich-replace)
silent! xmap <unique> <leader>sr <Plug>(sandwich-replace)
silent! nmap <unique> <leader>srb <Plug>(sandwich-replace-auto)

if !exists('g:textobj_sandwich_no_default_key_mappings')
  silent! omap <unique> <leader>ib <Plug>(textobj-sandwich-auto-i)
  silent! xmap <unique> <leader>ib <Plug>(textobj-sandwich-auto-i)
  silent! omap <unique> <leader>ab <Plug>(textobj-sandwich-auto-a)
  silent! xmap <unique> <leader>ab <Plug>(textobj-sandwich-auto-a)

  silent! omap <unique> is <Plug>(textobj-sandwich-query-i)
  silent! xmap <unique> is <Plug>(textobj-sandwich-query-i)
  silent! omap <unique> as <Plug>(textobj-sandwich-query-a)
  silent! xmap <unique> as <Plug>(textobj-sandwich-query-a)
endif
]]
end

return M
