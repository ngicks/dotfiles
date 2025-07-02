#!/bin/bash

# If an update contains deno, proceeding deno task fails somehow with ENOENT.
# Call twice to encounter that case.
deno task update:all
deno task update:all
