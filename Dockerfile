FROM ubuntu:24.04

# ---------------------------------------------------------------------------
# Build arguments — pin versions so the image is reproducible
# ---------------------------------------------------------------------------
ARG DEBIAN_FRONTEND=noninteractive
ARG TARGETARCH
ARG GO_VERSION=1.24.1
ARG YQ_VERSION=v4.45.1
ARG NODE_MAJOR=22
ARG KUBE_MINOR=1.32

# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------
ENV TZ=UTC \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PIPX_HOME=/home/dev/.local/share/pipx \
    PIPX_BIN_DIR=/home/dev/.local/bin \
    PATH=/home/dev/.local/bin:/home/dev/.cargo/bin:/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# ---------------------------------------------------------------------------
# 1. Bootstrap — minimal set of packages needed to add third-party repos
# ---------------------------------------------------------------------------
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
       apt-transport-https \
       ca-certificates \
       curl \
       gnupg \
       lsb-release \
       software-properties-common \
       sudo \
       wget \
  && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# 2. Add third-party APT repositories via a helper script
#    (avoids fragile inline GPG / shell-escaping chains)
# ---------------------------------------------------------------------------
COPY scripts/setup-repos.sh /tmp/setup-repos.sh
RUN chmod +x /tmp/setup-repos.sh \
  && NODE_MAJOR=${NODE_MAJOR} KUBE_MINOR=${KUBE_MINOR} /tmp/setup-repos.sh \
  && rm -f /tmp/setup-repos.sh

# ---------------------------------------------------------------------------
# 3. Install all development packages from base + third-party repos
# ---------------------------------------------------------------------------
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
       awscli \
       azure-cli \
       bash-completion \
       build-essential \
       dbus-x11 \
       docker-buildx-plugin \
       docker-ce-cli \
       docker-compose-plugin \
       fd-find \
       fonts-liberation \
       fzf \
       gh \
       git \
       google-chrome-stable \
       helm \
       htop \
       jq \
       kubectl \
       less \
       make \
       nano \
       nodejs \
       novnc \
       openjdk-21-jdk \
       openssh-client \
       pipx \
       pkg-config \
       procps \
       python3 \
       python3-pip \
       python3-venv \
       ripgrep \
       tar \
       tmux \
       tree \
       unzip \
       vim \
       websockify \
       x11vnc \
       xfce4 \
       xfce4-terminal \
       xvfb \
       zip \
       zsh \
  && ln -sf /usr/bin/fdfind /usr/local/bin/fd \
  && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# 4. Binary tools that are fetched outside APT (yq, Go)
# ---------------------------------------------------------------------------
RUN arch="${TARGETARCH}" \
  && case "${arch}" in \
       amd64) yq_arch="amd64"; go_arch="amd64" ;; \
       arm64) yq_arch="arm64"; go_arch="arm64" ;; \
       *) echo "Unsupported architecture: ${arch}" >&2; exit 1 ;; \
     esac \
  && curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${yq_arch}" \
       -o /usr/local/bin/yq && chmod +x /usr/local/bin/yq \
  && curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${go_arch}.tar.gz" \
       -o /tmp/go.tgz \
  && rm -rf /usr/local/go && tar -C /usr/local -xzf /tmp/go.tgz \
  && rm -f /tmp/go.tgz

# ---------------------------------------------------------------------------
# 5. Non-root user with passwordless sudo
# ---------------------------------------------------------------------------
RUN useradd -m -s /bin/bash dev \
  && echo "dev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev \
  && chmod 0440 /etc/sudoers.d/dev \
  && install -d -o dev -g dev \
       /workspace \
       /home/dev/.cache \
       /home/dev/.config/gh \
       /home/dev/.config/xfce4 \
       /home/dev/.local/bin \
       /home/dev/.local/share \
       /home/dev/.local/state \
       /home/dev/.npm \
       /home/dev/.aws \
       /home/dev/.azure \
       /home/dev/.kube \
       /home/dev/.ssh \
       /home/dev/.codex \
       /home/dev/.claude

# ---------------------------------------------------------------------------
# 6. User-level toolchains — Rust, Node globals
# ---------------------------------------------------------------------------
RUN su - dev -c 'curl -fsSL https://sh.rustup.rs | sh -s -- -y --profile minimal'

RUN su - dev -c '\
  npm config set prefix /home/dev/.local \
  && npm install -g @openai/codex @anthropic-ai/claude-code'

# ---------------------------------------------------------------------------
# 7. Shell bootstrap for all login shells
# ---------------------------------------------------------------------------
RUN printf '%s\n' \
      'export EDITOR=nano' \
      'export PAGER="less -R"' \
      'export HISTFILE=/home/dev/.bash_history' \
      'export HISTSIZE=50000' \
      'export HISTFILESIZE=50000' \
      'export PATH=/home/dev/.local/bin:/home/dev/.cargo/bin:/usr/local/go/bin:${PATH}' \
      'alias ll="ls -alF --color=auto"' \
      'alias la="ls -A --color=auto"' \
      'alias l="ls -CF --color=auto"' \
      > /etc/profile.d/dev-bootstrap.sh \
  && chmod 0644 /etc/profile.d/dev-bootstrap.sh \
  && touch /home/dev/.bash_history \
  && chown dev:dev /home/dev/.bash_history

# ---------------------------------------------------------------------------
# 8. Helper scripts
# ---------------------------------------------------------------------------
COPY scripts/start-browser-session.sh /usr/local/bin/start-browser-session
RUN chmod +x /usr/local/bin/start-browser-session

# ---------------------------------------------------------------------------
# Runtime defaults
# ---------------------------------------------------------------------------
USER dev
WORKDIR /workspace
EXPOSE 6080
CMD ["sleep", "infinity"]
