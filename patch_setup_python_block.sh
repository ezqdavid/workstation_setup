#!/usr/bin/env bash
set -euo pipefail

FILE="${1:-setup.sh}"

python_block=$(cat <<'EOF'
cat > modules/python.sh <<'EOF_PY'
#!/usr/bin/env bash
set -euo pipefail

sudo apt-get update -y
sudo apt-get install -y --no-install-recommends \
  python3-full python3-venv python3-pip pipx \
  libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
  llvm libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev \
  git curl

# Ensure pipx path is active
python3 -m pipx ensurepath || true
mkdir -p "$HOME/.local/bin"

# Install Poetry via pipx (PEP 668 compliant)
command -v poetry >/dev/null 2>&1 || pipx install poetry

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
EOF_PY
chmod +x modules/python.sh
EOF
)

# Rewrite: copy everything, but replace the python.sh heredoc section
python3 - <<PY
import re, pathlib, sys
p = pathlib.Path("$FILE")
s = p.read_text(encoding="utf-8")

# Match the whole block that writes modules/python.sh (from 'cat > modules/python.sh <<' to 'chmod +x modules/python.sh')
pat = re.compile(
    r"cat > modules/python\.sh <<'EOF'.*?^EOF\\nchmod \\+x modules/python\\.sh\\n",
    re.S | re.M
)

if not pat.search(s):
    # Fallback: match any heredoc marker after 'cat > modules/python.sh' up to chmod
    pat = re.compile(
        r"cat > modules/python\.sh <<'.*?^chmod \\+x modules/python\\.sh\\n",
        re.S | re.M
    )

m = pat.search(s)
if not m:
    print("ERROR: Could not find modules/python.sh block inside setup.sh", file=sys.stderr)
    sys.exit(2)

new_s = pat.sub("""%s\n""" % ("""$python_block"""), s, count=1)
p.write_text(new_s, encoding="utf-8")
print("Patched", p)
PY
