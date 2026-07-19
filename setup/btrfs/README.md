## btrfs setup

### WSL2

#### On Host

Make virtual disk on any target drives.

```ps1
mkdir E:\wsl
New-VHD -Path E:\data\wsl\vhd\linux-userdata-0.vhdx -SizeBytes 500GB -Dynami
# mirror only:
mkdir D:\wsl
New-VHD -Path D:\data\wsl\vhd\linux-userdata-1.vhdx -SizeBytes 500GB -Dynamic
```

Customize and execute `register-task-wsl-mount.ps1`

Verify

```ps1
(Get-ScheduledTask "WSL attach data disks").Principal   # RunLevel : Highest
Start-ScheduledTask "WSL attach data disks"             # test-fire
wsl -e lsblk                                            # disk visible?
```

Execute manually

```ps1
Start-ScheduledTask "WSL attach data disks"
```

### On Linux

Find disks

```
lsblk
ls /dev/disk/by-id/ -la
```

Normally it starts from `sde`

```
sudo mkfs.btrfs -L linux-userdata -d raid1 -m raid1 /dev/sde /dev/sdf ...
```

Or if just a single disk

```
sudo mkfs.btrfs -L linux-userdata /dev/sde
```

### Config

Moving parts live in `mountpoints.json` (gitignored). Start from the example:

```
cp mountpoints.example.json mountpoints.json
```

- `env`: UPPER_SNAKE_CASE variables substituted into `template/` via `envsubst`
  - `ROOT_POOL`: where the pool top-level (subvolid=5) is mounted
  - `DISK_LABEL`: filesystem label of the pool device
  - `FS_COMPRESSION`: `compress=` mount option value
  - `SNAPSHOT_SCRIPT_DIR` (optional, default `/usr/local/libexec/btrfs-snapshot`):
    absolute path the snapshot scripts are installed to and that the snapshot
    services exec
  - `MANAGEMENT_SCRIPT_DIR` (optional, default `/usr/local/sbin`): absolute path
    the admin scripts (`create-subvolumes.sh`) are installed to
  - `SNAPSHOT_RANDOMIZED_DELAY` (optional, default `10min`): `RandomizedDelaySec=`
    of the snapshot timers. Each timer gets a stable per-unit offset
    (`FixedRandomDelay=true`) so simultaneous firings — especially the
    `Persistent=true` catch-up burst right after boot — are spread out
- `subvolume[]`: `volname` (path under the pool) and `mount-to` (mountpoint);
  both may reference `${USER}`, `${HOME}`, `${XDG_DATA_HOME}`. Optional
  `snapshot[]` entries `{ "interval": "hourly", "retention": 5 }` set up periodic
  snapshots per interval (any systemd `OnCalendar` shorthand/spec; `retention`
  defaults to 3).

Requires `jq`, `envsubst` (gettext), `systemd-escape`, `btrfs-progs`.

### Generate

Run as your normal user; rerun after editing `mountpoints.json`. All outputs are
gitignored. `result/` is a staging tree mirroring `/`.

```
./generate-units.sh              # template/ -> result/etc/systemd/system/
                                 #   mount units + btrfs-snapshot-<mountpoint>-<interval>.{service,timer}
./generate-snapshot-scripts.sh   # -> result/<SNAPSHOT_SCRIPT_DIR>/<escaped-mountpoint>.sh
./generate-create-subvolumes.sh  # -> result/<MANAGEMENT_SCRIPT_DIR>/create-subvolumes.sh
```

### Apply

```sh
# copy the staging tree onto / (units + scripts)
sudo cp -a result/. /
sudo systemctl daemon-reload

# mount the pool top-level (unit name = systemd-escaped ROOT_POOL) and
# create the configured subvolumes (idempotent; skips existing ones)
sudo systemctl start mnt-btrfspool.mount
sudo /usr/local/share/btrfs-util/create-subvolumes.sh

# enable + start everything else. Mounts are wanted by the disk's device unit,
# so they come up whenever the disk appears; timers go to timers.target with
# Persistent=true (runs missed while powered off fire on the next boot).
# The snapshot .service units are timer-activated and need no enabling.
(cd result/etc/systemd/system && sudo systemctl enable --now $(ls *.mount *.timer | tr '\n' ' '))
```

Snapshot timers come one pair per mountpoint & interval
(`btrfs-snapshot-<mountpoint>-<interval>.{service,timer}`), so snapshotting can
still be enabled/disabled per subvolume afterwards.

Read-only snapshots go to `<ROOT_POOL>/@snapshots/<volname>/<interval>/<stamp>`,
pruned to the newest `retention` per subvolume and interval.

### Stop / remove

To just stop snapshotting one mountpoint, disable its timers; existing
snapshots are kept:

```sh
sudo systemctl disable --now \
  btrfs-snapshot-home-watage-.gnupg-daily.timer \
  btrfs-snapshot-home-watage-.gnupg-monthly.timer
```

Full teardown below. The staged `result/` tree serves as the manifest of what
was installed — regenerate it first if `mountpoints.json` changed since the
install. None of this deletes data except step 3.

```sh
# 1. snapshot timers, so nothing fires mid-teardown
(cd result/etc/systemd/system && sudo systemctl disable --now $(ls *.timer | tr '\n' ' '))

# 2. subvolume mounts, keeping the pool mounted for step 3. Unmounting fails
#    while a mountpoint is busy; close its users first (`fuser -vm <mountpoint>`
#    lists them, e.g. gpg-agent for ~/.gnupg, running containers for
#    ~/.local/share/containers)
(cd result/etc/systemd/system && sudo systemctl disable --now $(ls *.mount | grep -v '^mnt-btrfspool' | tr '\n' ' '))

# 3. OPTIONAL + DESTRUCTIVE: delete the data via the pool path.
#    Snapshots of a subvolume first, then the subvolume itself.
sudo btrfs subvolume delete /mnt/btrfspool/@snapshots/watage/@gnupg/*/*
sudo btrfs subvolume delete /mnt/btrfspool/watage/@gnupg

# 4. pool mount
sudo systemctl disable --now mnt-btrfspool.mount

# 5. remove the installed units and scripts, using the staging tree as manifest
(cd result && find . -type f -printf '/%P\0' | xargs -0 sudo rm)
sudo systemctl daemon-reload
```
