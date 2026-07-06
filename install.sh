#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ROOT="$REPO_ROOT/home/.config"
USER_CONFIG_ROOT="$HOME/.config"
APT_PACKAGES=(
  curl git fish bat file ffmpeg jq poppler-utils fd-find ripgrep fzf zoxide imagemagick p7zip-full
)

log() {
  printf '[install] %s\n' "$1"
}

has_command() {
  command -v "$1" >/dev/null 2>&1
}

install_apt_packages() {
  if ! has_command apt-get; then
    log "apt-get not found; skipping apt package installation"
    return
  fi

  local available_packages=()
  local package
  for package in "${APT_PACKAGES[@]}"; do
    if apt-cache show "$package" >/dev/null 2>&1; then
      available_packages+=("$package")
    else
      log "Skipping unavailable apt package: $package"
    fi
  done

  if [ "${#available_packages[@]}" -gt 0 ]; then
    sudo apt-get update
    sudo apt-get install -y "${available_packages[@]}"
  fi
}

install_eza() {
  if has_command eza; then
    log "eza already installed"
    return
  fi

  if apt-cache show eza >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y eza
    return
  fi

  log "Configuring official eza repository"
  sudo mkdir -p /etc/apt/keyrings
  if [ ! -f /etc/apt/keyrings/gierens.gpg ]; then
    curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg
  fi

  local arch codename repo_file
  arch="$(dpkg --print-architecture)"
  codename="$(. /etc/os-release && printf '%s' "${VERSION_CODENAME:-}")"
  if [ -z "$codename" ] && has_command lsb_release; then
    codename="$(lsb_release -cs)"
  fi
  if [ -z "$codename" ]; then
    log "Could not determine distro codename for eza repository"
    return 1
  fi

  repo_file="/etc/apt/sources.list.d/gierens.list"
  printf 'deb [arch=%s signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main\n' "$arch" | sudo tee "$repo_file" >/dev/null
  sudo chmod 644 "$repo_file"
  sudo mkdir -p /etc/apt/preferences.d
  printf 'Package: *\nPin: origin deb.gierens.de\nPin-Priority: 1000\n' | sudo tee /etc/apt/preferences.d/gierens >/dev/null
  sudo chmod 644 /etc/apt/preferences.d/gierens
  sudo apt-get update
  sudo apt-get install -y eza
}

install_snap_package() {
  local name="$1"
  if has_command "$name"; then
    log "$name already installed"
    return
  fi

  if ! has_command snap; then
    log "snap not found; skipping $name installation"
    return
  fi

  sudo snap install "$name" --classic
}

install_fisher() {
  if ! has_command fish; then
    log "fish not found; skipping fisher installation"
    return
  fi

  if fish -c 'functions -q fisher' >/dev/null 2>&1; then
    log "fisher already installed"
  else
    log "Installing fisher"
    fish -c 'curl -fsSL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher'
  fi

  fish -c 'contains -- "$HOME/.local/bin" $fish_user_paths; or set -Ua fish_user_paths "$HOME/.local/bin"' >/dev/null 2>&1 || true
}

backup_target_if_needed() {
  local target="$1"
  local source="$2"

  if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$source")" ]; then
    return
  fi

  if [ -e "$target" ] || [ -L "$target" ]; then
    local backup_path="${target}.backup.$(date +%Y%m%d%H%M%S)"
    log "Backing up $target to $backup_path"
    mv "$target" "$backup_path"
  fi
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

  backup_target_if_needed "$target" "$source"
  ln -sfn "$source" "$target"
  log "Linked $target -> $source"
}

main() {
  install_apt_packages
  install_eza
  install_snap_package zellij
  install_snap_package yazi
  install_fisher
  link_config_dir fish
  link_config_dir yazi
  link_config_dir zellij
  log "Done"
}

main "$@"
