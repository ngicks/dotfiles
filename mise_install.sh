# run with whatever shell you want

set -Cue

dir="$(dirname $0)/.config/initial_path"

echo "sourcing $dir/00_*.sh"

for f in $dir/00_*.sh; do
  . $f
done

eval "$(mise activate $1)"
core_tools=$(mise ls --json | jq -r 'keys[] | select(contains(":") | not)' | tr "\n" " ")
echo "installing core(no backend) tools:"
echo "  $core_tools"
echo ""
mise install -y $core_tools
echo ""
echo ""
echo "install rest of tools"
echo ""
mise install -y
