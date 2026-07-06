Server dotfiles repository.

Includes fish, yazi, and zellij configs.

- `./install.sh` installs packages and tools only, including terminal support for kitty/xterm-kitty VPS sessions so Vim and similar apps work correctly.
- `./link.sh` backs up existing config directories as needed and symlinks the repo-managed configs into `~/.config`.
