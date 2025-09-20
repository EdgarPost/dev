# Docker Development Environment
# Ubuntu 24.04 with complete development toolchain
# User: edgar with sudo access
# Theme: Catppuccin Mocha throughout

FROM ubuntu:24.04 AS base

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Install base system packages
RUN apt-get update && apt-get install -y \
    # Base system
    curl wget git unzip sudo locales tzdata \
    # Development tools
    build-essential python3 python3-pip \
    # Terminal and shell
    zsh tmux \
    # Modern CLI tools
    ripgrep fd-find fzf \
    # System utilities
    htop tree jq ca-certificates gnupg lsb-release \
    # Clipboard and display
    xclip wl-clipboard \
    # Fonts
    fontconfig \
    && rm -rf /var/lib/apt/lists/*

# Configure locales
RUN locale-gen en_US.UTF-8

# Create edgar user with sudo access
RUN useradd -m -s /bin/zsh edgar && \
    usermod -aG sudo edgar && \
    echo 'edgar ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Add additional repositories for modern tools
# DEBUG: This should run as ROOT user, not edgar
RUN apt-get update && apt-get install -y software-properties-common

# Install modern CLI tools via package managers where available
RUN apt-get update && apt-get install -y \
    # Available in Ubuntu repos
    bat eza zoxide btop \
    # Git delta
    git-delta \
    && rm -rf /var/lib/apt/lists/*

# Install Neovim via PPA for latest version
RUN add-apt-repository ppa:neovim-ppa/unstable -y && \
    apt-get update && \
    apt-get install -y neovim && \
    rm -rf /var/lib/apt/lists/*

# Install tools from releases - detect architecture
RUN ARCH=$(dpkg --print-architecture) && \
    echo "Building for architecture: $ARCH" && \
    # lsd (better ls) - not in Ubuntu repos yet
    if [ "$ARCH" = "amd64" ]; then \
        curl -sL https://github.com/lsd-rs/lsd/releases/latest/download/lsd_1.1.5_amd64.deb -o /tmp/lsd.deb; \
    else \
        curl -sL https://github.com/lsd-rs/lsd/releases/latest/download/lsd-musl_1.1.5_arm64_xz.deb -o /tmp/lsd.deb; \
    fi && \
    dpkg -i /tmp/lsd.deb && rm /tmp/lsd.deb

# yazi file manager - not in Ubuntu repos
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then \
        curl -sL https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.tar.gz | tar xz -C /tmp && \
        mv /tmp/yazi-x86_64-unknown-linux-gnu/yazi /usr/local/bin/; \
    else \
        curl -sL https://github.com/sxyazi/yazi/releases/latest/download/yazi-aarch64-unknown-linux-musl.zip -o /tmp/yazi.zip && \
        cd /tmp && unzip yazi.zip && mv yazi-*/yazi /usr/local/bin/; \
    fi && \
    rm -rf /tmp/yazi*

# lazygit - not in Ubuntu repos
RUN ARCH=$(dpkg --print-architecture) && \
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*') && \
    if [ "$ARCH" = "amd64" ]; then \
        LAZYGIT_ARCH="x86_64"; \
    else \
        LAZYGIT_ARCH="arm64"; \
    fi && \
    curl -sL "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_${LAZYGIT_ARCH}.tar.gz" | tar xz -C /tmp && \
    mv /tmp/lazygit /usr/local/bin/ && rm -f /tmp/lazygit

# Install Docker CLI via apt repository
RUN ARCH=$(dpkg --print-architecture) && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=$ARCH signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && apt-get install -y docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

# Install Kubernetes tools
# kubectl via Google's apt repository
RUN curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list && \
    apt-get update && apt-get install -y kubectl && \
    rm -rf /var/lib/apt/lists/*

# Helm via official apt repository
RUN curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor -o /usr/share/keyrings/helm.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | tee /etc/apt/sources.list.d/helm-stable-debian.list && \
    apt-get update && apt-get install -y helm && \
    rm -rf /var/lib/apt/lists/*

# k9s and kubectx/kubens - not in standard repos, use releases
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then \
        K9S_ARCH="amd64"; \
    else \
        K9S_ARCH="arm64"; \
    fi && \
    curl -sL "https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_${K9S_ARCH}.tar.gz" | tar xz -C /tmp && \
    mv /tmp/k9s /usr/local/bin/ && rm -rf /tmp/k9s*

RUN git clone https://github.com/ahmetb/kubectx /opt/kubectx && \
    ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx && \
    ln -s /opt/kubectx/kubens /usr/local/bin/kubens

# Install age via apt (available in Ubuntu 22.04+)
RUN apt-get update && apt-get install -y age && rm -rf /var/lib/apt/lists/*

# Create symlinks for fd
RUN ln -s /usr/bin/fdfind /usr/local/bin/fd

# Add custom clipboard script (before user switch)
COPY scripts/clip /usr/local/bin/clip
RUN chmod +x /usr/local/bin/clip

# Switch to edgar user for user-specific installations
USER edgar
WORKDIR /home/edgar

# Create user bin directory and install tools
RUN mkdir -p ~/.local/bin

# Starship prompt - install to user directory
RUN curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir ~/.local/bin --yes

# Atuin for shell history
RUN curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh

# Install nvm and Node.js
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
RUN bash -c 'source ~/.nvm/nvm.sh && nvm install --lts && nvm use --lts && nvm alias default node'

# Install Claude Code (user install)
RUN curl -fsSL https://claude.ai/install.sh | bash

# Create config directories
RUN mkdir -p ~/.config/{nvim,tmux,lazygit,yazi,btop,starship}

# Install LazyVim
RUN git clone https://github.com/LazyVim/starter ~/.config/nvim
RUN rm -rf ~/.config/nvim/.git

# Copy base configurations (will be overridden by volume mounts)
COPY configs/ /home/edgar/.config/

# Fix ownership of copied configs and install tmux plugin manager
RUN sudo chown -R edgar:edgar ~/.config && \
    git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm

# Install Nerd Fonts (for container consistency)
RUN mkdir -p ~/.local/share/fonts && \
    curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/FiraCode.tar.xz | tar xJ -C ~/.local/share/fonts/ && \
    fc-cache -fv

# Set up environment
ENV SHELL=/bin/zsh
ENV HOME=/home/edgar
ENV USER=edgar
ENV PATH="/home/edgar/.local/bin:$PATH"

# Configure shell
RUN echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && \
    echo 'eval "$(starship init zsh)"' >> ~/.zshrc && \
    echo 'eval "$(zoxide init zsh)"' >> ~/.zshrc && \
    echo 'eval "$(atuin init zsh)"' >> ~/.zshrc && \
    echo 'source ~/.nvm/nvm.sh' >> ~/.zshrc && \
    echo 'alias ls=lsd' >> ~/.zshrc && \
    echo 'alias cat=bat' >> ~/.zshrc && \
    echo 'alias find=fd' >> ~/.zshrc

# Set default shell
ENTRYPOINT ["/bin/zsh"]