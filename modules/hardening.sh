#!/usr/bin/env bash
set -euo pipefail
sudo apt-get update -y
sudo apt-get install -y --no-install-recommends ufw fail2ban unattended-upgrades

sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH >/dev/null 2>&1 || true
sudo ufw --force enable >/dev/null 2>&1 || true

sudo systemctl enable --now fail2ban
sudo dpkg-reconfigure -f noninteractive unattended-upgrades >/dev/null 2>&1 || true
