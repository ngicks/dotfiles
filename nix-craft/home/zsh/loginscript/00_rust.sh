if [[ "$IN_CONTAINER" -ne "1" ]]; then
  export CARGO_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/cargo"
  export RUSTUP_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/rustup"
fi
