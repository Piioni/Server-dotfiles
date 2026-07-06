Server dotfiles repository.

Includes fish, yazi, and zellij configs.

- `./install.sh` installs packages and tools only, including terminal support for kitty/xterm-kitty VPS sessions so Vim and similar apps work correctly.
- `./install.sh` also installs `zjstatus.wasm` to `/usr/local/share/zellij/plugins/` when the plugin file is present in the repo.
- `./link.sh` backs up existing config directories as needed and symlinks the repo-managed configs into `~/.config`.
