#!/usr/bin/env bash
set -euo pipefail
sudo apt-get update -y
sudo apt-get install -y --no-install-recommends tmux

touch "$HOME/.bashrc"
grep -qs 'direnv hook bash' "$HOME/.bashrc" || cat >> "$HOME/.bashrc" <<'EOT'

# --- Dev bootstrap ---
export PATH="$HOME/.local/bin:$PATH"
eval "$(direnv hook bash)"
EOT
