#!/usr/bin/env bash
set -euo pipefail
sudo apt-get update -y
sudo apt-get install -y --no-install-recommends age sops

if ! command -v gitleaks >/dev/null 2>&1; then
  TMP="$(mktemp -d)"
  cd "$TMP"
  VERSION="8.20.1"
  curl -fsSL -o gitleaks.tgz "https://github.com/gitleaks/gitleaks/releases/download/v${VERSION}/gitleaks_${VERSION}_linux_x64.tar.gz"
  tar -xzf gitleaks.tgz
  install -m 0755 gitleaks "$HOME/.local/bin/gitleaks"
  cd - >/dev/null
  rm -rf "$TMP"
fi

mkdir -p "$HOME/.config/sops/age"
[[ -f "$HOME/.config/sops/age/keys.txt" ]] || age-keygen -o "$HOME/.config/sops/age/keys.txt"
grep -qs 'SOPS_AGE_KEY_FILE' "$HOME/.bashrc" || echo 'export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"' >> "$HOME/.bashrc"
