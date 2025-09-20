#!/bin/bash

# SSH Key Setup Helper
# Helps users add SSH keys to their development environment

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { printf "   ${BLUE}ℹ${NC} %s\n" "$1"; }
log_success() { printf "   ${GREEN}✓${NC} %s\n" "$1"; }
log_warning() { printf "   ${YELLOW}⚠${NC} %s\n" "$1"; }
log_error() { printf "   ${RED}❌${NC} %s\n" "$1"; }

echo "🔑 SSH Key Configuration"
echo
echo "Choose how you want to set up SSH keys:"
echo
echo "1) Use existing SSH key from ~/.ssh/"
echo "2) Generate new SSH key"
echo "3) Import SSH key from file"
echo "4) Skip SSH key setup"
echo

read -p "Choose option (1-4): " ssh_option

# Handle empty input
if [ -z "$ssh_option" ]; then
    log_warning "No option selected. Defaulting to option 1 (use existing SSH key)"
    ssh_option="1"
fi

case $ssh_option in
    1)
        # Use existing SSH key
        if [ -f ~/.ssh/id_rsa ]; then
            log_info "Found existing SSH key"

            # Create secrets directory
            mkdir -p ~/.devenv/secrets/

            # Copy keys
            cp ~/.ssh/id_rsa ~/.devenv/secrets/
            cp ~/.ssh/id_rsa.pub ~/.devenv/secrets/

            # Set permissions
            chmod 600 ~/.devenv/secrets/id_rsa
            chmod 644 ~/.devenv/secrets/id_rsa.pub

            log_success "SSH key copied to development environment"

            # Add to SSH agent
            if ssh-add ~/.devenv/secrets/id_rsa 2>/dev/null; then
                log_success "SSH key added to agent"
            else
                log_warning "Could not add key to SSH agent (this is normal if agent is not running)"
            fi

        elif [ -f ~/.ssh/id_ed25519 ]; then
            log_info "Found existing Ed25519 SSH key"

            mkdir -p ~/.devenv/secrets/
            cp ~/.ssh/id_ed25519 ~/.devenv/secrets/id_rsa
            cp ~/.ssh/id_ed25519.pub ~/.devenv/secrets/id_rsa.pub

            chmod 600 ~/.devenv/secrets/id_rsa
            chmod 644 ~/.devenv/secrets/id_rsa.pub

            log_success "Ed25519 SSH key copied to development environment"

            if ssh-add ~/.devenv/secrets/id_rsa 2>/dev/null; then
                log_success "SSH key added to agent"
            fi
        else
            log_error "No SSH key found in ~/.ssh/"
            log_info "Generate a new key with option 2"
            exit 1
        fi
        ;;
    2)
        # Generate new SSH key
        log_info "Generating new SSH key for development environment"

        # Get email for key
        read -p "Enter email for SSH key: " email
        if [ -z "$email" ]; then
            email="edgar@devenv"
        fi

        # Create secrets directory
        mkdir -p ~/.devenv/secrets/

        # Generate key
        ssh-keygen -t ed25519 -C "$email" -f ~/.devenv/secrets/id_rsa -N ""

        log_success "New SSH key generated"

        # Add to SSH agent
        if ssh-add ~/.devenv/secrets/id_rsa 2>/dev/null; then
            log_success "SSH key added to agent"
        fi

        echo
        log_warning "🔑 Your new public key (add this to GitHub/GitLab/etc.):"
        echo
        cat ~/.devenv/secrets/id_rsa.pub
        echo
        ;;
    3)
        # Import from file
        read -p "Enter path to private key file: " key_path

        if [ ! -f "$key_path" ]; then
            log_error "File not found: $key_path"
            exit 1
        fi

        mkdir -p ~/.devenv/secrets/

        # Copy private key
        cp "$key_path" ~/.devenv/secrets/id_rsa
        chmod 600 ~/.devenv/secrets/id_rsa

        # Try to find corresponding public key
        pub_path="${key_path}.pub"
        if [ -f "$pub_path" ]; then
            cp "$pub_path" ~/.devenv/secrets/id_rsa.pub
            chmod 644 ~/.devenv/secrets/id_rsa.pub
            log_success "SSH key pair imported"
        else
            # Generate public key from private key
            ssh-keygen -y -f ~/.devenv/secrets/id_rsa > ~/.devenv/secrets/id_rsa.pub
            log_success "SSH key imported and public key generated"
        fi

        # Add to SSH agent
        if ssh-add ~/.devenv/secrets/id_rsa 2>/dev/null; then
            log_success "SSH key added to agent"
        fi
        ;;
    4)
        log_info "Skipping SSH key setup"
        log_warning "Note: You'll need to set up SSH keys manually for Git access"
        ;;
    *)
        log_error "Invalid option: '$ssh_option'"
        log_error "Please choose 1, 2, 3, or 4"
        exit 1
        ;;
esac

echo
echo "✅ SSH Key setup complete!"

# Show current status
if [ -f ~/.devenv/secrets/id_rsa ]; then
    echo
    echo "📋 SSH Key Status:"
    echo "   • Private key: ~/.devenv/secrets/id_rsa"
    echo "   • Public key: ~/.devenv/secrets/id_rsa.pub"
    echo "   • Fingerprint: $(ssh-keygen -lf ~/.devenv/secrets/id_rsa.pub 2>/dev/null || echo 'Unable to read')"

    echo
    echo "💡 Next steps:"
    echo "   • Add your public key to GitHub: https://github.com/settings/keys"
    echo "   • Test SSH access: ${GREEN}dev ssh -T git@github.com${NC}"
    echo "   • Test Git clone: ${GREEN}dev git clone git@github.com:user/repo.git${NC}"
fi