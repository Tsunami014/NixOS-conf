#!/usr/bin/env bash
if [ "${1:-}" = "own" ]; then
  sudo chown -R "$USER" /etc/nixos/users
  exit 0
fi
sudo chown root:config /etc/nixos/*
sudo chmod 771 /etc/nixos/programs /etc/nixos/users # Directories are executable
sudo find /etc/nixos -maxdepth 1 -type f -exec chmod 660 {} + # Normal files
sudo chown root:config -R /etc/nixos/.git
sudo chown -R root:config /etc/nixos/.git
sudo find /etc/nixos/.git -type d -exec chmod 771 {} +
sudo find /etc/nixos/.git -type f -exec chmod 660 {} +
sudo chown root:config -R /etc/nixos/programs
sudo chmod 771 -R /etc/nixos/programs
sudo chmod +x /etc/nixos/programs/*
for folder in /etc/nixos/users/*; do
  name=$(basename "$folder")
  sudo chown -R "$name:users" "$folder"
  if [ -f "$folder/sync.sh" ]; then
    sudo chmod +x "$folder/sync.sh"
  fi
done
