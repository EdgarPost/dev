# 🐳 Docker Development Environment

> A beautiful, secure, and portable development environment using Docker/Podman with Catppuccin Mocha theme throughout.

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-brightgreen.svg)
![Theme](https://img.shields.io/badge/theme-Catppuccin%20Mocha-f5c2e7.svg)

## ✨ Features

- 🎨 **Unified Catppuccin Mocha theme** across all tools
- 🔐 **Security-first design** with SSH agent forwarding
- 🚀 **5-minute setup** on any machine
- 📦 **Rootless containers** via Podman
- 🔄 **Cross-machine sync** with encrypted history
- 🛠️ **Complete development stack** with modern tools

## 🚀 Quick Start

### Recommended Setup

```bash
# Clone the repository
git clone https://github.com/EdgarPost/dev.git
cd dev

# Step 1: Set up prerequisites (SSH keys, Podman, fonts)
./install-prerequisites.sh

# Step 2: Build and configure development environment
./install-devenv.sh

# Step 3: Enter your development environment
dev
```

> **Why local execution?** Running scripts locally provides full interactivity, better progress output, easier debugging, and the ability to review code before execution.

That's it! You now have a complete development environment with all tools configured.

## 🛠️ What's Included

### Core Development Tools

| Tool | Purpose | Theme |
|------|---------|-------|
| **Neovim** + LazyVim | Code editor with LSP, autocomplete, and more | ✅ Catppuccin Mocha |
| **tmux** | Terminal multiplexer with persistent sessions | ✅ Catppuccin Mocha |
| **lazygit** | Beautiful Git UI with diff viewer | ✅ Catppuccin Mocha |
| **yazi** | File manager with preview support | ✅ Catppuccin Mocha |
| **Claude Code** | AI coding assistant (with safe permissions) | ✅ Catppuccin Mocha |

### Modern CLI Tools

| Tool | Replaces | Description |
|------|----------|-------------|
| **rg** (ripgrep) | `grep` | Faster search with better UX |
| **fd** | `find` | Intuitive file finder |
| **lsd** | `ls` | Beautiful file listings with icons |
| **bat** | `cat` | Syntax highlighted file viewer |
| **delta** | `diff` | Beautiful Git diffs |
| **dust** | `du` | Visual disk usage |
| **btop** | `htop` | Modern system monitor |
| **fzf** | - | Fuzzy finder for everything |
| **zoxide** | `cd` | Smart directory jumping |

### Development Stack

- **Shell**: zsh with Starship prompt
- **History**: Atuin (encrypted, cross-machine sync)
- **Node.js**: nvm with latest LTS
- **Kubernetes**: kubectl, helm, k9s, kubectx/kubens
- **Docker**: CLI with socket mounting
- **Fonts**: Nerd Fonts for perfect icon rendering

## 📁 Directory Structure

```
~/.devenv/
├── data/           # App data, caches, tmux sessions
├── atuin/          # Encrypted shell history database
├── claude/         # Claude Code sessions and settings
├── config/         # All tool configurations
│   ├── nvim/       # Neovim + LazyVim config
│   ├── tmux/       # Tmux configuration
│   ├── lazygit/    # Git UI configuration
│   └── ...         # Other tool configs
└── secrets/        # Decrypted secrets (host-only)

~/Projects/         # Your projects (mounted to container)
```

## 🎨 Theme Showcase

Everything uses the beautiful **Catppuccin Mocha** palette:

- **Base**: `#1e1e2e` - Warm dark background
- **Text**: `#cdd6f4` - Crisp readable text
- **Mauve**: `#cba6f7` - Purple accent
- **Blue**: `#89b4fa` - Info and links
- **Green**: `#a6e3a1` - Success states
- **Red**: `#f38ba8` - Errors and warnings
- **Yellow**: `#f9e2af` - Warnings and highlights

## 🔐 Security Architecture

### SSH Agent Forwarding
- SSH keys **never enter the container**
- Host OS manages key security (Keychain, secure enclave)
- Agent forwarding provides seamless Git access
- Perfect isolation with zero key exposure

### Encrypted Secrets
- All personal configs encrypted with `age`
- One password unlocks everything
- Secrets decrypted to host, mounted read-only
- Easy key rotation and backup

### Container Isolation
- Rootless Podman eliminates daemon risks
- Security options prevent privilege escalation
- Limited filesystem access via volume mounts
- Claude Code runs safely with `--dangerously-skip-permissions`

## 🚀 Usage Guide

### Basic Commands

```bash
# Enter development environment
dev

# Quick access to specific tools
dev-git        # Open lazygit
dev-files      # Open yazi file manager
dev-code       # Open Neovim

# Run commands in container
dev nvim README.md
dev "cd ~/Projects/myapp && npm test"
```

### Inside the Container

```bash
# Navigation
yazi           # File manager
lazygit        # Git UI
btop           # System monitor

# Development
nvim           # Code editor
claude --dangerously-skip-permissions  # AI assistant
tmux           # Session management

# Modern CLI
rg "pattern"   # Fast search
fd "*.js"      # Find files
lsd -la        # Pretty file listing
bat file.md    # Syntax highlighted viewing
```

### Tmux Sessions

```bash
# Create named sessions for each project
tmux new-session -d -s myapp
tmux new-session -d -s website
tmux new-session -d -s api

# List sessions
tmux list-sessions

# Attach to session
tmux attach -t myapp

# Switch between sessions with prefix + s
```

## 🔄 Cross-Machine Workflow

### Setting Up a New Machine

```bash
# Clone and run setup scripts
git clone https://github.com/EdgarPost/dev.git
cd dev

# Run setup scripts
./install-prerequisites.sh
./install-devenv.sh

# Start developing
dev
```

### History Sync with Atuin

- **Automatic sync** every hour
- **Encrypted** end-to-end (server can't read commands)
- **Rich context** (working directory, exit codes, duration)
- **Smart search** with Ctrl+R

```bash
# First-time setup (during installation)
atuin register -u username -e email

# On new machines (automatically handled)
atuin login
atuin sync
```

## 🎯 Perfect For

- **Multi-machine developers** who work on macOS and Linux
- **Security-conscious teams** needing isolated environments
- **Remote workers** wanting consistent setups everywhere
- **Open source contributors** managing multiple projects
- **DevOps engineers** working with Kubernetes daily
- **Anyone** who loves beautiful, functional development tools

## 🔧 Customization

Want to customize the environment? See [CUSTOMIZATION.md](./CUSTOMIZATION.md) for:

- Adding your existing SSH keys and configs
- Customizing Neovim, tmux, and other tools
- Managing API keys and tokens
- Adding project-specific configurations
- Advanced security setups

## 🐛 Troubleshooting

### Container Issues

```bash
# Rebuild container
podman build -t devenv:latest ~/.devenv-setup/

# Check container startup
dev echo "Container working"

# Reset configuration
rm -rf ~/.devenv/config && dev
```

### SSH Problems

```bash
# Check SSH agent
ssh-add -l

# Re-add keys
ssh-add ~/.devenv/secrets/id_rsa

# Test Git access
dev "ssh -T git@github.com"
```

### Podman Issues

```bash
# Start Podman machine (macOS)
podman machine start

# Check Podman status
podman info

# Reset Podman machine (macOS)
podman machine stop && podman machine start
```

## 📚 Advanced Usage

### Custom Shell Functions

Add to your `~/.zshrc`:

```bash
# Quick project navigation
proj() {
    cd ~/Projects/"$1"
    dev
}

# Git workflow
gitwork() {
    dev "cd /workspace/projects/$1 && lazygit"
}

# Development server with forwarding
devserver() {
    dev "cd /workspace/projects/$1 && npm run dev" --publish 3000:3000
}
```

### CI/CD Integration

Use the container in GitHub Actions:

```yaml
- name: Setup Development Environment
  run: |
    curl -fsSL https://raw.githubusercontent.com/EdgarPost/dev/main/install-devenv.sh | sh
    dev "npm test"
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes and test in the container
4. Commit with conventional commits: `git commit -m "feat: add amazing feature"`
5. Push and create a Pull Request

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

- [Catppuccin](https://github.com/catppuccin/catppuccin) for the beautiful color scheme
- [LazyVim](https://github.com/LazyVim/LazyVim) for the excellent Neovim distribution
- All the amazing tool maintainers who make development better

---

**Happy coding!** 🚀

*Built with ❤️ and lots of ☕ by Edgar*