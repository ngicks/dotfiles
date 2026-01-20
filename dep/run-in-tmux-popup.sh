#!/bin/bash

set -e

if !(command -v go &> /dev/null); then
  echo "  skipping...: go is not installed"
  return
fi

if command -v tmux-popup-pinentry-curses &> /dev/null; then
    echo "  tmux-popup-pinentry-curses already installed"
else
    echo "  Installing tmux-popup-pinentry-curses..."
    GOBIN=$HOME/.local/bin go install github.com/ngicks/run-in-tmux-popup/cmd/tmux-popup-pinentry-curses@latest
    echo "  tmux-popup-pinentry-curses installation completed"
fi


if command -v zellij-popup-pinentry-curses &> /dev/null; then
    echo "  zellij-popup-pinentry-curses already installed"
else
    echo "  Installing zellij-popup-pinentry-curses..."
    GOBIN=$HOME/.local/bin go install github.com/ngicks/run-in-tmux-popup/cmd/zellij-popup-pinentry-curses@latest
    echo "  zellij-popup-pinentry-curses installation completed"
fi
