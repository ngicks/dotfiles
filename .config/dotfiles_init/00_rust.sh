if [[ "$IN_CONTAINER" -ne "1" ]]; then
  export CARGO_HOME="$HOME/.local/cargo"
  export RUSTUP_HOME="$HOME/.local/rustup"
fi
