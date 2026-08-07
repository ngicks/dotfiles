return {
  settings = {
    ["rust-analyzer"] = {
      cargo = {
        extraEnv = {
          RUSTC_BOOTSTRAP = "1",
        },
      },
    },
  },
}
