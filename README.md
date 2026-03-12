# Universal Dev Container for macOS

This repository provides a reusable Docker-based development workstation for Docker Desktop on macOS. It is designed for people who want one container image for most daily development tasks instead of rebuilding ad hoc environments per project.

It supports two workflows:

- plain Docker for terminal use
- VS Code or Cursor via `.devcontainer`

## What it includes

The image includes:

- core tooling: `git`, `gh`, `curl`, `jq`, `yq`, `ripgrep`, `fd`, `fzf`, `tmux`, `nano`, `vim`
- build tooling: `make`, `build-essential`, `pkg-config`
- runtimes: Python, Node.js, Go, Rust, Java
- cloud and platform CLIs: `kubectl`, `helm`, `aws`, `az`, Docker CLI, Docker Compose plugin
- AI CLIs: Codex CLI and Claude CLI
- browser tooling: Google Chrome with Xfce, Xvfb, x11vnc, and noVNC for an interactive browser session

## Why this setup

- one reusable image for general development
- persistent credentials, caches, and shell history
- Docker-outside-of-Docker support through Docker Desktop
- interactive browser access without installing a full Linux desktop on the host
- editor-friendly devcontainer support without giving up plain `docker run`

## Persistence model

The container is disposable. Your work and auth state are not.

Host bind mounts:

- project source mounted to `/workspace`
- `~/.ssh` -> `/home/dev/.ssh`
- `~/.gitconfig` -> `/home/dev/.gitconfig`
- `~/.aws` -> `/home/dev/.aws`
- `~/.azure` -> `/home/dev/.azure`
- `~/.kube` -> `/home/dev/.kube`
- `~/.config/gh` -> `/home/dev/.config/gh`

Named Docker volumes:

- `/home/dev/.cache`
- `/home/dev/.npm`
- `/home/dev/.local/share/pipx`
- `/home/dev/.local/state`
- `/home/dev/.cargo`
- `/home/dev/.rustup`
- `/home/dev/.bash_history`
- `/home/dev/.codex`
- `/home/dev/.claude`

Rebuilding the image does not remove the mounted data or named volumes.

## One-time host preparation

Make sure Docker Desktop is installed and running.

If any of these paths do not exist on your Mac, create them before you start the container:

```bash
mkdir -p ~/.ssh ~/.aws ~/.azure ~/.kube ~/.config/gh
touch ~/.gitconfig
```

If Docker Desktop prompts for file sharing access, allow access to your home directory or at least the directories listed above.

## Build and run with Docker

Build the image:

```bash
docker build -t universal-dev .
```

Run the container with persistence:

```bash
docker run -it --rm \
  --name universal-dev \
  -v "$PWD:/workspace" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$HOME/.ssh:/home/dev/.ssh" \
  -v "$HOME/.gitconfig:/home/dev/.gitconfig" \
  -v "$HOME/.aws:/home/dev/.aws" \
  -v "$HOME/.azure:/home/dev/.azure" \
  -v "$HOME/.kube:/home/dev/.kube" \
  -v "$HOME/.config/gh:/home/dev/.config/gh" \
  -v dev-cache:/home/dev/.cache \
  -v dev-npm:/home/dev/.npm \
  -v dev-pipx:/home/dev/.local/share/pipx \
  -v dev-local-state:/home/dev/.local/state \
  -v dev-cargo:/home/dev/.cargo \
  -v dev-rustup:/home/dev/.rustup \
  -v dev-bash-history:/home/dev/.bash_history \
  -v dev-codex:/home/dev/.codex \
  -v dev-claude:/home/dev/.claude \
  -p 6080:6080 \
  universal-dev
```

## Use as a devcontainer

1. Open this folder in VS Code or Cursor.
2. Choose **Reopen in Container**.
3. Wait for the image build and the `postCreateCommand` validation to finish.

The devcontainer setup uses `.devcontainer/docker-compose.yml` to preserve state and expose the browser session port.

## Repository layout

- `Dockerfile`: base image with the development toolchain
- `.devcontainer/devcontainer.json`: VS Code and Cursor integration
- `.devcontainer/docker-compose.yml`: ports, mounts, volumes, and runtime settings
- `scripts/start-browser-session.sh`: on-demand Chrome/Xfce/noVNC launcher

## Start the browser session

From inside the container:

```bash
start-browser-session
```

Then open:

```text
http://localhost:6080
```

Environment variables you can override:

- `NOVNC_PORT` defaults to `6080`
- `VNC_PORT` defaults to `5900`
- `DISPLAY_NUMBER` defaults to `99`
- `SCREEN_SIZE` defaults to `1440x900x24`
- `BROWSER_BIN` defaults to `google-chrome`

## First logins

Run these inside the container as needed:

```bash
gh auth login
aws configure
az login
codex
claude
```

Because the related config directories are persisted, these logins survive container rebuilds and recreations.

## Notes

- The container runs as the non-root user `dev`.
- `sudo` is available without a password for local development tasks.
- Docker access uses the host Docker Desktop socket rather than Docker-in-Docker.
- Large caches live in named volumes to avoid slow bind-mounted cache directories on macOS.
