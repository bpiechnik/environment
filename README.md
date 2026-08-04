# environment

macOS dev config: zsh, tmux, nvim, ghostty.

```sh
git clone git@github.com:bpiechnik/environment.git ~/environment
~/environment/install.sh
```

`install.sh` is idempotent — re-run it after pulling. It symlinks configs into
place, so editing either the repo or the live path edits the same file and
`git status` shows drift immediately.

## Layout

| Path | Links to |
|---|---|
| `zsh/.zshrc` | `~/.zshrc` |
| `zsh/aliases.zsh` | `~/.config/zsh/aliases.zsh` |
| `tmux/tmux.conf` | `~/.config/tmux/tmux.conf` |
| `nvim/` | `~/.config/nvim` |
| `ghostty/config` | `~/.config/ghostty/config` |
| `go/golangci-lint.yaml` | `~/.config/.golangci-lint.yaml` |
| `scripts/tmux-*` | `~/.local/scripts/` |
| `brew/Brewfile` | — (`brew bundle install`) |

## Machine-local config

Nothing machine- or work-specific belongs in this repo. Two untracked escape
hatches, both gitignored:

- **`~/.zshrc.local`** — sourced last by `.zshrc`. Work aliases, credentials,
  `AWS_PROFILE`, company tooling.
- **`~/.config/tmux-sessionizer/roots.conf`** — the sessionizer's search paths.
  See `scripts/roots.conf.example`.

## Keys

tmux prefix is `Ctrl-Space`.

| Key | Does |
|---|---|
| `Ctrl-f` / `prefix o` | tmux-sessionizer (fzf project switcher) |
| `Ctrl-s` / `prefix i` | switch session |
| `prefix u` | kill sessions |
| `prefix C-f` / `prefix v` | split vertical / horizontal |

## Not managed here

- Language runtimes → asdf (`.tool-versions`); asdf itself isn't brew-managed.
- nvim plugins → lazy.nvim, pinned in `nvim/lazy-lock.json`.
- nvim LSPs → mason (`lua_ls`, `pyright`, `ts_ls`). gopls and golangci-lint
  come from Homebrew instead, pinned to `/opt/homebrew/bin` so editor tooling
  stays off the asdf shim.
