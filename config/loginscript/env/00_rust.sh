export_unless_container_override CARGO_HOME "${XDG_DATA_HOME:-$HOME/.local/share}/cargo"
export_unless_container_override RUSTUP_HOME "${XDG_DATA_HOME:-$HOME/.local/share}/rustup"

if command -v rustc > /dev/null 2>&1; then
  export_unless_container_override RUST_SRC_PATH "$(rustc --print sysroot)/lib/rustlib/src/rust/library"
fi
