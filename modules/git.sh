#!/usr/bin/env bash
set -euo pipefail

git config --global init.defaultBranch main
git config --global fetch.prune true
git config --global pull.rebase false
git config --global rerere.enabled true

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
touch "$HOME/.ssh/config"
chmod 600 "$HOME/.ssh/config"

grep -qs "Host github.com-personal" "$HOME/.ssh/config" || cat >> "$HOME/.ssh/config" <<'EOT'

# --- Multi-identity GitHub SSH scaffold ---
Host github.com-personal
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_personal
  IdentitiesOnly yes

Host github.com-work
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_work
  IdentitiesOnly yes
EOT
