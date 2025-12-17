#!/usr/bin/env bash
set -euo pipefail

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[1;34m"
NC="\033[0m"

ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
fail()  { echo -e "${RED}[FAIL]${NC} $*"; FAILED=1; }
info()  { echo -e "${BLUE}==>${NC} $*"; }

has() { command -v "$1" >/dev/null 2>&1; }

FAILED=0

info "Workstation verification (Ubuntu 24.04) - $(date)"
echo

info "OS / Kernel"
if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  echo "  OS: ${PRETTY_NAME:-unknown}"
else
  warn "Could not read /etc/os-release"
fi
echo "  Kernel: $(uname -r)"
echo

info "PATH sanity"
if echo "$PATH" | tr ':' '\n' | grep -qx "$HOME/.local/bin"; then
  ok "$HOME/.local/bin in PATH"
else
  warn "$HOME/.local/bin not in PATH (recommended). Add to $HOME/.profile or $HOME/.bashrc"
fi
echo

info "Shell / tmux / direnv"
if has tmux; then ok "tmux present"; else fail "tmux missing (run shell module)"; fi
if has direnv; then ok "direnv present"; else warn "direnv missing (base module installs it)"; fi
if grep -qs 'direnv hook bash' "$HOME/.bashrc" 2>/dev/null; then
  ok "direnv hook present in ~/.bashrc"
else
  warn "direnv hook not found in ~/.bashrc (shell module should add it)"
fi
echo

info "Git / SSH"
if has git; then ok "git present"; else fail "git missing"; fi
if [[ -f "$HOME/.ssh/config" ]]; then
  if grep -q "Host github.com-personal" "$HOME/.ssh/config"; then ok "SSH alias github.com-personal present"; else warn "SSH alias github.com-personal not found"; fi
  if grep -q "Host github.com-work" "$HOME/.ssh/config"; then ok "SSH alias github.com-work present"; else warn "SSH alias github.com-work not found"; fi
else
  warn "$HOME/.ssh/config missing (git module creates it)"
fi
echo

info "Python toolchain"
if has pyenv; then ok "pyenv present"; else warn "pyenv missing (python module)"; fi
if has poetry; then ok "poetry present"; else warn "poetry missing (python module uses pipx)"; fi
if grep -qs 'PYENV_ROOT' "$HOME/.bashrc" 2>/dev/null; then
  ok "pyenv init present in ~/.bashrc"
else
  warn "pyenv init not found in ~/.bashrc"
fi
if has pipx; then ok "pipx present"; else warn "pipx not found in PATH (open a new terminal)"; fi
echo

info "Node toolchain"
if [[ -d "$HOME/.nvm" ]]; then
  ok "$HOME/.nvm exists"
  # nvm is not nounset-safe
  set +u
  # shellcheck disable=SC1091
  . "$HOME/.nvm/nvm.sh" >/dev/null 2>&1 || true
  set -u || true

  if has node; then ok "node present: $(node -v)"; else warn "node not in PATH (open a new terminal; ensure nvm is sourced)"; fi
  if has npm; then ok "npm present"; else warn "npm missing"; fi
else
  warn "$HOME/.nvm missing (node module)"
fi
echo

info "Docker / Compose"
if has docker; then
  ok "docker present: $(docker --version | sed 's/,.*//')"
  if docker ps >/dev/null 2>&1; then
    ok "docker daemon reachable (no sudo)"
  else
    warn "docker daemon not reachable without sudo (log out/in or add user to docker group)"
  fi
else
  warn "docker not installed"
fi

if has docker && docker compose version >/dev/null 2>&1; then
  ok "docker compose plugin present"
else
  warn "docker compose plugin missing"
fi
echo

info "GPU (NVIDIA)"
if has nvidia-smi; then
  ok "nvidia-smi present"
  echo "  GPU: $(nvidia-smi --query-gpu=name,driver_version --format=csv,noheader | head -n 1)"
else
  warn "nvidia-smi missing (GPU driver not installed or not loaded; reboot after gpu module)"
fi

if has docker; then
  if docker info 2>/dev/null | grep -qi "Runtimes:.*nvidia"; then
    ok "Docker NVIDIA runtime detected"
  else
    warn "Docker NVIDIA runtime not detected (nvidia-container-toolkit may not be configured)"
  fi

  if has nvidia-smi; then
    if docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi >/dev/null 2>&1; then
      ok "Docker GPU test succeeded"
    else
      warn "Docker GPU test failed (try reboot; verify nvidia-container-toolkit + docker restart)"
    fi
  fi
fi
echo

info "Secrets tooling (sops/age/gitleaks)"
if has age; then ok "age present"; else warn "age missing"; fi
if has sops; then ok "sops present: $(sops --version 2>/dev/null | head -n 1)"; else warn "sops missing (secrets module installs it)"; fi
if has gitleaks; then ok "gitleaks present: $(gitleaks version 2>/dev/null | head -n 1)"; else warn "gitleaks missing"; fi

if [[ -f "$HOME/.config/sops/age/keys.txt" ]]; then
  ok "age key exists at ~/.config/sops/age/keys.txt"
else
  warn "age key missing (~/.config/sops/age/keys.txt). Run secrets module."
fi

if grep -qs 'SOPS_AGE_KEY_FILE' "$HOME/.bashrc" 2>/dev/null; then
  ok "SOPS_AGE_KEY_FILE exported in ~/.bashrc"
else
  warn "SOPS_AGE_KEY_FILE export not found in ~/.bashrc"
fi
echo

info "Repo hooks / lint scaffolding"
if [[ -f ".pre-commit-config.yaml" ]]; then ok ".pre-commit-config.yaml present"; else warn ".pre-commit-config.yaml missing"; fi
if [[ -d ".github/workflows" ]]; then ok "GitHub Actions workflows present"; else warn ".github/workflows missing"; fi
if [[ -f "scripts/install-dev-hooks.sh" ]]; then ok "scripts/install-dev-hooks.sh present"; else warn "scripts/install-dev-hooks.sh missing"; fi
echo

info "Hardening"
if has ufw; then ok "ufw present"; else warn "ufw missing"; fi
if systemctl is-enabled fail2ban >/dev/null 2>&1; then ok "fail2ban enabled"; else warn "fail2ban not enabled"; fi
echo

info "Summary"
if [[ "${FAILED}" -eq 0 ]]; then
  ok "All critical checks passed (warnings may remain)."
else
  fail "Some critical checks failed. Review warnings above and rerun after fixes."
fi

echo
info "Recommended next action"
echo "Open a NEW terminal to ensure PATH/Bash init changes are loaded:"
echo "  exec \$SHELL -l"
echo
