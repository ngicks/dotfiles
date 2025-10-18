# run with whatever shell you want

set -Cue

eval "$(mise activate $1)"
core_tools=$(mise ls --json | jq -r 'keys[] | select(contains(":") | not)' | tr "\n" " ")
echo "installing core(no backend) tools:"
echo "  $core_tools"
echo ""
mise install -y --raw $core_tools
echo ""
echo ""
echo "install rest of tools"
echo ""
mise install -y --raw
