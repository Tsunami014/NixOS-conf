#!/usr/bin/env bash
fixPerms() {
  sudo chown root:root /etc/nixos/*
  sudo chown root:root -R /etc/nixos/.git
  for folder in /etc/nixos/users/*; do
    name=$(basename "$folder")
    sudo chown "$name" "$folder"
  done
}
case "${1:-}" in
  fix ) fixPerms ;;
  lazygit )
    sudo chown "$USER" -R /etc/nixos/.git
    prev=$(pwd)
    cd /etc/nixos
    lazygit || true
    cd "$prev"
    fixPerms
    ;;
  *)
    echo "Usage:
  $0 fix - Fixes permissions in /etc/nixos
  $0 lazygit - Runs lazygit in /etc/nixos as the current user but gives temporary permission to the git folder
esac
" ;;
esac
