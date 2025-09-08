#!/bin/bash

set -e

echo "Installing packages via apt..."

for f in ./dep/brew/*.sh; do
  . $f
done

echo "apt done"
