#!/bin/bash

# BTRFS Snapshot Script with Retention Strategy
# Keeps: 24 hourly, 7 daily, 4 weekly, 12 monthly, 5 yearly snapshots

BTRFS_IMAGE="/usr/local/etc/btrfs_home/watage/home.img"
MOUNT_POINT="/mnt/btrfs_home/watage"
SNAPSHOT_DIR="${MOUNT_POINT}/snapshots"
DATE=$(date +%Y-%m-%dT%H:%M:%S)
HOUR=$(date +%Y-%m-%dT%H)
DAY=$(date +%Y-%m-%d)
WEEK=$(date +%Y-W%U)
MONTH=$(date +%Y-%m)
YEAR=$(date +%Y)

# Snapshot type passed as argument (hourly, daily, weekly, monthly, yearly)
SNAPSHOT_TYPE=${1:-hourly}

# Retention limits
HOURLY_KEEP=24
DAILY_KEEP=7
WEEKLY_KEEP=4
MONTHLY_KEEP=12
YEARLY_KEEP=10

# Ensure mount point exists and is mounted
if ! mountpoint -q "$MOUNT_POINT"; then
    echo "Error: $MOUNT_POINT is not mounted" >&2
    exit 1
fi

# Check if snapshots directory exists
if [ ! -d "$SNAPSHOT_DIR" ]; then
    echo "Error: Snapshots directory $SNAPSHOT_DIR does not exist" >&2
    exit 1
fi

# Create snapshot based on type
case "$SNAPSHOT_TYPE" in
    hourly)
        SNAPSHOT_NAME="hourly_${HOUR}_${DATE}"
        PREFIX="hourly_"
        KEEP_COUNT=$HOURLY_KEEP
        ;;
    daily)
        SNAPSHOT_NAME="daily_${DAY}_${DATE}"
        PREFIX="daily_"
        KEEP_COUNT=$DAILY_KEEP
        ;;
    weekly)
        SNAPSHOT_NAME="weekly_${WEEK}_${DATE}"
        PREFIX="weekly_"
        KEEP_COUNT=$WEEKLY_KEEP
        ;;
    monthly)
        SNAPSHOT_NAME="monthly_${MONTH}_${DATE}"
        PREFIX="monthly_"
        KEEP_COUNT=$MONTHLY_KEEP
        ;;
    yearly)
        SNAPSHOT_NAME="yearly_${YEAR}_${DATE}"
        PREFIX="yearly_"
        KEEP_COUNT=$YEARLY_KEEP
        ;;
    *)
        echo "Error: Invalid snapshot type. Use: hourly, daily, weekly, monthly, or yearly" >&2
        exit 1
        ;;
esac

# Create snapshot of the current subvolume
btrfs subvolume snapshot -r "${MOUNT_POINT}/current" "${SNAPSHOT_DIR}/${SNAPSHOT_NAME}"

if [ $? -eq 0 ]; then
    echo "Snapshot created: ${SNAPSHOT_DIR}/${SNAPSHOT_NAME}"
else
    echo "Error: Failed to create snapshot" >&2
    exit 1
fi

# Clean up old snapshots of the same type
SNAPSHOT_COUNT=$(ls -1 "$SNAPSHOT_DIR" | grep "^${PREFIX}" | wc -l)
if [ "$SNAPSHOT_COUNT" -gt "$KEEP_COUNT" ]; then
    OLD_SNAPSHOTS=$(ls -1t "$SNAPSHOT_DIR" | grep "^${PREFIX}" | tail -n +$((KEEP_COUNT + 1)))
    for old_snapshot in $OLD_SNAPSHOTS; do
        btrfs subvolume delete "${SNAPSHOT_DIR}/${old_snapshot}"
        echo "Deleted old snapshot: ${SNAPSHOT_DIR}/${old_snapshot}"
    done
fi
