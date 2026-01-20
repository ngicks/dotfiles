if command -v nvim &> /dev/null; then
  # for zellij
  export EDITOR=$(which nvim)
  export VISUAL=$(which nvim)
fi
