#!/usr/bin/env bash

# this always fails because of readonly
# lazy.lock
nvim --headless "+Lazy! restore" +qa
nvim --headless -c "TSUpdateSync" +qa
