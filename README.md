Server dotfiles repository.

Manages shared shell/terminal config for a server setup.

## What `install.sh` installs

`./install.sh` installs packages and tools only:

- apt packages: `curl`, `git`, `bat`, `file`, `ffmpeg`, `jq`, `poppler-utils`, `fd-find`, `ripgrep`, `fzf`, `zoxide`, `imagemagick`, `p7zip-full`, `kitty-terminfo`
- `eza` (from apt when available, otherwise from the official eza apt repo)
- `starship`
- `nu` (latest release binary from GitHub into `/usr/local/bin`) and the generated `~/.zoxide.nu` and starship init that its config sources
- snap packages: `zellij`, `yazi`
- global `zjstatus.wasm` for zellij at `/usr/local/share/zellij/plugins/` when the plugin file exists in this repo

It does not install Neovim.

## What `link.sh` links

`./link.sh` symlinks repo-managed config into `~/.config`:

- `nushell` → `~/.config/nushell`
- `starship.toml` → `~/.config/starship.toml`
- `yazi` → `~/.config/yazi`
- `zellij` → `~/.config/zellij`

When no component is passed, it links all managed configs.

### Usage

- Link everything: `./link.sh`
- Dry run: `./link.sh --dry-run`
- Link one component: `./link.sh nushell`
- Link multiple components: `./link.sh --dry-run nushell zellij`

If an existing target already points at this repo, `link.sh` skips it.

## Using nu as the shell

`install.sh` does not change the login shell. To do it: `echo /usr/local/bin/nu | sudo tee -a /etc/shells && chsh -s /usr/local/bin/nu`. Note that `ssh host 'cmd'` runs `cmd` through the login shell, so remote one-liners then need nu syntax.

## Backups

Existing targets are moved into a centralized backup root under:

- `~/.local/state/server-dotfiles/backups/<timestamp>/...`

Backups are not left next to the original files.

## Not managed by this repo

This repo is for shared config, not local-only or machine-specific state. For example, it does not manage:

- `~/.config/nushell/history.txt`
- other host-specific runtime/cache/state files you want to keep local
