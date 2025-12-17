#!/usr/bin/env bash
set -euo pipefail

sudo apt-get update -y
sudo apt-get install -y --no-install-recommends ubuntu-drivers-common ca-certificates curl gnupg

# 1) Install recommended NVIDIA driver (Ubuntu-managed)
sudo ubuntu-drivers autoinstall

# 2) Install NVIDIA Container Toolkit (official "stable/deb" repo method)
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
  | sudo gpg --dearmor -o /etc/apt/keyrings/nvidia-container-toolkit.gpg
sudo chmod a+r /etc/apt/keyrings/nvidia-container-toolkit.gpg

curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
  | sed 's#deb https://#deb [signed-by=/etc/apt/keyrings/nvidia-container-toolkit.gpg] https://#g' \
  | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list >/dev/null

sudo apt-get update -y
sudo apt-get install -y nvidia-container-toolkit

# Configure Docker runtime
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

cat <<'EOT'
GPU module installed.
Recommended: reboot.

Validate:
  nvidia-smi
  docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
EOT
