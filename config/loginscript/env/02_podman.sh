export PODMAN_IGNORE_CGROUPSV1_WARNING=1

# keep in sync with ../../environment.d/75-podman.conf
_quadlet_additional="${XDG_CONFIG_HOME:-$HOME/.config}/containers-quadlet-additional"
mkdir -p "${_quadlet_additional}"
export_unless_container_override QUADLET_UNIT_DIRS "${XDG_CONFIG_HOME:-$HOME/.config}/containers-quadlet:${_quadlet_additional}"
unset _quadlet_additional

if [[ -f $HOME/.config/containers/path.sh ]]; then
  . $HOME/.config/containers/path.sh
fi
