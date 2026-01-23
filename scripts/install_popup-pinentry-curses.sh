#/bin/env bash
export GOBIN=$HOME/.local/bin

selector=${1:-"latest"}

go install github.com/ngicks/run-in-tmux-popup/cmd/tmux-popup-pinentry-curses@${selector}
go install github.com/ngicks/run-in-tmux-popup/cmd/zellij-popup-pinentry-curses@${selector}
