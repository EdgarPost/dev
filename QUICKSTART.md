# 🚀 Quick Start Guide

Get your Docker development environment running in 5 minutes!

## ⚡ One-Command Setup

```bash
# Step 1: Set up SSH keys and host dependencies
curl -fsSL https://raw.githubusercontent.com/edgarpost/docker-dev-env/main/install-host-keys.sh | sh

# Step 2: Build and configure development environment
curl -fsSL https://raw.githubusercontent.com/edgarpost/docker-dev-env/main/install-devenv.sh | sh

# Step 3: Enter your development environment
dev
```

## 🎯 What Just Happened?

1. **Host Setup**: Installed Podman, Nerd Fonts, and SSH keys
2. **Container Build**: Created development environment with all tools
3. **Configuration**: Set up Catppuccin Mocha theme across all tools
4. **Shell Integration**: Added `dev` command to your shell

## 🛠️ Essential Commands

```bash
# Enter development environment
dev

# Quick tool access
dev-git        # Open lazygit
dev-files      # Open yazi file manager
dev-code       # Open Neovim

# Run specific commands
dev nvim README.md
dev "cd ~/Projects/myapp && npm test"
```

## 🎨 What's Included

- **Neovim** + LazyVim with Catppuccin Mocha
- **tmux** with persistent sessions
- **lazygit** for beautiful Git workflows
- **yazi** file manager with previews
- **Claude Code** AI assistant
- **Modern CLI tools**: rg, fd, lsd, bat, delta, btop, etc.
- **Development stack**: Node.js, Docker, Kubernetes tools

## 📁 Directory Layout

```
~/.devenv/                 # All development environment data
├── data/                  # App data and caches
├── config/                # Tool configurations
├── secrets/               # SSH keys (host only)
└── atuin/                 # Shell history sync

~/Projects/                # Your projects (mounted in container)
```

## 🔧 Customization

```bash
# Add your personal configurations
./scripts/helpers/add-config.sh

# Check current status
./scripts/helpers/show-status.sh

# Read detailed customization guide
cat CUSTOMIZATION.md
```

## 🔐 Security Features

- **SSH Agent Forwarding**: Keys never enter container
- **Rootless Containers**: No root daemon
- **Encrypted Secrets**: Personal configs encrypted with `age`
- **Container Isolation**: Limited filesystem access

## 💡 Pro Tips

- Use **Ctrl+R** for intelligent history search (Atuin)
- **tmux sessions** persist across container restarts
- All tools use **Catppuccin Mocha** theme for consistency
- **Universal clipboard** works across platforms

## 🐛 Quick Troubleshooting

```bash
# Container not starting?
podman machine start  # macOS only

# SSH not working?
ssh-add ~/.devenv/secrets/id_rsa

# Dev command not found?
source ~/.zshrc  # Restart terminal

# Need to rebuild?
podman build -t devenv:latest .
```

## 📚 Next Steps

1. **Add projects** to `~/Projects/`
2. **Customize configs** in `~/.devenv/config/`
3. **Set up Git credentials** in container
4. **Configure Claude Code** API key
5. **Read full documentation** in `README.md`

---

**Ready to code!** 🎉

*For detailed documentation, see [README.md](./README.md)*
*For customization help, see [CUSTOMIZATION.md](./CUSTOMIZATION.md)*