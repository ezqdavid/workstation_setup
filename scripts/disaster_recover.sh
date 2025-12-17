#!/usr/bin/env bash
set -euo pipefail

# Set these before running:
#   export BOOTSTRAP_REPO_SSH="git@github.com-work:ORG/workstation-bootstrap.git"
# or:
#   export BOOTSTRAP_REPO_HTTPS="https://github.com/ORG/workstation-bootstrap.git"

TARGET_DIR="${TARGET_DIR:-$HOME/dev/repos}"
REPO_DIR="${REPO_DIR:-$TARGET_DIR/workstation-bootstrap}"

if [[ -z "${BOOTSTRAP_REPO_SSH:-}" && -z "${BOOTSTRAP_REPO_HTTPS:-}" ]]; then
  echo "Set BOOTSTRAP_REPO_SSH or BOOTSTRAP_REPO_HTTPS."
  exit 2
fi

sudo apt-get update -y
sudo apt-get install -y --no-install-recommends git curl ca-certificates

mkdir -p "$TARGET_DIR"

if [[ -d "$REPO_DIR/.git" ]]; then
  echo "Repo already exists: $REPO_DIR"
else
  if [[ -n "${BOOTSTRAP_REPO_SSH:-}" ]]; then
    git clone "$BOOTSTRAP_REPO_SSH" "$REPO_DIR"
  else
    git clone "$BOOTSTRAP_REPO_HTTPS" "$REPO_DIR"
  fi
fi

cd "$REPO_DIR"
./bootstrap.sh
