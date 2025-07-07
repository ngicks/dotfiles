#!/bin/bash

# Usage: ./pattern_swap.sh <pattern> <replacement> <command> [args...]
# Example: ./pattern_swap.sh "foo" "bar" echo "hello foo world"

if [ $# -lt 3 ]; then
    echo "Usage: $0 <pattern> <replacement> <command> [args...]" >&2
    exit 1
fi

PATTERN="$1"
REPLACEMENT="$2"
COMMAND="$3"
shift 3

# Run command and swap pattern in its stdout
# stderr passes through unchanged
"$COMMAND" "$@" | sed "s/$PATTERN/$REPLACEMENT/g"

# Preserve exit code
exit ${PIPESTATUS[0]}