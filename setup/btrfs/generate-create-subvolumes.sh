#!/usr/bin/env bash
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config="$here/mountpoints.json"

for cmd in jq envsubst; do
  command -v "$cmd" >/dev/null || {
    echo "error: required command not found: $cmd" >&2
    exit 1
  }
done

[[ -f $config ]] || {
  echo "error: $config not found; copy mountpoints.example.json and edit it" >&2
  exit 1
}

# XDG_DATA_HOME may be referenced from mountpoints.json but unset in the caller env.
: "${XDG_DATA_HOME:=$HOME/.local/share}"
export XDG_DATA_HOME

while IFS=$'\t' read -r key value; do
  [[ $key =~ ^[A-Z_][A-Z0-9_]*$ ]] || {
    echo "error: env key is not UPPER_SNAKE_CASE: $key" >&2
    exit 1
  }
  export "$key=$value"
done < <(jq -r '.env | to_entries[] | [.key, .value] | @tsv' "$config")

# staged under result/ mirroring the install location (MANAGEMENT_SCRIPT_DIR)
management_dir="${MANAGEMENT_SCRIPT_DIR:-/usr/local/sbin}"
[[ $management_dir = /* ]] || {
  echo "error: MANAGEMENT_SCRIPT_DIR must be an absolute path: $management_dir" >&2
  exit 1
}
out="$here/result$management_dir/create-subvolumes.sh"
mkdir -p "$(dirname "$out")"

{
  cat <<EOF
#!/usr/bin/env bash
# generated from mountpoints.json by generate-create-subvolumes.sh; do not edit.
# installed to $management_dir/create-subvolumes.sh; run as root
set -euo pipefail

if ! mountpoint -q $(printf '%q' "$ROOT_POOL"); then
  echo "error: $ROOT_POOL is not a mountpoint; mount the pool first (see units/)" >&2
  exit 1
fi

create() {
  local subvol=\$1
  if btrfs subvolume show "\$subvol" >/dev/null 2>&1; then
    echo "exists: \$subvol (skipped)"
    return
  fi
  mkdir -p "\$(dirname "\$subvol")"
  btrfs subvolume create "\$subvol"
  chown $(printf '%q' "$USER"): "\$subvol"
}

EOF
  while IFS= read -r volname; do
    vol="$(envsubst <<<"$volname")"
    printf 'create %q\n' "$ROOT_POOL/$vol"
  done < <(jq -r '.subvolume[].volname' "$config")
} >"$out"
chmod +x "$out"
echo "generated ${out#"$here/"}"
