#!/usr/bin/env bash
set -euo pipefail

sudo apt-get update -y
sudo apt-get install -y --no-install-recommends \
  ca-certificates curl wget gnupg lsb-release software-properties-common \
  build-essential pkg-config make cmake \
  git openssh-client unzip zip xz-utils \
  jq tree htop ripgrep fd-find fzf bat direnv neovim \
  net-tools dnsutils iputils-ping

mkdir -p "$HOME/.local/bin"
command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1 && ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1 && ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"

# Ensure ~/.local/bin is in PATH for interactive shells
grep -qs "export PATH=\"\$HOME/.local/bin:\$PATH\"" "$HOME/.profile" || echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$HOME/.profile"
