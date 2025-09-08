#!/bin/bash

set -e

echo "Installing packages via brew..."

for f in ./dep/apt/*.sh; do
  . $f
done

echo "brew done"
