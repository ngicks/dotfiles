#!/bin/env bash

set -e

XDG_CONFIG_HOME=./config nvim --headless "+Lazy! restore" +qa
XDG_CONFIG_HOME=./config nvim --headless -c "TSUpdateSync" +qa
