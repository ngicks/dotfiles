# run with whatever shell you want

set -Cue

eval "$(mise activate $1)"
mise install
