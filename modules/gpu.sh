#!/usr/bin/env bash
set -euo pipefail
sudo apt-get update -y
sudo apt-get install -y --no-install-recommends ubuntu-drivers-common ca-certificates curl gnupg

sudo ubuntu-drivers autoinstall

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /etc/apt/keyrings/nvidia-container-toolkit.gpg
sudo chmod a+r /etc/apt/keyrings/nvidia-container-toolkit.gpg

distribution=$(. /etc/os-release;echo "${ID}${VERSION_ID}")
curl -fsSL "https://nvidia.github.io/libnvidia-container/${distribution}/libnvidia-container.list" \
  | sed 's#deb https://#deb [signed-by=/etc/apt/keyrings/nvidia-container-toolkit.gpg] https://#g' \
  | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list >/dev/null

sudo apt-get update -y
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
