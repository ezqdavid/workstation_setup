#!/usr/bin/env bash
set -euo pipefail
command -v node >/dev/null 2>&1 || { echo "Node required"; exit 1; }
npm init -y >/dev/null 2>&1 || true
npm i -D husky @commitlint/cli @commitlint/config-conventional >/dev/null
npx husky init >/dev/null
cat > .husky/commit-msg <<'EOT'
#!/usr/bin/env sh
. "$(dirname "$0")/_/husky.sh"
npx --no -- commitlint --edit "$1"
EOT
chmod +x .husky/commit-msg
cat > commitlint.config.cjs <<'EOT'
module.exports = { extends: ['@commitlint/config-conventional'] };
EOT
echo "Hooks installed."
