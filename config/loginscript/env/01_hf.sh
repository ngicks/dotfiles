# huggingface_hub defaults HF_HOME to ~/.cache/huggingface and keeps both the
# login token and the hub/xet/datasets caches under it. Keep the caches in the
# shared gitrepo storage so they are reused across projects and devenv
# containers, and split the token off into the XDG config dir so it can be
# persisted on its own. In containers devenv/scripts/opts.d/46-hf.sh forwards
# the same cache path and mounts the hf-token volume at the token dir.
export_unless_container_override HF_HOME "${GITREPO_ROOT:-$HOME/gitrepo}/__global_storage/huggingface"
export_unless_container_override HF_TOKEN_PATH "${XDG_CONFIG_HOME:-$HOME/.config}/huggingface/token"
