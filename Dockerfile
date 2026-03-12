FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG TARGETARCH
ARG GO_VERSION=1.24.1
ARG YQ_VERSION=v4.45.1
ARG NODE_MAJOR=22

ENV TZ=UTC
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV PIPX_HOME=/home/dev/.local/share/pipx
ENV PIPX_BIN_DIR=/home/dev/.local/bin
ENV PATH=/home/dev/.local/bin:/home/dev/.cargo/bin:/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gpg \
    lsb-release \
    software-properties-common \
    sudo \
    wget \
  && install -d -m 0755 /etc/apt/keyrings \
  && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
  && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
  && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
  && chmod a+r /etc/apt/keyrings/docker.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${VERSION_CODENAME}") stable" > /etc/apt/sources.list.d/docker.list \
  && curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg \
  && chmod a+r /etc/apt/keyrings/microsoft.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $(. /etc/os-release && echo "${VERSION_CODENAME}") main" > /etc/apt/sources.list.d/azure-cli.list \
  && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
  && chmod a+r /etc/apt/keyrings/nodesource.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" > /etc/apt/sources.list.d/nodesource.list \
  && curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg \
  && chmod a+r /etc/apt/keyrings/kubernetes-apt-keyring.gpg \
  && echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /" > /etc/apt/sources.list.d/kubernetes.list \
  && curl -fsSL https://baltocdn.com/helm/signing.asc | gpg --dearmor -o /etc/apt/keyrings/helm.gpg \
  && chmod a+r /etc/apt/keyrings/helm.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" > /etc/apt/sources.list.d/helm.list \
  && curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg \
  && chmod a+r /etc/apt/keyrings/google-chrome.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
  && apt-get update \
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
    gnupg \
    google-chrome-stable \
    helm \
    htop \
    jq \
    kubectl \
    less \
    make \
    nano \
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
    sudo \
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
  && rm -rf /var/lib/apt/lists/*

RUN ln -sf /usr/bin/fdfind /usr/local/bin/fd \
  && arch="${TARGETARCH}" \
  && case "${arch}" in \
       amd64) yq_arch="amd64"; go_arch="amd64" ;; \
       arm64) yq_arch="arm64"; go_arch="arm64" ;; \
       *) echo "Unsupported architecture: ${arch}" >&2; exit 1 ;; \
     esac \
  && curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${yq_arch}" -o /usr/local/bin/yq \
  && chmod +x /usr/local/bin/yq \
  && curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${go_arch}.tar.gz" -o /tmp/go.tgz \
  && rm -rf /usr/local/go \
  && tar -C /usr/local -xzf /tmp/go.tgz \
  && rm -f /tmp/go.tgz

RUN useradd -m -s /bin/bash dev \
  && echo "dev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev \
  && chmod 0440 /etc/sudoers.d/dev \
  && install -d -o dev -g dev /workspace /home/dev/.cache /home/dev/.config/gh /home/dev/.config/xfce4 /home/dev/.local/bin /home/dev/.local/share /home/dev/.local/state /home/dev/.npm /home/dev/.aws /home/dev/.azure /home/dev/.kube /home/dev/.ssh /home/dev/.codex /home/dev/.claude

RUN su - dev -c 'curl -fsSL https://sh.rustup.rs | sh -s -- -y --profile minimal' \
  && su - dev -c 'npm config set prefix /home/dev/.local && npm install -g @openai/codex @anthropic-ai/claude-code'

RUN printf '%s\n' \
    'export EDITOR=nano' \
    'export PAGER="less -R"' \
    'export HISTFILE=/home/dev/.bash_history' \
    'export PATH=/home/dev/.local/bin:/home/dev/.cargo/bin:/usr/local/go/bin:${PATH}' \
    'alias ll="ls -alF --color=auto"' \
    'alias la="ls -A --color=auto"' \
    'alias l="ls -CF --color=auto"' \
    > /etc/profile.d/dev-bootstrap.sh \
  && chmod 0644 /etc/profile.d/dev-bootstrap.sh \
  && touch /home/dev/.bash_history \
  && chown dev:dev /home/dev/.bash_history

COPY scripts/start-browser-session.sh /usr/local/bin/start-browser-session

RUN chmod +x /usr/local/bin/start-browser-session

USER dev
WORKDIR /workspace

EXPOSE 6080

CMD ["sleep", "infinity"]
