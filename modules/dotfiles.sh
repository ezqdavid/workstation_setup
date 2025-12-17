#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$HOME/.local/bin"
if ! command -v chezmoi >/dev/null 2>&1; then
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
fi
chezmoi --version
echo "chezmoi installed. Next: chezmoi init --apply <your-dotfiles-repo>"
