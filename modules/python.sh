#!/usr/bin/env bash
set -euo pipefail

sudo apt-get update -y
sudo apt-get install -y --no-install-recommends   python3-full python3-venv python3-pip pipx   libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev   llvm libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev   git curl

# Ensure pipx path is active
python3 -m pipx ensurepath || true
mkdir -p "$HOME/.local/bin"

# Install Poetry via pipx (PEP 668 compliant)
command -v poetry >/dev/null 2>&1 || pipx install poetry
pipx install pre-commit || pipx reinstall pre-commit

# Install pyenv
[[ -d "$HOME/.pyenv" ]] || curl -fsSL https://pyenv.run | bash

# Bash init
BASHRC="$HOME/.bashrc"
touch "$BASHRC"
if ! grep -qs "PYENV_ROOT" "$BASHRC"; then
  cat >> "$BASHRC" <<'EOT'

# --- pyenv ---
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)" 2>/dev/null || true
EOT
fi

echo "Python ready: pyenv + pipx + poetry (Ubuntu 24.04 PEP668 compliant)"
