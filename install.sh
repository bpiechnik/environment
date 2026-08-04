#!/usr/bin/env bash
# Bootstrap a fresh macOS machine. Idempotent -- safe to re-run.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"

info() { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m!!\033[0m  %s\n' "$1"; }

# Symlink $2 -> $1, backing up an existing real file.
link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ]; then
    [ "$(readlink "$dst")" = "$src" ] && return 0
    rm "$dst"
  elif [ -e "$dst" ]; then
    warn "backing up $dst -> $dst.bak"
    mv "$dst" "$dst.bak"
  fi
  ln -s "$src" "$dst"
  printf '    %s -> %s\n' "$dst" "$src"
}

clone() {
  local url="$1" dst="$2"
  if [ -d "$dst/.git" ]; then
    printf '    %s (present)\n' "$dst"
  else
    git clone --depth=1 "$url" "$dst"
  fi
}

# --- homebrew ---
if ! command -v brew >/dev/null 2>&1; then
  info "installing homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

info "installing brew packages"
brew bundle install --file="$REPO/brew/Brewfile"

# --- oh-my-zsh + custom plugins ---
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  info "installing oh-my-zsh"
  RUNZSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

info "installing zsh plugins"
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone https://github.com/Aloxaf/fzf-tab               "$ZSH_CUSTOM/plugins/fzf-tab"

# --- tmux plugins ---
info "installing tmux plugins"
clone https://github.com/tmux-plugins/tpm  "$HOME/.tmux/plugins/tpm"
clone https://github.com/jonmosco/kube-tmux "$HOME/.tmux/plugins/kube-tmux"

# --- ghostty cursor shaders ---
info "installing ghostty shaders"
clone https://github.com/sahaj-b/ghostty-cursor-shaders "$CONFIG/ghostty/shaders"

# --- symlinks ---
info "linking configs"
link "$REPO/zsh/aliases.zsh"     "$CONFIG/zsh/aliases.zsh"
link "$REPO/tmux/tmux.conf"      "$CONFIG/tmux/tmux.conf"
link "$REPO/nvim"                "$CONFIG/nvim"
link "$REPO/ghostty/config"      "$CONFIG/ghostty/config"
link "$REPO/go/golangci-lint.yaml" "$CONFIG/.golangci-lint.yaml"

for f in config.toml languages.toml yazi-picker.sh ignore python-venv-lsp.sh; do
  link "$REPO/helix/$f" "$CONFIG/helix/$f"
done

for s in tmux-sessionizer tmux-switch-session tmux-sessionizer-clean \
         golangci-fmt blame_file_pretty blame_line_pretty git-hunk \
         helix-git-blame markdown-reader; do
  link "$REPO/scripts/$s" "$HOME/.local/scripts/$s"
done

chmod +x "$REPO"/scripts/* "$REPO/nvim/gopls-wrapper.sh" \
         "$REPO/helix/yazi-picker.sh" "$REPO/helix/python-venv-lsp.sh"

# --- ~/.zshrc stub ---
# A real file, not a symlink: installers (conda init, rustup, envman, work
# tooling) append to ~/.zshrc, and a symlink would write that into the repo.
if ! grep -q 'environment/zsh/.zshrc' "$HOME/.zshrc" 2>/dev/null; then
  info "writing ~/.zshrc stub"
  [ -e "$HOME/.zshrc" ] && { warn "backing up ~/.zshrc -> ~/.zshrc.bak"; mv "$HOME/.zshrc" "$HOME/.zshrc.bak"; }
  cat > "$HOME/.zshrc" <<'STUB'
# Thin local stub -- deliberately a real file, NOT a symlink into ~/environment.
# Installers (conda init, rustup, envman, work tooling) append to ~/.zshrc; a
# symlink would write those machine-specific lines into the public repo.
#
# Real config: ~/environment/zsh/.zshrc     Local overrides: ~/.zshrc.local
source "$HOME/environment/zsh/.zshrc"
STUB
fi

# --- local config scaffolding ---
if [ ! -f "$CONFIG/tmux-sessionizer/roots.conf" ]; then
  info "seeding tmux-sessionizer roots.conf"
  mkdir -p "$CONFIG/tmux-sessionizer"
  cp "$REPO/scripts/roots.conf.example" "$CONFIG/tmux-sessionizer/roots.conf"
fi

[ -f "$HOME/.zshrc.local" ] || touch "$HOME/.zshrc.local"

cat <<'EOF'

Done. Remaining manual steps:

  1. exec zsh
  2. tmux, then prefix + I   (Ctrl-Space I -- install tmux plugins via tpm)
  3. nvim                    (lazy.nvim + mason bootstrap on first launch)
  4. put machine/work-specific env in ~/.zshrc.local
  5. edit ~/.config/tmux-sessionizer/roots.conf for this machine's layout
  6. asdf is not brew-managed: install it, then `asdf install`

EOF
