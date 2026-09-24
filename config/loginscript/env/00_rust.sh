export_unless_container_override CARGO_HOME "${XDG_DATA_HOME:-$HOME/.local/share}/cargo"
export_unless_container_override RUSTUP_HOME "${XDG_DATA_HOME:-$HOME/.local/share}/rustup"

# RUST_SRC_PATH is not exported: rust-analyzer locates the std sources from the
# active toolchain's sysroot itself, and resolving it here cost a
# `rustc --print sysroot` fork on every shell start.
