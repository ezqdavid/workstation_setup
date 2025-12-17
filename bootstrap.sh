#!/usr/bin/env bash
set -euo pipefail

DEV_ROOT="${DEV_ROOT:-$HOME/dev}"
INSTALL_BASE="${INSTALL_BASE:-1}"
INSTALL_SHELL="${INSTALL_SHELL:-1}"
INSTALL_DOTFILES="${INSTALL_DOTFILES:-1}"
INSTALL_GIT="${INSTALL_GIT:-1}"
INSTALL_PYTHON="${INSTALL_PYTHON:-1}"
INSTALL_NODE="${INSTALL_NODE:-1}"
INSTALL_DOCKER="${INSTALL_DOCKER:-1}"
INSTALL_GPU="${INSTALL_GPU:-1}"
INSTALL_SECRETS="${INSTALL_SECRETS:-1}"
INSTALL_BACKUP="${INSTALL_BACKUP:-1}"
INSTALL_MONITORING="${INSTALL_MONITORING:-1}"
INSTALL_HARDENING="${INSTALL_HARDENING:-1}"

log() { printf "\n\033[1;34m==>\033[0m %s\n" "$*"; }
run_module() { log "Running module: $1"; bash "modules/$1.sh"; }

mkdir -p "$DEV_ROOT"/{repos,sandbox,notes,scripts,tmp}

[[ "$INSTALL_BASE" == "1" ]]       && run_module base
[[ "$INSTALL_SHELL" == "1" ]]      && run_module shell
[[ "$INSTALL_GIT" == "1" ]]        && run_module git
[[ "$INSTALL_DOTFILES" == "1" ]]   && run_module dotfiles
[[ "$INSTALL_PYTHON" == "1" ]]     && run_module python
[[ "$INSTALL_NODE" == "1" ]]       && run_module node
[[ "$INSTALL_DOCKER" == "1" ]]     && run_module docker
[[ "$INSTALL_GPU" == "1" ]]        && run_module gpu
[[ "$INSTALL_SECRETS" == "1" ]]    && run_module secrets
[[ "$INSTALL_HARDENING" == "1" ]]  && run_module hardening
[[ "$INSTALL_BACKUP" == "1" ]]     && run_module backup
[[ "$INSTALL_MONITORING" == "1" ]] && run_module monitoring

log "Bootstrap complete."
echo "Next:"
echo "  - Open a new terminal (or: exec \$SHELL -l)"
echo "  - Docker group change requires log out/in (or reboot)"
echo "  - GPU driver: reboot recommended"
echo "  - Install hooks: ./scripts/install-dev-hooks.sh"
