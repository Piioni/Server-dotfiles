#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ROOT="$REPO_ROOT/home/.config"
USER_CONFIG_ROOT="$HOME/.config"
TIMESTAMP="$(date +%Y%m%d%H%M%S)"

log() {
  printf '[link] %s\n' "$1"
}

backup_target_if_needed() {
  local target="$1"
  local source="$2"

  if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$source")" ]; then
    log "$target already points to repo config"
    return 1
  fi

  if [ -e "$target" ] || [ -L "$target" ]; then
    local backup_path="${target}.backup.${TIMESTAMP}"
    log "Backing up $target to $backup_path"
    mv "$target" "$backup_path"
  fi

  return 0
}

link_config_dir() {
  local name="$1"
  local source="$CONFIG_ROOT/$name"
  local target="$USER_CONFIG_ROOT/$name"

  mkdir -p "$USER_CONFIG_ROOT"

  if [ ! -d "$source" ]; then
    log "Source config missing for $name; skipping"
    return
  fi

  if ! backup_target_if_needed "$target" "$source"; then
    return
  fi

  ln -sfn "$source" "$target"
  log "Linked $target -> $source"
}

main() {
  link_config_dir fish
  link_config_dir yazi
  link_config_dir zellij
  log "Done"
}

main "$@"
