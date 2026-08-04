# Portable aliases. Work-specific ones live in ~/.zshrc.local.

# --- editor / shell ---
alias n='nvim'
alias cc='clear'

# --- git ---
# (oh-my-zsh's git plugin provides gcmsg, gsw, gswc, ga, gl, ...)
alias gs='git status'
alias gcam='git commit -am'
alias ghome='cd $(git rev-parse --show-toplevel)'
alias df=' git diff --name-only --relative --diff-filter=d -z | xargs -0 bat --theme "Catppuccin Mocha" --diff'

# --- go ---
alias grm='go run main.go'
alias gt='go test ./...'

# --- make ---
alias mt='make test'
alias mg='make generate'
alias ml='make lint'

# --- tmux ---
alias tls='tmux ls'
alias tks='tmux kill-session -t'
alias tms='~/.local/scripts/tmux-sessionizer'
alias tmss='~/.local/scripts/tmux-switch-session'
alias tmsk='~/.local/scripts/tmux-sessionizer-clean'

# --- kubernetes ---
alias k='kubectl'
alias kctx='kubectx'

# --- containers ---
alias pcd='podman-compose down'
alias pcdv='podman-compose down -v'

# --- localstack sqs ---
alias slist="awslocal sqs list-queues"
alias qurl='awslocal sqs list-queues | jq -r '\''.QueueUrls[1]'\'' | pbcopy'

deleteq() {
    awslocal sqs delete-queue --queue-url "$(awslocal sqs list-queues | jq -r '.QueueUrls[0]')"
}
