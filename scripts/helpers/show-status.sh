#!/bin/bash

# Configuration Status Display
# Shows current status of all configurations

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

log_success() { echo -e "   ${GREEN}✓${NC} $1"; }
log_warning() { echo -e "   ${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "   ${RED}❌${NC} $1"; }
log_info() { echo -e "   ${BLUE}ℹ${NC} $1"; }

echo "📊 Docker Development Environment - Configuration Status"
echo "======================================================="
echo

# Check SSH Keys
echo "${PURPLE}🔑 SSH Keys${NC}"
if [ -f ~/.devenv/secrets/id_rsa ]; then
    log_success "SSH private key configured"
    if [ -f ~/.devenv/secrets/id_rsa.pub ]; then
        log_success "SSH public key configured"
        fingerprint=$(ssh-keygen -lf ~/.devenv/secrets/id_rsa.pub 2>/dev/null | awk '{print $2}' || echo "Unable to read")
        echo "      Fingerprint: $fingerprint"
    else
        log_warning "SSH public key missing"
    fi
else
    log_error "SSH keys not configured"
    echo "      Run: ./scripts/helpers/add-ssh-key.sh"
fi
echo

# Check Git Configuration
echo "${PURPLE}📝 Git Configuration${NC}"
if [ -f ~/.devenv/config/git/config ]; then
    log_success "Git configuration found"

    # Extract key info
    git_name=$(grep "name = " ~/.devenv/config/git/config | head -1 | sed 's/.*name = //' || echo "Not set")
    git_email=$(grep "email = " ~/.devenv/config/git/config | head -1 | sed 's/.*email = //' || echo "Not set")

    echo "      Name: $git_name"
    echo "      Email: $git_email"

    if grep -q "gpgsign = true" ~/.devenv/config/git/config 2>/dev/null; then
        log_success "Commit signing enabled"
    else
        log_warning "Commit signing not configured"
    fi
else
    log_error "Git configuration not found"
    echo "      Run: ./scripts/helpers/add-git-config.sh"
fi
echo

# Check Neovim Configuration
echo "${PURPLE}📝 Neovim Configuration${NC}"
if [ -d ~/.devenv/config/nvim ]; then
    log_success "Neovim configuration directory exists"

    if [ -f ~/.devenv/config/nvim/lua/config/catppuccin.lua ]; then
        log_success "Catppuccin theme configured"
    fi

    # Count custom configs
    custom_files=$(find ~/.devenv/config/nvim -name "*.lua" -type f 2>/dev/null | wc -l || echo "0")
    echo "      Custom config files: $custom_files"
else
    log_warning "No custom Neovim configuration"
    echo "      Default LazyVim will be used"
fi
echo

# Check Tmux Configuration
echo "${PURPLE}🖥️  Tmux Configuration${NC}"
if [ -f ~/.devenv/config/tmux/tmux.conf ]; then
    log_success "Tmux configuration found"

    # Check for Catppuccin theme
    if grep -q "catppuccin" ~/.devenv/config/tmux/tmux.conf 2>/dev/null; then
        log_success "Catppuccin theme configured"
    fi

    # Count custom bindings
    custom_bindings=$(grep -c "bind" ~/.devenv/config/tmux/tmux.conf 2>/dev/null || echo "0")
    echo "      Custom key bindings: $custom_bindings"
else
    log_warning "Using default tmux configuration"
fi
echo

# Check Shell Configuration
echo "${PURPLE}🐚 Shell Configuration${NC}"
if [ -f ~/.devenv/config/zsh/.zshrc ]; then
    log_success "Custom zsh configuration found"

    # Count aliases
    alias_count=$(grep -c "alias " ~/.devenv/config/zsh/.zshrc 2>/dev/null || echo "0")
    echo "      Custom aliases: $alias_count"

    # Count functions
    function_count=$(grep -c "function " ~/.devenv/config/zsh/.zshrc 2>/dev/null || echo "0")
    echo "      Custom functions: $function_count"
else
    log_warning "Using default shell configuration"
fi
echo

# Check Starship Configuration
echo "${PURPLE}✨ Starship Prompt${NC}"
if [ -f ~/.devenv/config/starship/starship.toml ]; then
    log_success "Starship configuration found"

    if grep -q "catppuccin_mocha" ~/.devenv/config/starship/starship.toml 2>/dev/null; then
        log_success "Catppuccin Mocha theme configured"
    fi
else
    log_warning "Using default Starship configuration"
fi
echo

# Check Directory Structure
echo "${PURPLE}📁 Directory Structure${NC}"
required_dirs=(
    "~/.devenv/data"
    "~/.devenv/config"
    "~/.devenv/atuin"
    "~/.devenv/claude"
)

for dir in "${required_dirs[@]}"; do
    expanded_dir=$(eval echo "$dir")
    if [ -d "$expanded_dir" ]; then
        log_success "$(basename "$dir") directory exists"
    else
        log_error "$(basename "$dir") directory missing"
    fi
done
echo

# Check Container Status
echo "${PURPLE}🐳 Container Status${NC}"
if command -v podman &> /dev/null; then
    log_success "Podman installed"

    # Check if container image exists
    if podman images | grep -q "devenv" 2>/dev/null; then
        log_success "Development container image built"

        # Get image size
        image_size=$(podman images --format "table {{.Size}}" devenv:latest 2>/dev/null | tail -1 || echo "Unknown")
        echo "      Image size: $image_size"
    else
        log_warning "Development container not built"
        echo "      Run: ./install-devenv.sh"
    fi

    # Check if dev function exists
    if command -v dev &> /dev/null; then
        log_success "Dev shell function available"
    else
        log_warning "Dev shell function not configured"
        echo "      Restart your terminal or run: source ~/.zshrc"
    fi
else
    log_error "Podman not installed"
    echo "      Run: ./install-host-keys.sh"
fi
echo

# Check Projects Directory
echo "${PURPLE}📂 Projects Directory${NC}"
if [ -d ~/Projects ]; then
    log_success "Projects directory exists"

    project_count=$(find ~/Projects -maxdepth 1 -type d 2>/dev/null | wc -l)
    project_count=$((project_count - 1))  # Subtract the Projects directory itself
    echo "      Projects found: $project_count"

    if [ $project_count -gt 0 ]; then
        echo "      Recent projects:"
        find ~/Projects -maxdepth 1 -type d -not -path ~/Projects | head -3 | while read -r project; do
            echo "        • $(basename "$project")"
        done
    fi
else
    log_warning "Projects directory not found"
    echo "      Create with: mkdir -p ~/Projects"
fi
echo

# Summary
echo "${PURPLE}📋 Quick Summary${NC}"
config_score=0
total_checks=6

[ -f ~/.devenv/secrets/id_rsa ] && ((config_score++))
[ -f ~/.devenv/config/git/config ] && ((config_score++))
[ -d ~/.devenv/config/nvim ] && ((config_score++))
[ -f ~/.devenv/config/tmux/tmux.conf ] && ((config_score++))
command -v podman &> /dev/null && ((config_score++))
command -v dev &> /dev/null && ((config_score++))

echo "   Configuration completeness: $config_score/$total_checks"

if [ $config_score -eq $total_checks ]; then
    log_success "🎉 Everything is configured! Ready to code!"
elif [ $config_score -ge 4 ]; then
    log_success "✨ Most things configured! Almost ready!"
else
    log_warning "⚠️  Several configurations missing. Run setup scripts."
fi

echo
echo "💡 Quick actions:"
echo "   • Configure missing items: ${GREEN}./scripts/helpers/add-config.sh${NC}"
echo "   • Test environment: ${GREEN}dev${NC}"
echo "   • View documentation: ${GREEN}cat README.md${NC}"
echo "   • Customize further: ${GREEN}cat CUSTOMIZATION.md${NC}"