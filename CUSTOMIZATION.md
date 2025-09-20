# 🔧 Personal Customization Guide

> Complete guide for adding your existing configurations and personalizing your Docker development environment.

## 🚀 Quick Setup for Existing Configs

If you already have development configurations you love, here's how to migrate them to your new environment.

### Adding Your Existing SSH Keys

#### Option 1: Import Existing SSH Key

```bash
# Navigate to your setup directory
cd ~/.devenv-setup

# Create encryption key if you haven't already
age-keygen -o private.key
age-keygen -y private.key > public.key

# Copy your existing SSH key
mkdir -p raw-secrets/ssh/
cp ~/.ssh/id_rsa raw-secrets/ssh/
cp ~/.ssh/id_rsa.pub raw-secrets/ssh/

# Encrypt the private key
age -r $(cat public.key) raw-secrets/ssh/id_rsa > encrypted-secrets/ssh/id_rsa.age
age -r $(cat public.key) raw-secrets/ssh/id_rsa.pub > encrypted-secrets/ssh/id_rsa.pub.age

# Clean up raw files
rm -rf raw-secrets/
```

#### Option 2: Generate New Development SSH Key

```bash
# Generate a dedicated key for development
ssh-keygen -t ed25519 -C "edgar@devenv" -f ~/.devenv/secrets/id_rsa_dev

# Add to SSH agent
ssh-add ~/.devenv/secrets/id_rsa_dev

# Add public key to your Git services
cat ~/.devenv/secrets/id_rsa_dev.pub
```

### Migrating Your Neovim Configuration

#### If You Use LazyVim Already

```bash
# Copy your existing LazyVim config
mkdir -p ~/.devenv/config/nvim/lua/config/
mkdir -p ~/.devenv/config/nvim/lua/plugins/

# Copy your customizations
cp -r ~/.config/nvim/lua/config/* ~/.devenv/config/nvim/lua/config/
cp -r ~/.config/nvim/lua/plugins/* ~/.devenv/config/nvim/lua/plugins/

# Your configs will override the defaults
```

#### If You Use Different Neovim Setup

```bash
# Backup your current config
cp -r ~/.config/nvim ~/.config/nvim.backup

# Copy your entire config to the container
cp -r ~/.config/nvim ~/.devenv/config/
```

#### Common LazyVim Customizations

**Personal keymaps** (`~/.devenv/config/nvim/lua/config/keymaps.lua`):
```lua
-- Your custom keybindings
local map = vim.keymap.set

-- Project navigation
map("n", "<leader>pv", vim.cmd.Ex, { desc = "Open file explorer" })
map("n", "<leader>pf", "<cmd>Telescope find_files<cr>", { desc = "Find files" })

-- Better navigation
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })

-- Quick save
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file" })
```

**Additional plugins** (`~/.devenv/config/nvim/lua/plugins/custom.lua`):
```lua
return {
  -- GitHub Copilot
  {
    "github/copilot.vim",
    event = "VeryLazy",
  },

  -- Prettier formatting
  {
    "prettier/vim-prettier",
    build = "yarn install --frozen-lockfile --production",
    ft = { "javascript", "typescript", "css", "less", "scss", "json", "graphql", "markdown", "vue", "yaml", "html" },
  },

  -- Your favorite theme as backup
  {
    "folke/tokyonight.nvim",
    opts = {},
  },
}
```

### Personal Git Configuration

#### Global Git Config

```bash
# Create your personal git config
cat > ~/.devenv/config/git/config << EOF
[user]
    name = Edgar Post
    email = edgar@example.com
    signingkey = ~/.ssh/id_rsa.pub

[core]
    editor = nvim
    autocrlf = input
    pager = delta

[interactive]
    diffFilter = delta --color-only

[delta]
    navigate = true
    light = false
    side-by-side = true
    line-numbers = true

[merge]
    conflictstyle = diff3

[diff]
    colorMoved = default

[init]
    defaultBranch = main

[push]
    default = simple
    autoSetupRemote = true

[pull]
    rebase = true

[alias]
    # Beautiful log
    lg = log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit

    # Quick status
    st = status -sb

    # Amend last commit
    amend = commit --amend --no-edit

    # Undo last commit but keep changes
    undo = reset HEAD~1 --mixed

    # Clean up merged branches
    cleanup = "!git branch --merged | grep -v '\\*\\|main\\|develop' | xargs -n 1 git branch -d"
EOF
```

#### Project-Specific Git Config

For projects with different email/signing requirements:

```bash
# In each project directory
cd ~/Projects/work-project/
git config user.email "edgar@company.com"
git config user.signingkey "work-key"

cd ~/Projects/personal-project/
git config user.email "edgar@personal.com"
git config user.signingkey "personal-key"
```

### Tmux Customization

#### Adding Your Tmux Config

```bash
# Add to ~/.devenv/config/tmux/tmux.conf
cat >> ~/.devenv/config/tmux/tmux.conf << 'EOF'

# Your personal tmux settings
# ===========================

# Additional key bindings
bind-key h select-pane -L
bind-key j select-pane -D
bind-key k select-pane -U
bind-key l select-pane -R

# Window management
bind-key -n M-h previous-window
bind-key -n M-l next-window

# Session management
bind-key S command-prompt -p "New Session:" "new-session -A -s '%%'"
bind-key K confirm kill-session

# Copy mode improvements
bind-key -T copy-mode-vi 'v' send -X begin-selection
bind-key -T copy-mode-vi 'y' send -X copy-pipe-and-cancel 'clip'

# Pane resizing
bind-key -r H resize-pane -L 5
bind-key -r J resize-pane -D 5
bind-key -r K resize-pane -U 5
bind-key -r L resize-pane -R 5

# Status line customization
set -g status-left-length 50
set -g status-left "#[fg=#89b4fa,bold]󰞷 #S #[fg=#6c7086]│ "

# Your custom plugins
set -g @plugin 'tmux-plugins/tmux-yank'
set -g @plugin 'tmux-plugins/tmux-open'
set -g @plugin 'christoomey/vim-tmux-navigator'
EOF
```

### Shell Configuration (Zsh)

#### Personal Aliases and Functions

```bash
# Add to ~/.devenv/config/zsh/.zshrc
cat >> ~/.devenv/config/zsh/.zshrc << 'EOF'

# Your personal aliases
# ====================

# Git shortcuts
alias g='git'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gs='git status'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'

# Modern CLI replacements
alias ll='lsd -la'
alias la='lsd -la'
alias lt='lsd --tree'
alias cat='bat'
alias find='fd'
alias du='dust'
alias ps='procs'

# Directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Development shortcuts
alias v='nvim'
alias lg='lazygit'
alias y='yazi'

# Docker/Podman
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'

# Kubernetes
alias k='kubectl'
alias kns='kubens'
alias kctx='kubectx'

# Your custom functions
# ====================

# Create directory and cd into it
function mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Find and edit file
function fe() {
    local file=$(fd . | fzf)
    if [[ -n $file ]]; then
        nvim "$file"
    fi
}

# Git commit with conventional format
function gcm() {
    if [[ -z "$1" ]]; then
        echo "Usage: gcm <type> <message>"
        echo "Types: feat, fix, docs, style, refactor, test, chore"
        return 1
    fi
    git commit -m "$1: $2"
}

# Quick project switcher
function proj() {
    local project=$(fd . ~/Projects --type d --max-depth 1 --exec basename | fzf)
    if [[ -n $project ]]; then
        cd ~/Projects/"$project"
    fi
}

# Your environment variables
# =========================
export EDITOR=nvim
export BROWSER=open
export TERM=xterm-256color

# Project-specific environment
export NODE_ENV=development
export PYTHON_ENV=development
EOF
```

## 🔐 Managing API Keys and Tokens

### Setting Up Encrypted API Keys

```bash
# Create API keys file
mkdir -p ~/.devenv-setup/raw-secrets/api-keys/
cat > ~/.devenv-setup/raw-secrets/api-keys/tokens << EOF
# Development API Keys
GITHUB_TOKEN=ghp_your_github_token_here
ANTHROPIC_API_KEY=sk-ant-api03-your_claude_key
OPENAI_API_KEY=sk-your_openai_key
DOCKER_HUB_TOKEN=dckr_pat_your_docker_token

# Cloud Provider Keys
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
AZURE_CLIENT_ID=your_azure_client_id
AZURE_CLIENT_SECRET=your_azure_client_secret

# Database URLs
DATABASE_URL=postgresql://user:pass@localhost:5432/mydb
REDIS_URL=redis://localhost:6379

# Service Keys
STRIPE_SECRET_KEY=sk_test_your_stripe_key
SENDGRID_API_KEY=SG.your_sendgrid_key
EOF

# Encrypt the tokens
age -r $(cat ~/.devenv-setup/public.key) ~/.devenv-setup/raw-secrets/api-keys/tokens > ~/.devenv-setup/encrypted-secrets/api-keys/tokens.age

# Clean up raw file
rm ~/.devenv-setup/raw-secrets/api-keys/tokens
```

### Loading API Keys in Container

The keys will be automatically available as environment variables when you enter the container.

```bash
# In container, check available keys
env | grep -E "(GITHUB|ANTHROPIC|OPENAI|AWS)"

# Use in your development
claude --api-key $ANTHROPIC_API_KEY "help me debug this"
gh auth login --with-token <<< $GITHUB_TOKEN
```

## 🛠️ Advanced Customizations

### Custom Tools Installation

Add tools to your personal setup:

```bash
# Add to Dockerfile.custom
cat > ~/.devenv-setup/Dockerfile.custom << 'EOF'
# Additional tools for your workflow
RUN curl -sSL https://get.docker.com | sh

# Install language-specific tools
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
RUN pip3 install --user poetry black flake8 mypy

# Install additional CLI tools
RUN npm install -g @vercel/ncc typescript ts-node
EOF
```

### Project Templates

Create templates for new projects:

```bash
# Create project templates
mkdir -p ~/.devenv/templates/

# React TypeScript template
mkdir -p ~/.devenv/templates/react-ts/
cat > ~/.devenv/templates/react-ts/package.json << 'EOF'
{
  "name": "project-name",
  "version": "1.0.0",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.0",
    "@types/react-dom": "^18.2.0",
    "@vitejs/plugin-react": "^4.0.0",
    "typescript": "^5.0.0",
    "vite": "^4.0.0"
  }
}
EOF

# Function to create new project from template
function newproj() {
    local template="$1"
    local name="$2"

    if [[ -z "$template" || -z "$name" ]]; then
        echo "Usage: newproj <template> <project-name>"
        echo "Available templates:"
        ls ~/.devenv/templates/
        return 1
    fi

    cp -r ~/.devenv/templates/"$template" ~/Projects/"$name"
    cd ~/Projects/"$name"

    # Replace placeholders
    sed -i "s/project-name/$name/g" package.json

    echo "Created new $template project: $name"
}
```

### Container Networking

For web development with port forwarding:

```bash
# Add to your shell profile
devserver() {
    local port="${2:-3000}"
    dev --publish "$port:$port" "cd /workspace/projects/$1 && npm run dev"
}

# Usage
devserver myapp 3000  # Forwards localhost:3000 to container
```

## 🔄 Backup and Sync Strategy

### Backup Your Configurations

```bash
# Backup script
#!/bin/bash
backup_devenv() {
    local backup_dir="$HOME/devenv-backup-$(date +%Y%m%d)"
    mkdir -p "$backup_dir"

    # Backup configurations
    cp -r ~/.devenv/config "$backup_dir/"

    # Backup encrypted secrets
    cp -r ~/.devenv-setup/encrypted-secrets "$backup_dir/"

    # Create archive
    tar -czf "$backup_dir.tar.gz" "$backup_dir"
    rm -rf "$backup_dir"

    echo "Backup created: $backup_dir.tar.gz"
}
```

### Git Repository Setup

```bash
# Initialize git repo for your setup
cd ~/.devenv-setup
git init
git add .
git commit -m "Initial devenv setup"

# Add remote (replace with your repo)
git remote add origin https://github.com/EdgarPost/dev.git
git push -u origin main

# Auto-sync changes
git config --global alias.devenv-sync '!cd ~/.devenv-setup && git add . && git commit -m "Update devenv config $(date)" && git push'
```

## 🔧 Troubleshooting Your Customizations

### Config Not Loading

```bash
# Check if configs are mounted correctly
dev ls -la ~/.config/

# Verify volume mounts
dev mount | grep devenv

# Restart container to reload configs
# (configs are loaded on container start)
```

### SSH Key Issues

```bash
# Check SSH agent in container
dev ssh-add -l

# Test Git access
dev ssh -T git@github.com

# Re-add keys if needed
ssh-add ~/.devenv/secrets/id_rsa
```

### Tool-Specific Issues

```bash
# Neovim: Check health
dev nvim -c "checkhealth"

# Tmux: Reload config
dev tmux source-file ~/.config/tmux/tmux.conf

# Git: Check config
dev git config --list
```

## 🎯 Next Steps

1. **Set up your personal configurations** using the guides above
2. **Create your encrypted secrets repository** for sync across machines
3. **Customize the theme** if you prefer different Catppuccin flavors
4. **Add project-specific configurations** for your workflow
5. **Set up backup automation** to protect your configurations

## 💡 Pro Tips

- **Start small**: Migrate one tool at a time
- **Test configs**: Always test in container before committing
- **Version control**: Keep your configs in git for easy rollback
- **Document changes**: Add comments to your custom configurations
- **Share configs**: Create shareable configuration modules for your team

---

Happy customizing! 🚀

*Need help? Check the main [README.md](./README.md) or open an issue.*