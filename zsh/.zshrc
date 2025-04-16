export ZSH="$HOME/.oh-my-zsh"
export GOPATH="/opt/homebrew/Cellar/go"

PATH="$GOPATH/bin:$PATH"
ZSH_THEME="robbyrussell"

# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
    git
    zsh-autosuggestions
    z
    fzf-tab
)

bindkey "[D" backward-word
bindkey "[C" forward-word
bindkey -s ^f "~/.local/scripts/tmux-sessionizer\n"
bindkey -s ^s "~/.local/scripts/tmux-switch-session\n"
set -o vi

source $ZSH/oh-my-zsh.sh

source <(fzf --zsh)

alias gs='git status'
alias gcam='git commit -am'
alias cc='clear'
alias n='nvim'

alias slist="awslocal sqs list-queues"
alias ghome='cd $(git rev-parse --show-toplevel)'
alias qurl='awslocal sqs list-queues | jq -r '\''.QueueUrls[1]'\'' | pbcopy'
alias grm='go run main.go'
alias tls='tmux ls'
alias tks='tmux kill-session -t'
alias tms='~/.local/scripts/tmux-sessionizer'
alias tmss='~/.local/scripts/tmux-switch-session'
alias cgs='~/.local/scripts/go-services'
alias tmsk='~/.local/scripts/tmux-sessionizer-clean'

deleteq() {
    awslocal sqs delete-queue --queue-url "$(awslocal sqs list-queues | jq -r '.QueueUrls[0]')"
}

# User configuration

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup

# <<< conda initialize <<<

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='nvim'
else
  export EDITOR='mvim'
fi

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

eval "$(direnv hook zsh)"

eval $(thefuck --alias)
export DOCKER_HOST='unix:///var/folders/y5/q78810qx4bx18fjv1rt9x9xw0000gp/T/podman/podman-machine-default-api.sock'
alias pcdv='podman-compose down -v'
alias pcd='podman-compose down'

source ~/.opendoor_rc
