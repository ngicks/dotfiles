#!/bin/bash

set -e

echo "Installing packages via apt..."

for f in ./dep/apt/*.sh; do
  . $f
done

echo "brew done"
