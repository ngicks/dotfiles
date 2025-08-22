# snapshot home

An instruction to make home dir snapshot-table.

A countermeasurement for deleting (by yourself) accidentally important files.

## prepare image file.

Run `./prepare_image.sh`

## Optional: you can copy your pre-existing home dir.

```sh
rsync -av --progress ~/ "/mnt/snapshot-home/$(uname -n)/current"
```
