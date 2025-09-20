#!/bin/bash

# Docker Development Environment - Prerequisites Setup
# Sets up SSH keys, container runtime, fonts, and other host dependencies

set -e

echo "🔧 Docker Development Environment - Prerequisites Setup"
echo "======================================================="
echo

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    printf "   ${BLUE}ℹ${NC} %s\n" "$1"
}

log_success() {
    printf "   ${GREEN}✓${NC} %s\n" "$1"
}

log_warning() {
    printf "   ${YELLOW}⚠${NC} %s\n" "$1"
}

log_error() {
    printf "   ${RED}❌${NC} %s\n" "$1"
}

# Step 1: Check prerequisites
echo "📋 Checking prerequisites..."

# Check if age is installed
if ! command -v age &> /dev/null; then
    log_info "Installing age encryption tool..."
    case "$(uname)" in
        Darwin)
            if command -v brew &> /dev/null; then
                brew install age >/dev/null 2>&1
                log_success "age installed via Homebrew"
            else
                log_error "Homebrew not found. Please install Homebrew first."
                exit 1
            fi
            ;;
        Linux)
            if command -v apt-get &> /dev/null; then
                sudo apt-get update >/dev/null 2>&1
                sudo apt-get install -y age >/dev/null 2>&1
                log_success "age installed via apt"
            elif command -v yum &> /dev/null; then
                sudo yum install -y age >/dev/null 2>&1
                log_success "age installed via yum"
            else
                log_warning "Installing age from GitHub releases..."
                curl -sL https://github.com/FiloSottile/age/releases/download/v1.1.1/age-v1.1.1-linux-amd64.tar.gz | tar xz -C /tmp
                sudo mv /tmp/age/age /usr/local/bin/
                sudo mv /tmp/age/age-keygen /usr/local/bin/
                log_success "age installed from GitHub"
            fi
            ;;
        *)
            log_error "Unsupported operating system: $(uname)"
            exit 1
            ;;
    esac
else
    log_success "age encryption found"
fi

# Check git
if ! command -v git &> /dev/null; then
    log_error "git not found. Please install git first."
    exit 1
else
    log_success "git found"
fi

echo

# Step 2: Download encrypted configuration
echo "🔽 Downloading encrypted configuration..."

SETUP_DIR="$HOME/.devenv-setup"
if [ ! -d "$SETUP_DIR" ]; then
    log_info "Cloning configuration repository..."
    if ! git clone -q https://github.com/EdgarPost/dev.git "$SETUP_DIR" </dev/null 2>/dev/null; then
        log_warning "Using current directory as setup source"
        SETUP_DIR="$(pwd)"
    fi
    log_success "Configuration downloaded"
else
    log_info "Updating existing configuration..."
    (cd "$SETUP_DIR" && git pull -q origin main </dev/null 2>/dev/null || true)
    log_success "Configuration updated"
fi

echo

# Step 3: Create directory structure
echo "📁 Creating directory structure..."

mkdir -p ~/.devenv/{data,atuin,claude,config,secrets}
log_success "Directories created"

echo

# Step 4: Handle SSH keys
echo "🔑 Setting up SSH keys..."

echo "Choose an option:"
echo "1) Decrypt existing SSH keys from encrypted repository"
echo "2) Use your current SSH keys"
echo "3) Generate new SSH keys"
echo "4) Skip SSH key setup"
echo

read -p "Choose (1-4): " ssh_choice </dev/tty

# Handle empty input
if [ -z "$ssh_choice" ]; then
    log_warning "No option selected. Defaulting to option 2 (use existing SSH keys)"
    ssh_choice="2"
fi

case $ssh_choice in
    1)
        if [ -f "$SETUP_DIR/encrypted-secrets/ssh/id_rsa.age" ]; then
            log_info "Enter your master password to decrypt SSH keys:"
            if age -d "$SETUP_DIR/encrypted-secrets/ssh/id_rsa.age" > ~/.devenv/secrets/id_rsa 2>/dev/null; then
                chmod 600 ~/.devenv/secrets/id_rsa
                age -d "$SETUP_DIR/encrypted-secrets/ssh/id_rsa.pub.age" > ~/.devenv/secrets/id_rsa.pub 2>/dev/null
                chmod 644 ~/.devenv/secrets/id_rsa.pub

                # Add to SSH agent
                if ssh-add ~/.devenv/secrets/id_rsa 2>/dev/null; then
                    log_success "SSH keys decrypted and added to agent"
                else
                    log_warning "SSH keys decrypted but couldn't add to agent"
                fi
            else
                log_error "Failed to decrypt SSH keys. Check your password."
                exit 1
            fi
        else
            log_error "No encrypted SSH keys found in repository"
            exit 1
        fi
        ;;
    2)
        if [ -f ~/.ssh/id_rsa ]; then
            cp ~/.ssh/id_rsa ~/.devenv/secrets/
            cp ~/.ssh/id_rsa.pub ~/.devenv/secrets/
            chmod 600 ~/.devenv/secrets/id_rsa
            chmod 644 ~/.devenv/secrets/id_rsa.pub
            log_success "Existing SSH keys copied"
        else
            log_error "No existing SSH keys found in ~/.ssh/"
            exit 1
        fi
        ;;
    3)
        log_info "Generating new SSH key..."
        ssh-keygen -t ed25519 -C "edgar@devenv" -f ~/.devenv/secrets/id_rsa -N ""
        if ssh-add ~/.devenv/secrets/id_rsa 2>/dev/null; then
            log_success "New SSH key generated and added to agent"
        else
            log_warning "New SSH key generated but couldn't add to agent"
        fi

        echo
        log_warning "Don't forget to add this public key to your Git services:"
        echo
        cat ~/.devenv/secrets/id_rsa.pub
        echo
        ;;
    4)
        log_warning "Skipping SSH key setup"
        ;;
    *)
        log_error "Invalid choice: '$ssh_choice'"
        log_error "Please choose 1, 2, 3, or 4"
        exit 1
        ;;
esac

echo

# Step 5: Install host dependencies
echo "🖥️  Setting up host machine..."

case "$(uname)" in
    Darwin)
        log_info "Installing Nerd Fonts for macOS..."
        if ! brew list --cask font-fira-code-nerd-font &>/dev/null; then
            log_info "Downloading Fira Code Nerd Font (this may take 2-3 minutes)..."
            if brew install --cask font-fira-code-nerd-font; then
                log_success "Nerd Fonts installed"
            else
                log_warning "Font installation failed, but continuing..."
            fi
        else
            log_success "Nerd Fonts already installed"
        fi

        log_info "Installing Podman..."
        if ! command -v podman &> /dev/null; then
            log_info "Downloading and installing Podman..."
            if brew install podman; then
                log_info "Initializing Podman machine (downloading VM image, ~5-10 minutes)..."
                if podman machine init; then
                    log_info "Starting Podman machine..."
                    podman machine start >/dev/null 2>&1
                    log_success "Podman installed and started"
                else
                    log_warning "Podman machine init failed, but continuing..."
                fi
            else
                log_error "Failed to install Podman"
                exit 1
            fi
        else
            if ! podman machine list --format json | jq -r '.[0].Running' | grep -q true 2>/dev/null; then
                log_info "Starting Podman machine..."
                podman machine start >/dev/null 2>&1
            fi
            log_success "Podman ready"
        fi
        ;;
    Linux)
        log_info "Installing Nerd Fonts for Linux..."
        if [ ! -d ~/.local/share/fonts/FiraCode ]; then
            mkdir -p ~/.local/share/fonts
            curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/FiraCode.tar.xz | tar xJ -C ~/.local/share/fonts/
            fc-cache -fv >/dev/null 2>&1
            log_success "Nerd Fonts installed"
        else
            log_success "Nerd Fonts already installed"
        fi

        log_info "Installing Podman..."
        if ! command -v podman &> /dev/null; then
            if command -v apt-get &> /dev/null; then
                sudo apt-get update >/dev/null 2>&1
                sudo apt-get install -y podman >/dev/null 2>&1
                log_success "Podman installed via apt"
            elif command -v yum &> /dev/null; then
                sudo yum install -y podman >/dev/null 2>&1
                log_success "Podman installed via yum"
            else
                log_error "Could not install Podman. Please install manually."
                exit 1
            fi
        else
            log_success "Podman already installed"
        fi
        ;;
esac

echo

# Step 6: Decrypt other configurations (if available)
echo "⚙️  Setting up configurations..."

if [ -d "$SETUP_DIR/encrypted-secrets/configs" ] && [ "$ssh_choice" = "1" ]; then
    log_info "Decrypting personal configurations..."

    # Decrypt configs if they exist
    for config_file in "$SETUP_DIR/encrypted-secrets/configs"/**/*.age; do
        if [ -f "$config_file" ]; then
            relative_path="${config_file#$SETUP_DIR/encrypted-secrets/configs/}"
            output_path="$HOME/.devenv/config/${relative_path%.age}"
            mkdir -p "$(dirname "$output_path")"

            if age -d "$config_file" > "$output_path" 2>/dev/null; then
                log_success "Decrypted $(basename "$output_path")"
            else
                log_warning "Failed to decrypt $(basename "$config_file")"
            fi
        fi
    done
else
    log_info "Using default configurations"
fi

echo

echo "✅ SSH key setup complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Next steps:"
echo "   Run the following command to set up your development environment:"
echo "   ${GREEN}curl -fsSL https://raw.githubusercontent.com/EdgarPost/dev/main/install-devenv.sh | sh${NC}"
echo
echo "💡 What was set up:"
echo "   • SSH keys configured and added to agent"
echo "   • Nerd Fonts installed for proper icon display"
echo "   • Podman container runtime ready"
echo "   • Directory structure created in ~/.devenv/"

if [ "$ssh_choice" = "3" ]; then
    echo
    echo "🔑 Don't forget:"
    echo "   Add your new public key to GitHub/GitLab/etc:"
    echo "   ${BLUE}cat ~/.devenv/secrets/id_rsa.pub${NC}"
fi