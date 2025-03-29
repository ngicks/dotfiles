if vim.fn.has "wsl" == 1 then
  -- on wsl, "unnamedplus" is wl-copy as discribed in :h clipboard (wsl now has $WAYLAND_DISPLAY)
  -- But somehow, wsl ubuntu 24.04.01 LTS fails to create wayland socket on the runtime dir.
  -- That effectively disables us from using that.
  -- xsel worked out excellently on my home and work environment.
  -- I assume it works for most of you.
  vim.g.clipboard = {
    name = "xsel",
    copy = {
      ["+"] = "xsel -bi",
      ["*"] = "xsel -bi",
    },
    paste = {
      ["+"] = function()
        return vim.fn.systemlist "xsel -bo | sed 's/\\r$//'"
      end,
      ["*"] = "xsel -bo", -- is not actually used?
    },
    cache_enabled = 0,
  }
else
  vim.opt.clipboard = "unnamedplus"
end
