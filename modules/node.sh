#!/usr/bin/env bash
set -eo pipefail

# nvm is not 'set -u' safe, so we avoid nounset entirely in this module.
# (We still keep -e and pipefail, which provides strong safety.)

if [[ ! -d "$HOME/.nvm" ]]; then
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi

export NVM_DIR="$HOME/.nvm"

# Source nvm
# shellcheck disable=SC1090
. "$NVM_DIR/nvm.sh"

# Install + use latest LTS
nvm install --lts
nvm alias default 'lts/*'
nvm use --default lts/*

# npm defaults
npm config set fund false
npm config set audit false

# Global tooling (optional; keep aligned to your semantic-release workflow)
npm i -g npm@latest
npm i -g semantic-release @semantic-release/changelog @semantic-release/git conventional-changelog-conventionalcommits

echo "Node ready: nvm + LTS + semantic-release tooling."
