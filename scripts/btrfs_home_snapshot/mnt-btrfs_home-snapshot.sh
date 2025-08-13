#!/bin/bash

# WSL Startup Snapshot Handler
# Runs when WSL starts to catch up on missed snapshots

SCRIPT_PATH="/usr/local/bin/btrfs_snapshot_strategy.sh"
MOUNT_POINT="/mnt/btrfs_home/watage"
SNAPSHOT_DIR="${MOUNT_POINT}/snapshots"

# Check last snapshot times
get_last_snapshot_date() {
    local snapshot_type=$1
    local prefix=""
    
    case "$snapshot_type" in
        hourly)  prefix="hourly_" ;;
        daily)   prefix="daily_" ;;
        weekly)  prefix="weekly_" ;;
        monthly) prefix="monthly_" ;;
        yearly)  prefix="yearly_" ;;
    esac
    
    # Get the most recent snapshot of this type
    local latest=$(ls -1t "$SNAPSHOT_DIR" 2>/dev/null | grep "^${prefix}" | head -1)
    
    if [ -n "$latest" ]; then
        # Extract date from snapshot name (format: type_YYYYMMDD_...)
        echo "$latest" | sed -n "s/^${prefix}\([0-9_]*\)_.*/\1/p"
    else
        echo "0"
    fi
}

# Check if snapshot is needed based on actual snapshot files
should_create_snapshot() {
    local snapshot_type=$1
    local last_date=$(get_last_snapshot_date "$snapshot_type")
    local current_date=$(date +%Y%m%d)
    
    case "$snapshot_type" in
        hourly)
            # Need hourly if last hour differs
            local last_hour=$(echo "$last_date" | cut -d_ -f1,2)
            local current_hour=$(date +%Y%m%d_%H)
            [ "$last_hour" != "$current_hour" ]
            ;;
        daily)
            # Need daily if last snapshot date differs from today
            [ "$last_date" != "$(date +%Y%m%d)" ]
            ;;
        weekly)
            # Need weekly if last week number differs
            local last_week=$(echo "$last_date" | cut -c1-4)_W$(date -d "${last_date:0:4}-${last_date:4:2}-${last_date:6:2}" +%U 2>/dev/null || echo "00")
            local current_week=$(date +%Y_W%U)
            [ "$last_week" != "$current_week" ]
            ;;
        monthly)
            # Need monthly if last month differs
            local last_month=${last_date:0:6}
            local current_month=$(date +%Y%m)
            [ "$last_month" != "$current_month" ]
            ;;
        yearly)
            # Need yearly if last year differs
            local last_year=${last_date:0:4}
            local current_year=$(date +%Y)
            [ "$last_year" != "$current_year" ]
            ;;
    esac
}

# Main execution
echo "WSL Startup Snapshot Check"

# Wait for mount to be ready
for i in {1..10}; do
    if mountpoint -q "$MOUNT_POINT"; then
        break
    fi
    sleep 1
done

if ! mountpoint -q "$MOUNT_POINT"; then
    echo "Error: Mount point not ready" >&2
    exit 1
fi

# Check and create snapshots as needed
for snapshot_type in hourly daily weekly monthly yearly; do
    if should_create_snapshot "$snapshot_type"; then
        echo "Creating $snapshot_type snapshot"
        $SCRIPT_PATH "$snapshot_type"
    else
        echo "$snapshot_type snapshot is up to date"
    fi
done

echo "Snapshot check completed"