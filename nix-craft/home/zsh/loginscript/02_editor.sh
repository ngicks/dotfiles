if command -v nvim &> /dev/null; then
  export EDITOR=$(which nvim)
  export VISUAL=$(which nvim)
fi
