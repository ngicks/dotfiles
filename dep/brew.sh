#!/bin/bash

set -e

echo "Installing packages via brew..."

for f in ./dep/brew/*.sh; do
  . $f
done

echo "apt done"
