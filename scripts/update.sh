#!/usr/bin/zsh

echo "apt update"
echo ""
sudo apt update
echo ""
echo "apt dist-upgrade"
echo ""
sudo apt dist-upgrade -y
echo ""
echo "apt autoremove"
echo ""
sudo apt autoremove -y
echo ""
echo "mise self-update"
echo ""
mise self-update -y


__force_reinstall_if_not_exist() {
  if ! command -v $1 >/dev/null 2>&1; then
     mise install $2 -f
  fi 
}

echo ""
echo "mise install"
echo ""
pushd ~/.config/mise
mise install
__force_reinstall_if_not_exist uv uv
__force_reinstall_if_not_exist cargo rust
popd


