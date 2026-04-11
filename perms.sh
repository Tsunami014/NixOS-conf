#!/usr/bin/env bash
sudo chown root:config /etc/nixos/*
sudo chmod 771 /etc/nixos/*
sudo chown root:config -R /etc/nixos/.git
sudo chmod 771 -R /etc/nixos/.git
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
