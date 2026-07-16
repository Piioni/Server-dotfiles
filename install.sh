#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZELLIJ_PLUGIN_DIR="/usr/local/share/zellij/plugins"
ZJSTATUS_PLUGIN_NAME="zjstatus.wasm"
APT_UPDATED=0

APT_PACKAGES=(
  curl git fish bat file ffmpeg jq poppler-utils fd-find ripgrep fzf zoxide imagemagick p7zip-full kitty-terminfo
)

log() {
  printf '[install] %s\n' "$1"
}

has_command() {
  command -v "$1" >/dev/null 2>&1
}

install_zjstatus_plugin() {
  local plugin_source="$REPO_ROOT/home/.config/zellij/$ZJSTATUS_PLUGIN_NAME"

  if [ ! -f "$plugin_source" ]; then
    log "zjstatus plugin not found in repo; skipping global plugin install"
    return
  fi

  log "Installing zjstatus plugin to $ZELLIJ_PLUGIN_DIR/$ZJSTATUS_PLUGIN_NAME"
  sudo mkdir -p "$ZELLIJ_PLUGIN_DIR"
  sudo install -m 0644 "$plugin_source" "$ZELLIJ_PLUGIN_DIR/$ZJSTATUS_PLUGIN_NAME"
}

apt_update_once() {
  local force_refresh="${1:-false}"

  if [ "$force_refresh" = "true" ] || [ "$APT_UPDATED" -eq 0 ]; then
    sudo apt-get update
    APT_UPDATED=1
  fi
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
    apt_update_once
    sudo apt-get install -y "${available_packages[@]}"
  fi
}

install_eza() {
  if has_command eza; then
    log "eza already installed"
    return
  fi

  if ! has_command apt-get; then
    log "apt-get not found; skipping eza installation"
    return
  fi

  if apt-cache show eza >/dev/null 2>&1; then
    apt_update_once
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
  apt_update_once true
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

install_starship() {
  if has_command starship; then
    log "starship already installed"
    return
  fi

  log "Installing starship"
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y
}

main() {
  install_apt_packages
  install_eza
  install_starship
  install_snap_package zellij
  install_snap_package yazi
  install_zjstatus_plugin
  log "Installation complete. Run ./link.sh to link repo-managed configs into ~/.config"
  log "Done"
}

main "$@"
