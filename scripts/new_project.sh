#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/new_project.sh <type> <name> [--dir <path>] [--with devstack] [--with dbt] [--with devcontainer] [--init-git] [--no-hooks]

Types:
  python      Poetry + src layout + ruff/black/pytest + per-project Jupyter
  next        Next.js (create-next-app) + prettier/eslint scaffold + semantic-release config stub
  data        Python + dbt + devstack (Postgres/Mongo/ClickHouse) + seed placeholders

Examples:
  ./scripts/new_project.sh python myproj --init-git --with devcontainer
  ./scripts/new_project.sh next webapp --dir ~/dev/repos --init-git --with devcontainer
  ./scripts/new_project.sh data analytics-lab --with devstack --with dbt --init-git --with devcontainer
USAGE
}

TYPE="${1:-}"
NAME="${2:-}"
shift 2 || true

TARGET_DIR="${TARGET_DIR:-$HOME/dev/repos}"
WITH_DEVSTACK=0
WITH_DBT=0
WITH_DEVCONTAINER=0
INIT_GIT=0
NO_HOOKS=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir) TARGET_DIR="$2"; shift 2 ;;
    --with)
      case "${2:-}" in
        devstack) WITH_DEVSTACK=1 ;;
        dbt) WITH_DBT=1 ;;
        devcontainer) WITH_DEVCONTAINER=1 ;;
        *) echo "Unknown --with option: ${2:-}"; exit 2 ;;
      esac
      shift 2
      ;;
    --init-git) INIT_GIT=1; shift ;;
    --no-hooks) NO_HOOKS=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1"; usage; exit 2 ;;
  esac
done

if [[ -z "$TYPE" || -z "$NAME" ]]; then usage; exit 2; fi

ROOT="$TARGET_DIR/$NAME"
if [[ -e "$ROOT" ]]; then echo "Target exists: $ROOT"; exit 1; fi

mkdir -p "$ROOT"
cd "$ROOT"

# ---------- shared repo standards ----------
mkdir -p .github/workflows scripts docs

cat > .editorconfig <<'EOT'
root = true
[*]
end_of_line = lf
insert_final_newline = true
charset = utf-8
indent_style = space
indent_size = 2
trim_trailing_whitespace = true
EOT

cat > .gitignore <<'EOT'
.venv/
.env
.env.*
!.env.enc
__pycache__/
*.pyc
node_modules/
dist/
build/
.config/sops/age/keys.txt
EOT

# SOPS conventions (optional, but included by default)
cat > .sops.yaml <<'EOT'
creation_rules:
  - path_regex: '.*\.env\.enc$'
    encrypted_regex: '^(.*)$'
    age: >-
      REPLACE_WITH_YOUR_AGE_PUBLIC_KEY
EOT

# Pre-commit baseline (works once pre-commit is installed via pipx)
cat > .pre-commit-config.yaml <<'EOT'
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v5.0.0
    hooks:
      - id: check-yaml
      - id: end-of-file-fixer
      - id: trailing-whitespace
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.20.1
    hooks:
      - id: gitleaks
        args: ["--redact"]
EOT

# CI: pre-commit + gitleaks + shellcheck via reviewdog if shell scripts exist
cat > .github/workflows/ci.yml <<'EOT'
name: CI
on:
  pull_request:
  push:
    branches: [ main ]
permissions:
  contents: read
  pull-requests: write
jobs:
  precommit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: "3.11" }
      - run: pip install pre-commit
      - run: pre-commit run -a
  gitleaks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - uses: gitleaks/gitleaks-action@v2
        env: { GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }} }
EOT

# Devcontainer (optional)
write_devcontainer() {
  mkdir -p .devcontainer
  cat > .devcontainer/devcontainer.json <<'EOT'
{
  "name": "project",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu-24.04",
  "features": {
    "ghcr.io/devcontainers/features/python:1": { "version": "3.11" },
    "ghcr.io/devcontainers/features/node:1": { "version": "lts" }
  },
  "postCreateCommand": "pip install pre-commit && pre-commit install || true",
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-azuretools.vscode-docker",
        "ms-python.python",
        "esbenp.prettier-vscode",
        "dbaeumer.vscode-eslint",
        "redhat.vscode-yaml",
        "eamodio.gitlens"
      ]
    }
  }
}
EOT
}

# Devstack compose (optional)
write_devstack() {
  cat > docker-compose.yml <<'EOT'
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: postgres
      POSTGRES_USER: postgres
      POSTGRES_DB: app
    ports: ["5432:5432"]
    volumes: [ "pgdata:/var/lib/postgresql/data" ]

  mongo:
    image: mongo:7
    ports: ["27017:27017"]
    volumes: [ "mongodata:/data/db" ]

  clickhouse:
    image: clickhouse/clickhouse-server:24
    ports: ["8123:8123", "9000:9000"]
    volumes: [ "chdata:/var/lib/clickhouse" ]

volumes:
  pgdata:
  mongodata:
  chdata:
EOT

  cat > scripts/devstack.sh <<'EOT'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  up) docker compose up -d ;;
  down) docker compose down -v ;;
  ps) docker compose ps ;;
  *) echo "Usage: ./scripts/devstack.sh {up|down|ps}"; exit 2 ;;
esac
EOT
  chmod +x scripts/devstack.sh
}

# dbt stub (optional)
write_dbt() {
  mkdir -p dbt/{models,seeds,macros}
  cat > dbt/README.md <<'EOT'
# dbt stub
Recommended:
  - dbt init inside this folder (or add to Poetry group)
  - dbt seed / run / test
EOT
}

# ---------- type-specific scaffolds ----------
case "$TYPE" in
  python)
    mkdir -p src tests
    cat > pyproject.toml <<'EOT'
[tool.poetry]
name = "app"
version = "0.1.0"
description = ""
authors = ["You <you@example.com>"]
packages = [{ include = "src" }]

[tool.poetry.dependencies]
python = "^3.11"

[tool.poetry.group.dev.dependencies]
ruff = "*"
black = "*"
pytest = "*"
jupyterlab = "*"

[tool.ruff]
line-length = 100

[tool.black]
line-length = 100
EOT

    cat > src/__init__.py <<'EOT'
__all__ = []
EOT

    cat > README.md <<'EOT'
# Python project (Poetry + src)

## Setup
- pyenv local 3.11.x
- poetry install

## Commands
- poetry run ruff check .
- poetry run black .
- poetry run pytest
- poetry run jupyter lab
EOT
    ;;

  next)
    # Requires node+npx (assumed installed on your machine)
    if ! command -v npx >/dev/null 2>&1; then
      echo "npx not found. Install Node via your bootstrap first."; exit 1
    fi
    npx create-next-app@latest . --yes

    # add minimal repo standards (prettier/eslint are typically included; keep this lightweight)
    cat > README.md <<'EOT'
# Next.js project

## Run
npm install
npm run dev
EOT

    # semantic-release stub (optional; you can refine)
    cat > .releaserc.json <<'EOT'
{
  "branches": ["main"],
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    "@semantic-release/changelog",
    "@semantic-release/git"
  ]
}
EOT
    ;;

  data)
    PKG_NAME="$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/_/g; s/^_+|_+$//g')"
    # data == python + dbt + devstack by default
    mkdir -p "src/$PKG_NAME" tests
    cat > pyproject.toml <<EOT
[tool.poetry]
name = "$NAME"
version = "0.1.0"
description = ""
authors = ["You <you@example.com>"]
readme = "README.md"
packages = [{ include = "$PKG_NAME", from = "src" }]

[tool.poetry.dependencies]
python = ">=3.11,<3.13"
pandas = "*"
pyarrow = "*"

[tool.poetry.group.dev.dependencies]
ruff = "*"
black = "*"
pytest = "*"
jupyterlab = "*"

[tool.ruff]
line-length = 100

[tool.black]
line-length = 100
EOT

    cat > "src/$PKG_NAME/__init__.py" <<'EOT'
__all__ = []
EOT

    cat > README.md <<EOT
# $NAME (Data)

Includes:
- Poetry + src layout
- Optional devstack (Postgres/Mongo/ClickHouse)
- Optional dbt stub
EOT
    WITH_DEVSTACK=1
    WITH_DBT=1
    ;;
  *)
    echo "Unknown type: $TYPE"; usage; exit 2 ;;
esac

[[ "$WITH_DEVSTACK" == "1" ]] && write_devstack
[[ "$WITH_DBT" == "1" ]] && write_dbt
[[ "$WITH_DEVCONTAINER" == "1" ]] && write_devcontainer

# ---------- git init + hooks ----------
if [[ "$INIT_GIT" == "1" ]]; then
  git init
  git branch -M main
  git add .
  git commit -m "chore: initial commit" || true

  if [[ "$NO_HOOKS" == "0" ]]; then
    if command -v pre-commit >/dev/null 2>&1; then
      pre-commit install || true
    fi
  fi
fi

echo "Created: $ROOT"
echo "Next:"
echo "  cd $ROOT"
case "$TYPE" in
  python|data) echo "  poetry install" ;;
  next) echo "  npm install" ;;
esac
