#!/usr/bin/env bash
# setup-repos.sh — Add third-party APT repositories with GPG keys.
# Runs as root during the Docker image build. Each repo is added independently
# so that a transient network hiccup on one key does not invalidate the entire
# layer.
set -euo pipefail

ARCH="$(dpkg --print-architecture)"
CODENAME="$(. /etc/os-release && echo "${VERSION_CODENAME}")"

install -d -m 0755 /etc/apt/keyrings

add_repo() {
  local name="$1" key_url="$2" repo_line="$3"
  local keyring="/etc/apt/keyrings/${name}.gpg"
  echo "→ Adding repository: ${name}"
  curl -fsSL "$key_url" | gpg --batch --yes --dearmor -o "$keyring"
  chmod a+r "$keyring"
  echo "$repo_line" > "/etc/apt/sources.list.d/${name}.list"
}

# GitHub CLI
add_repo github-cli \
  "https://cli.github.com/packages/githubcli-archive-keyring.gpg" \
  "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/github-cli.gpg] https://cli.github.com/packages stable main"

# Docker CE
add_repo docker \
  "https://download.docker.com/linux/ubuntu/gpg" \
  "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${CODENAME} stable"

# Azure CLI
add_repo azure-cli \
  "https://packages.microsoft.com/keys/microsoft.asc" \
  "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/azure-cli.gpg] https://packages.microsoft.com/repos/azure-cli/ ${CODENAME} main"

# Node.js (version comes from build arg forwarded as env)
add_repo nodesource \
  "https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key" \
  "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main"

# Kubernetes
add_repo kubernetes \
  "https://pkgs.k8s.io/core:/stable:/v${KUBE_MINOR}/deb/Release.key" \
  "deb [signed-by=/etc/apt/keyrings/kubernetes.gpg] https://pkgs.k8s.io/core:/stable:/v${KUBE_MINOR}/deb/ /"

# Helm
add_repo helm \
  "https://baltocdn.com/helm/signing.asc" \
  "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main"

# Google Chrome
add_repo google-chrome \
  "https://dl.google.com/linux/linux_signing_key.pub" \
  "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main"

echo "✓ All repositories added."
