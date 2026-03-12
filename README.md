# Universal Dev Container

A self-contained, reproducible Docker-based development workstation. The container is fully isolated from the host — no host configuration files are bind-mounted in. All credentials, caches, and state live inside named Docker volumes.

It supports two workflows:

- plain Docker for terminal use
- VS Code or Cursor via `.devcontainer`

## What it includes

The image includes:

- **Core tooling**: `git`, `gh`, `curl`, `jq`, `yq`, `ripgrep`, `fd`, `fzf`, `tmux`, `nano`, `vim`, `zsh`
- **Build tooling**: `make`, `build-essential`, `pkg-config`
- **Runtimes**: Python 3, Node.js 22, Go, Rust, Java 21
- **Cloud / platform CLIs**: `kubectl`, `helm`, `aws`, `az`, Docker CLI, Docker Compose / Buildx plugins
- **AI CLIs**: Codex CLI, Claude CLI
- **Browser tooling**: Google Chrome with Xfce, Xvfb, x11vnc, and noVNC for an interactive browser session

## Isolation model

The container is disposable. Your data survives rebuilds through **named Docker volumes only** — there are **no host bind mounts** for configuration files.

Named Docker volumes:

| Volume | Container path |
|---|---|
| `dev-ssh` | `/home/dev/.ssh` |
| `dev-gitconfig` | `/home/dev/.gitconfig` |
| `dev-aws` | `/home/dev/.aws` |
| `dev-azure` | `/home/dev/.azure` |
| `dev-kube` | `/home/dev/.kube` |
| `dev-gh` | `/home/dev/.config/gh` |
| `dev-cache` | `/home/dev/.cache` |
| `dev-npm` | `/home/dev/.npm` |
| `dev-pipx` | `/home/dev/.local/share/pipx` |
| `dev-local-state` | `/home/dev/.local/state` |
| `dev-cargo` | `/home/dev/.cargo` |
| `dev-rustup` | `/home/dev/.rustup` |
| `dev-bash-history` | `/home/dev/.bash_history` |
| `dev-codex` | `/home/dev/.codex` |
| `dev-claude` | `/home/dev/.claude` |

The only host path touched is the project source (mounted to `/workspace`) and, optionally, the Docker socket for Docker-outside-of-Docker.

Rebuilding the image does not remove the named volumes.

## Build and run with Docker

Build the image:

```bash
docker build -t universal-dev .
```

Run the container with full isolation:

```bash
docker run -it --rm \
  --name universal-dev \
  -v "$PWD:/workspace" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v dev-ssh:/home/dev/.ssh \
  -v dev-gitconfig:/home/dev/.gitconfig \
  -v dev-aws:/home/dev/.aws \
  -v dev-azure:/home/dev/.azure \
  -v dev-kube:/home/dev/.kube \
  -v dev-gh:/home/dev/.config/gh \
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

The devcontainer setup uses `.devcontainer/docker-compose.yml` to persist state in named volumes and expose the browser-session port.

## Repository layout

| File | Purpose |
|---|---|
| `Dockerfile` | Base image with the full development toolchain |
| `scripts/setup-repos.sh` | Helper that adds third-party APT repos and GPG keys during build |
| `scripts/start-browser-session.sh` | On-demand Chrome / Xfce / noVNC launcher |
| `.devcontainer/devcontainer.json` | VS Code and Cursor integration |
| `.devcontainer/docker-compose.yml` | Ports, named volumes, and runtime settings |

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

| Variable | Default |
|---|---|
| `NOVNC_PORT` | `6080` |
| `VNC_PORT` | `5900` |
| `DISPLAY_NUMBER` | `99` |
| `SCREEN_SIZE` | `1440x900x24` |
| `BROWSER_BIN` | `google-chrome` |

## First-time setup

Run these inside the container as needed:

```bash
gh auth login
aws configure
az login
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
ssh-keygen -t ed25519 -C "you@example.com"
```

Because every config directory is backed by a named volume, these settings survive container rebuilds and recreations.

## Notes

- The container runs as the non-root user `dev` with passwordless `sudo`.
- Docker access uses the host Docker Desktop socket (Docker-outside-of-Docker), not Docker-in-Docker.
- All third-party APT repositories are added through `scripts/setup-repos.sh` during the build, keeping the Dockerfile clean and the build more resilient to transient GPG errors.
- Large caches and toolchains live in named volumes to avoid slow bind-mounted directories on macOS.
