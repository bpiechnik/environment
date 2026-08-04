#!/usr/bin/env bash
# Opens yazi in a split, then feeds the chosen path back to helix as :$action.
action="$1"

ORIGINAL_PANE=$(tmux select-pane -U)
PANE_OUTPUT=$(tmux capture-pane -p -t "$ORIGINAL_PANE")

# Pull the current file out of helix's statusline to open yazi alongside it
RES=$(echo "$PANE_OUTPUT" | rg -e "(?:NOR|INS|SEL)\s+(\S*)\s[^│]* (\d+):*.*" -o --replace '$1 $2')
FILE=$(echo "$RES" | awk '{print $1}')

if [[ -n "$FILE" ]] && realpath "$FILE" >/dev/null 2>&1; then
	START_DIR=$(dirname "$(realpath "$FILE")")
else
	START_DIR="$PWD"
fi

paths=$(yazi --chooser-file=/dev/stdout "$START_DIR")

if [[ -n "$paths" ]]; then
	tmux last-pane
	tmux send-keys Escape
	tmux send-keys ":$action $paths"
	tmux send-keys Enter
else
	tmux kill-window -t fx
fi
