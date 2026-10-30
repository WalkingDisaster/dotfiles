#!/usr/bin/env bash
# Dotfiles bootstrap for dev containers (VS Code / devcontainer CLI run this
# after cloning). Installs zsh and Oh My Zsh and makes zsh the login shell.
# Safe to re-run: every step checks whether it is already done.
set -euo pipefail

log() { printf 'dotfiles: %s\n' "$*"; }

# Run a command as root: directly if we are root, otherwise via passwordless sudo.
as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
    sudo "$@"
  else
    return 1
  fi
}

install_packages() {
  local missing=()
  for pkg in zsh git curl; do
    command -v "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
  done
  [ ${#missing[@]} -eq 0 ] && return 0

  if ! command -v apt-get >/dev/null 2>&1; then
    log "missing ${missing[*]} and apt-get is unavailable; install them in the image"
    return 1
  fi
  if ! as_root true; then
    log "missing ${missing[*]} and no root or passwordless sudo; add them to the image"
    return 1
  fi
  log "installing ${missing[*]}"
  if ! as_root env DEBIAN_FRONTEND=noninteractive apt-get update -qq ||
     ! as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends -o Dpkg::Options::=--force-confold "${missing[@]}"; then
    log "could not install ${missing[*]}"
    return 1
  fi
}

install_oh_my_zsh() {
  local dir="${ZSH:-$HOME/.oh-my-zsh}"
  if [ -d "$dir" ]; then
    log "Oh My Zsh already installed"
    return 0
  fi
  log "installing Oh My Zsh"
  # RUNZSH=no: don't start zsh at the end. CHSH=no: we change the shell below.
  # KEEP_ZSHRC=yes: never overwrite an existing ~/.zshrc.
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
}

# agnoster needs a Powerline-patched font in the terminal on the host.
set_theme() {
  local theme=agnoster zshrc="$HOME/.zshrc"
  if grep -q '^ZSH_THEME=' "$zshrc" 2>/dev/null; then
    sed -i "s/^ZSH_THEME=.*/ZSH_THEME=\"$theme\"/" "$zshrc"
  else
    log "no ZSH_THEME line in $zshrc; leaving it alone"
  fi
}

set_login_shell() {
  local zsh_path user current
  zsh_path="$(command -v zsh)"
  user="$(id -un)"
  current="$(getent passwd "$user" | cut -d: -f7)"
  [ "$current" = "$zsh_path" ] && return 0

  if as_root chsh -s "$zsh_path" "$user"; then
    log "login shell set to $zsh_path"
    return 0
  fi

  # No root: hand interactive bash sessions over to zsh instead.
  local marker='# dotfiles: switch to zsh'
  if ! grep -qF "$marker" "$HOME/.bashrc" 2>/dev/null; then
    log "cannot chsh; interactive bash will exec zsh instead"
    cat >>"$HOME/.bashrc" <<EOF

$marker
if [[ \$- == *i* ]] && [ -z "\${ZSH_VERSION:-}" ] && command -v zsh >/dev/null 2>&1; then
  exec zsh -l
fi
EOF
  fi
}

if install_packages; then
  install_oh_my_zsh
  set_theme
  set_login_shell
else
  log "skipping Oh My Zsh"
fi
