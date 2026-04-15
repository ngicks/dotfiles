export_unless_container_override ANSIBLE_HOME "${XDG_DATA_HOME:-$HOME/.local/share}/ansible"
export_unless_container_override ANSIBLE_SSH_CONTROL_PATH_DIR "${ANSIBLE_HOME}/ssh_control_master"
