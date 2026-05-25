#!/usr/bin/env bash

set -euo pipefail

run_in_new_shell=$(cd $(dirname $0) && pwd -P)/run-in-new-interactive-shell.sh
mise_install_f=$(cd $(dirname $0) && pwd -P)/mise-install-f-if-missing.sh

echo ""
echo "mise install"
echo ""

mise install --locked

echo ""
echo "mise install -f if missing"
echo ""

$mise_install_f

echo ""
echo "mise prune"
echo ""

mise prune --locked -y
