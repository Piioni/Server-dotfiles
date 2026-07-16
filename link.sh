#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ROOT="$REPO_ROOT/home/.config"
USER_CONFIG_ROOT="$HOME/.config"
TIMESTAMP="$(date +%Y%m%d%H%M%S)"
BACKUP_ROOT="$HOME/.local/state/server-dotfiles/backups/$TIMESTAMP"
DRY_RUN=false
BACKUP_ROOT_PREPARED=false

log() {
  printf '[link] %s\n' "$1"
}

usage() {
  cat <<'EOF'
Usage: ./link.sh [--dry-run|-n] [component ...]

Components:
  fish
  starship
  yazi
  zellij
EOF
}

component_source_path() {
  case "$1" in
    fish|yazi|zellij)
      printf '%s/%s' "$CONFIG_ROOT" "$1"
      ;;
    starship)
      printf '%s/starship.toml' "$CONFIG_ROOT"
      ;;
    *)
      return 1
      ;;
  esac
}

component_target_path() {
  case "$1" in
    fish|yazi|zellij)
      printf '%s/%s' "$USER_CONFIG_ROOT" "$1"
      ;;
    starship)
      printf '%s/starship.toml' "$USER_CONFIG_ROOT"
      ;;
    *)
      return 1
      ;;
  esac
}

component_kind() {
  case "$1" in
    fish|yazi|zellij)
      printf 'dir'
      ;;
    starship)
      printf 'file'
      ;;
    *)
      return 1
      ;;
  esac
}

ensure_parent_dir() {
  local path="$1"
  local parent
  parent="$(dirname "$path")"

  if [ "$DRY_RUN" = true ]; then
    log "Would ensure parent directory exists: $parent"
  else
    mkdir -p "$parent"
  fi
}

ensure_backup_root() {
  if [ "$BACKUP_ROOT_PREPARED" = true ]; then
    return
  fi

  if [ "$DRY_RUN" = true ]; then
    log "Would use backup root: $BACKUP_ROOT"
  else
    mkdir -p "$BACKUP_ROOT"
  fi

  BACKUP_ROOT_PREPARED=true
}

backup_path_for_target() {
  local target="$1"
  local relative_target="${target#"$HOME"/}"
  printf '%s/%s' "$BACKUP_ROOT" "$relative_target"
}

backup_target_if_needed() {
  local target="$1"
  local source="$2"

  if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$source")" ]; then
    log "$target already points to repo config"
    return 1
  fi

  if [ -e "$target" ] || [ -L "$target" ]; then
    local backup_path
    backup_path="$(backup_path_for_target "$target")"
    ensure_backup_root

    if [ "$DRY_RUN" = true ]; then
      log "Would back up $target to $backup_path"
    else
      mkdir -p "$(dirname "$backup_path")"
      log "Backing up $target to $backup_path"
      mv "$target" "$backup_path"
    fi
  fi

  return 0
}

link_component() {
  local component="$1"
  local kind source target

  kind="$(component_kind "$component")" || {
    log "Unknown component: $component"
    usage
    exit 1
  }

  source="$(component_source_path "$component")"
  target="$(component_target_path "$component")"

  if [ "$kind" = dir ] && [ ! -d "$source" ]; then
    log "Source config missing for $component; skipping"
    return
  fi

  if [ "$kind" = file ] && [ ! -f "$source" ]; then
    log "Source config missing for $component; skipping"
    return
  fi

  ensure_parent_dir "$target"

  if ! backup_target_if_needed "$target" "$source"; then
    return
  fi

  if [ "$DRY_RUN" = true ]; then
    log "Would link $target -> $source"
  else
    ln -sfn "$source" "$target"
    log "Linked $target -> $source"
  fi
}

parse_args() {
  COMPONENTS=()

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --dry-run|-n)
        DRY_RUN=true
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      fish|starship|yazi|zellij)
        COMPONENTS+=("$1")
        ;;
      *)
        log "Unknown argument: $1"
        usage
        exit 1
        ;;
    esac
    shift
  done

  if [ "${#COMPONENTS[@]}" -eq 0 ]; then
    COMPONENTS=(fish starship yazi zellij)
  fi
}

main() {
  parse_args "$@"

  local component
  for component in "${COMPONENTS[@]}"; do
    link_component "$component"
  done

  if [ "$DRY_RUN" = true ]; then
    log "Dry run complete"
  else
    log "Done"
  fi
}

main "$@"
