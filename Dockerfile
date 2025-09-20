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

# Switch to edgar user
USER edgar
WORKDIR /home/edgar

# Add additional repositories for modern tools
RUN apt-get update && apt-get install -y software-properties-common

# Install modern CLI tools via package managers where available
RUN apt-get update && apt-get install -y \
    # Available in Ubuntu repos
    bat exa zoxide btop \
    # Git delta
    git-delta \
    && rm -rf /var/lib/apt/lists/*

# Install tools that need specific installation methods
# Starship prompt
RUN curl -sS https://starship.rs/install.sh | sh -s -- --yes

# Atuin for shell history
RUN curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh

# lsd (better ls) - not in Ubuntu repos yet
RUN curl -sL https://github.com/Peltoche/lsd/releases/latest/download/lsd_1.1.5_amd64.deb -o /tmp/lsd.deb && \
    sudo dpkg -i /tmp/lsd.deb && rm /tmp/lsd.deb

# yazi file manager - not in Ubuntu repos
RUN curl -sL https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.tar.gz | tar xz -C /tmp && \
    sudo mv /tmp/yazi-x86_64-unknown-linux-gnu/yazi /usr/local/bin/ && \
    rm -rf /tmp/yazi-*

# lazygit - not in Ubuntu repos
RUN curl -sL https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_0.44.1_Linux_x86_64.tar.gz | tar xz -C /tmp && \
    sudo mv /tmp/lazygit /usr/local/bin/ && rm /tmp/lazygit

# Install Neovim via PPA for latest version
RUN sudo add-apt-repository ppa:neovim-ppa/unstable -y && \
    sudo apt-get update && \
    sudo apt-get install -y neovim && \
    sudo rm -rf /var/lib/apt/lists/*

# Install nvm and Node.js
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
RUN bash -c 'source ~/.nvm/nvm.sh && nvm install --lts && nvm use --lts && nvm alias default node'

# Install Docker CLI via apt repository
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    sudo apt-get update && sudo apt-get install -y docker-ce-cli && \
    sudo rm -rf /var/lib/apt/lists/*

# Install Kubernetes tools
# kubectl via Google's apt repository
RUN curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list && \
    sudo apt-get update && sudo apt-get install -y kubectl && \
    sudo rm -rf /var/lib/apt/lists/*

# Helm via apt repository
RUN curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list && \
    sudo apt-get update && sudo apt-get install -y helm && \
    sudo rm -rf /var/lib/apt/lists/*

# k9s and kubectx/kubens - not in standard repos, use releases
RUN curl -sL https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz | tar xz -C /tmp && \
    sudo mv /tmp/k9s /usr/local/bin/ && rm -rf /tmp/k9s*

RUN sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx && \
    sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx && \
    sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens

# Install Claude Code
RUN curl -fsSL https://claude.ai/install.sh | sh

# Install age via apt (available in Ubuntu 22.04+)
RUN sudo apt-get update && sudo apt-get install -y age && sudo rm -rf /var/lib/apt/lists/*

# Create symlinks for fd
RUN sudo ln -s /usr/bin/fdfind /usr/local/bin/fd

# Create config directories
RUN mkdir -p ~/.config/{nvim,tmux,lazygit,yazi,btop,starship}

# Install LazyVim
RUN git clone https://github.com/LazyVim/starter ~/.config/nvim
RUN rm -rf ~/.config/nvim/.git

# Copy base configurations (will be overridden by volume mounts)
COPY configs/ /home/edgar/.config/

# Install tmux plugin manager
RUN git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm

# Install Nerd Fonts (for container consistency)
RUN mkdir -p ~/.local/share/fonts && \
    curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/FiraCode.tar.xz | tar xJ -C ~/.local/share/fonts/ && \
    fc-cache -fv

# Set up environment
ENV PATH="/home/edgar/.nvm/versions/node/$(cat ~/.nvm/alias/default)/bin:/opt/nvim-linux64/bin:$PATH"
ENV SHELL=/bin/zsh
ENV HOME=/home/edgar
ENV USER=edgar

# Add custom clipboard script
COPY scripts/clip /usr/local/bin/clip
RUN sudo chmod +x /usr/local/bin/clip

# Set working directory
WORKDIR /home/edgar

# Configure shell
RUN echo 'eval "$(starship init zsh)"' >> ~/.zshrc && \
    echo 'eval "$(zoxide init zsh)"' >> ~/.zshrc && \
    echo 'eval "$(atuin init zsh)"' >> ~/.zshrc && \
    echo 'source ~/.nvm/nvm.sh' >> ~/.zshrc && \
    echo 'alias ls=lsd' >> ~/.zshrc && \
    echo 'alias cat=bat' >> ~/.zshrc && \
    echo 'alias find=fd' >> ~/.zshrc && \
    echo 'alias du=dust' >> ~/.zshrc

# Set default shell
ENTRYPOINT ["/bin/zsh"]