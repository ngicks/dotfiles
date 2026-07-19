#!/usr/bin/env bash
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config="$here/mountpoints.json"

for cmd in jq envsubst systemd-escape; do
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

[[ -n ${ROOT_POOL:-} ]] || {
  echo "error: ROOT_POOL missing in mountpoints.json env" >&2
  exit 1
}

# scripts are staged under result/ mirroring their install location
# (SNAPSHOT_SCRIPT_DIR), which is what ExecStart= in the units references
script_dir="${SNAPSHOT_SCRIPT_DIR:-/usr/local/libexec/btrfs-snapshot}"
[[ $script_dir = /* ]] || {
  echo "error: SNAPSHOT_SCRIPT_DIR must be an absolute path: $script_dir" >&2
  exit 1
}
out_dir="$here/result$script_dir"

rm -rf "$out_dir"
mkdir -p "$out_dir"

while IFS= read -r entry; do
  vol="$(jq -r '.volname' <<<"$entry" | envsubst)"
  mount_to="$(jq -r '."mount-to"' <<<"$entry" | envsubst)"
  esc="$(systemd-escape --path "$mount_to")"
  out="$out_dir/$esc.sh"
  {
    cat <<EOF
#!/usr/bin/env bash
# generated from mountpoints.json by generate-snapshot-scripts.sh; do not edit.
# snapshots \$vol (mounted on $mount_to); invoked as "\$0 <interval>" by
# btrfs-snapshot-$esc-<interval>.service; read-only snapshots go to
# \$snap_root/\$vol/<interval>/<stamp>, pruned to the newest \$keep.
set -euo pipefail

pool=$(printf '%q' "$ROOT_POOL")
snap_root=\$pool/$(printf '%q' "${SNAPSHOT_DIR:-@snapshots}")
vol=$(printf '%q' "$vol")
interval="\${1:?usage: \$0 <interval>}"
stamp="\$(date +%Y%m%dT%H%M%S)"

case "\$interval" in
EOF
    while IFS=$'\t' read -r interval retention; do
      [[ $retention =~ ^[1-9][0-9]*$ ]] || {
        echo "error: retention must be a positive integer ($vol/$interval): $retention" >&2
        exit 1
      }
      printf '%s) keep=%q ;;\n' "$(printf '%q' "$interval")" "$retention"
    done < <(jq -r '.snapshot[] | [.interval, (.retention // 3)] | @tsv' <<<"$entry")
    cat <<EOF
*)
  echo "error: interval not configured for \$vol: \$interval" >&2
  exit 1
  ;;
esac

if ! mountpoint -q "\$pool"; then
  echo "error: \$pool is not a mountpoint; mount the pool first (see units/)" >&2
  exit 1
fi

dst_dir="\$snap_root/\$vol/\$interval"
mkdir -p "\$dst_dir"
btrfs subvolume snapshot -r "\$pool/\$vol" "\$dst_dir/\$stamp"
while IFS= read -r old; do
  btrfs subvolume delete "\$dst_dir/\$old"
done < <(ls -1 "\$dst_dir" | sort | head -n -"\$keep")
EOF
  } >"$out"
  chmod +x "$out"
  echo "generated ${out#"$here/"}"
done < <(jq -c '.subvolume[] | select(.snapshot)' "$config")
