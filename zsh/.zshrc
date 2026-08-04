export ZSH="$HOME/.oh-my-zsh"

export GOPATH="/opt/homebrew/Cellar/go"
path=("$GOPATH/bin" "$HOME/.cargo/bin" $path)

ZSH_THEME="robbyrussell"

# kube context in the prompt
if [ -f /opt/homebrew/opt/kube-ps1/share/kube-ps1.sh ]; then
  source /opt/homebrew/opt/kube-ps1/share/kube-ps1.sh
  PS1='$(kube_ps1)'$PS1
fi

ENABLE_CORRECTION="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"

# zsh-autosuggestions and fzf-tab are git clones -- see install.sh
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

command -v fzf     >/dev/null 2>&1 && source <(fzf --zsh)
command -v direnv  >/dev/null 2>&1 && eval "$(direnv hook zsh)"
command -v thefuck >/dev/null 2>&1 && eval "$(thefuck --alias)"
command -v kubectl >/dev/null 2>&1 && source <(kubectl completion zsh)

export EDITOR='nvim'

source "$HOME/.config/zsh/aliases.zsh"

# --- container / testcontainers ---
export DOCKER_HOST="unix://${HOME}/.colima/docker.sock"
export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock
export TESTCONTAINERS_RYUK_DISABLED=true

[ -d /opt/homebrew/opt/ruby/bin ] && path=("/opt/homebrew/opt/ruby/bin" $path)

# conda, if installed
__conda_base="/opt/homebrew/Caskroom/miniconda/base"
if [ -x "$__conda_base/bin/conda" ]; then
  __conda_setup="$("$__conda_base/bin/conda" 'shell.zsh' 'hook' 2>/dev/null)"
  if [ $? -eq 0 ]; then
    eval "$__conda_setup"
  elif [ -f "$__conda_base/etc/profile.d/conda.sh" ]; then
    . "$__conda_base/etc/profile.d/conda.sh"
  fi
  unset __conda_setup
fi
unset __conda_base

[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"

# Machine-local config: work aliases, credentials, AWS profiles, paths.
# Never committed -- see .gitignore.
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

