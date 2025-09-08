#!/bin/bash

set -e

echo "Checking and installing common tools..."

for f in ./dep/common/*.sh; do
  . $f
done

echo "common done"
