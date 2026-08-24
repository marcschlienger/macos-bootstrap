#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause

# Shared helpers for the bootstrap steps.

set -Eeuo pipefail
IFS=$'\n\t'

log() {
  printf '\n==> %s\n' "$*"
}

warn() {
  printf 'warning: %s\n' "$*" >&2
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

require_macos_user() {
  [[ "$(uname -s)" == "Darwin" ]] || die "This bootstrap supports macOS only."
  ((EUID != 0)) || die "Run this as your normal macOS user, not with sudo."
}

setup_homebrew() {
  local brew_bin

  if command -v brew >/dev/null 2>&1; then
    brew_bin="$(command -v brew)"
  elif [[ -x /opt/homebrew/bin/brew ]]; then
    brew_bin=/opt/homebrew/bin/brew
  elif [[ -x /usr/local/bin/brew ]]; then
    brew_bin=/usr/local/bin/brew
  else
    log "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [[ -x /opt/homebrew/bin/brew ]]; then
      brew_bin=/opt/homebrew/bin/brew
    elif [[ -x /usr/local/bin/brew ]]; then
      brew_bin=/usr/local/bin/brew
    else
      die "Homebrew installation finished, but brew could not be found."
    fi
  fi

  eval "$("$brew_bin" shellenv)"
}

trust_tap() {
  local tap=$1

  brew tap "$tap"
  if brew trust --help >/dev/null 2>&1; then
    brew trust --tap "$tap"
  fi
}

install_formulae() {
  (($# > 0)) || return 0
  log "Installing Homebrew formulae: $*"
  brew install "$@"
}

install_casks() {
  (($# > 0)) || return 0
  log "Installing Homebrew casks: $*"
  brew install --cask "$@"
}

clone_if_missing() {
  local repository=$1
  local destination=$2

  if [[ -d "$destination/.git" ]]; then
    log "Repository already present: $destination"
    return 0
  fi

  [[ ! -e "$destination" ]] || die "$destination exists but is not a Git repository."
  git clone "$repository" "$destination"
}

ensure_symlink() {
  local source=$1
  local target=$2

  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    log "Symlink already present: $target"
    return 0
  fi

  [[ ! -e "$target" && ! -L "$target" ]] || die "Refusing to replace existing path: $target"
  ln -s "$source" "$target"
}
