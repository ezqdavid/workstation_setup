#!/usr/bin/env bash
set -euo pipefail

# --- Dependencies ---
sudo apt-get update -y
sudo apt-get install -y --no-install-recommends curl gnupg age

mkdir -p "$HOME/.local/bin"

# --- Install sops (official binary) ---
if ! command -v sops >/dev/null 2>&1; then
  ARCH="$(dpkg --print-architecture)"
  case "$ARCH" in
    amd64) SOPS_ARCH="amd64" ;;
    arm64) SOPS_ARCH="arm64" ;;
    *) echo "Unsupported arch: $ARCH"; exit 1 ;;
  esac

  VERSION="3.9.0"
  curl -fsSL -o /tmp/sops.deb \
    "https://github.com/getsops/sops/releases/download/v${VERSION}/sops_${VERSION}_${SOPS_ARCH}.deb"
  sudo dpkg -i /tmp/sops.deb
  rm -f /tmp/sops.deb
fi

# --- Install gitleaks (official binary) ---
if ! command -v gitleaks >/dev/null 2>&1; then
  ARCH="$(dpkg --print-architecture)"
  case "$ARCH" in
    amd64) GL_ARCH="x64" ;;
    arm64) GL_ARCH="arm64" ;;
    *) echo "Unsupported arch: $ARCH"; exit 1 ;;
  esac

  VERSION="8.20.1"
  curl -fsSL -o /tmp/gitleaks.tgz \
    "https://github.com/gitleaks/gitleaks/releases/download/v${VERSION}/gitleaks_${VERSION}_linux_${GL_ARCH}.tar.gz"
  tar -xzf /tmp/gitleaks.tgz -C /tmp
  install -m 0755 /tmp/gitleaks "$HOME/.local/bin/gitleaks"
  rm -f /tmp/gitleaks /tmp/gitleaks.tgz
fi

# --- Age key (for sops) ---
mkdir -p "$HOME/.config/sops/age"
if [[ ! -f "$HOME/.config/sops/age/keys.txt" ]]; then
  age-keygen -o "$HOME/.config/sops/age/keys.txt"
fi

# --- Export key path ---
BASHRC="$HOME/.bashrc"
touch "$BASHRC"
grep -qs 'SOPS_AGE_KEY_FILE' "$BASHRC" || \
echo "export SOPS_AGE_KEY_FILE=\"\$HOME/.config/sops/age/keys.txt\"" >> "$BASHRC"

echo "Secrets ready: sops + age + gitleaks"
echo "Age public key:"
age-keygen -y "$HOME/.config/sops/age/keys.txt"
