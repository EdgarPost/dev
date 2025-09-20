#!/bin/bash

# Docker Development Environment - Container Setup
# Builds container and sets up development environment with progress tracking

set -e

echo "🐳 Docker Development Environment - Container Setup"
echo "=================================================="
echo

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

log_step() {
    printf "   ${PURPLE}→${NC} %s\n" "$1"
}

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command -v podman &> /dev/null; then
    log_warning "Podman not found. Installing prerequisites..."
    log_info "Running prerequisite setup (this includes SSH keys, Podman, and fonts)..."

    # Download and run the prerequisite script
    if curl -fsSL https://raw.githubusercontent.com/EdgarPost/dev/main/install-prerequisites.sh | sh; then
        log_success "Prerequisites installed successfully"
    else
        log_error "Failed to install prerequisites"
        exit 1
    fi

    # Verify Podman is now available
    if ! command -v podman &> /dev/null; then
        log_error "Podman still not found after prerequisite installation"
        exit 1
    fi
else
    log_success "Podman found"
fi

# Check if setup directory exists
SETUP_DIR="$HOME/.devenv-setup"
if [ ! -d "$SETUP_DIR" ]; then
    log_info "Downloading setup files..."
    git clone -q https://github.com/EdgarPost/dev.git "$SETUP_DIR"
    log_success "Setup files downloaded"
else
    log_success "Setup files found"
fi

# Check directory structure
if [ ! -d ~/.devenv ]; then
    log_error "Directory structure not found. Please run the SSH key setup script first."
    exit 1
else
    log_success "Directory structure found"
fi

echo

# Step 1: Build container
echo "🔨 Building development container..."
log_info "This may take 5-10 minutes on first run..."
echo

# Build with progress monitoring
build_log="/tmp/devenv-build.log"
podman build -t devenv:latest "$SETUP_DIR" --progress=plain > "$build_log" 2>&1 &
build_pid=$!

# Monitor build progress
while kill -0 $build_pid 2>/dev/null; do
    if [ -f "$build_log" ]; then
        # Show latest meaningful progress
        tail -n 1 "$build_log" | grep -E "(STEP|RUN|COPY|FROM)" | while read line; do
            case "$line" in
                *"STEP"*)
                    step_info=$(echo "$line" | sed 's/.*STEP [0-9]*\/[0-9]*: //')
                    log_step "$step_info"
                    ;;
                *"RUN"*)
                    if echo "$line" | grep -q "Installing\|Downloading\|Building"; then
                        action=$(echo "$line" | grep -o "Installing.*\|Downloading.*\|Building.*" | head -1)
                        log_info "$action"
                    fi
                    ;;
            esac
        done
    fi
    sleep 2
done

# Wait for build to complete
wait $build_pid
build_result=$?

if [ $build_result -eq 0 ]; then
    log_success "Container built successfully"
else
    log_error "Container build failed"
    echo "   Check the build log: $build_log"
    exit 1
fi

# Clean up build log
rm -f "$build_log"

echo

# Step 2: Set up Atuin (optional)
echo "🔄 Setting up shell history sync..."

if [ -f ~/.devenv/secrets/atuin_key ]; then
    log_success "Using existing Atuin configuration"
elif command -v atuin &> /dev/null && atuin status >/dev/null 2>&1; then
    log_success "Atuin already configured on host"
else
    echo "   Would you like to set up encrypted shell history sync across machines?"
    echo "   This allows you to access your command history on any machine."
    echo
    read -p "   Set up Atuin? (y/N): " setup_atuin </dev/tty

    if [[ "$setup_atuin" =~ ^[Yy]$ ]]; then
        log_info "Please register for Atuin history sync:"
        read -p "   Username: " atuin_username </dev/tty
        read -p "   Email: " atuin_email </dev/tty

        if [ ! -z "$atuin_username" ] && [ ! -z "$atuin_email" ]; then
            # Test container to set up Atuin
            log_info "Setting up Atuin in container..."
            podman run --rm -it \
                -v ~/.devenv/atuin:/home/edgar/.config/atuin \
                devenv:latest \
                bash -c "atuin register -u '$atuin_username' -e '$atuin_email' && atuin key" > ~/.devenv/secrets/atuin_key 2>/dev/null

            if [ -s ~/.devenv/secrets/atuin_key ]; then
                log_success "Atuin configured successfully"
            else
                log_warning "Atuin setup failed (you can configure it later)"
                rm -f ~/.devenv/secrets/atuin_key
            fi
        else
            log_warning "Skipping Atuin setup (you can configure it later)"
        fi
    else
        log_info "Skipping Atuin setup"
    fi
fi

echo

# Step 3: Install shell integration
echo "🐚 Setting up shell integration..."

# Detect shell
shell_profile=""
case "$SHELL" in
    */zsh) shell_profile="$HOME/.zshrc" ;;
    */bash) shell_profile="$HOME/.bashrc" ;;
    */fish) shell_profile="$HOME/.config/fish/config.fish" ;;
    *)
        log_warning "Unsupported shell: $SHELL"
        shell_profile="$HOME/.profile"
        ;;
esac

# Add shell function
if [ ! -z "$shell_profile" ]; then
    if ! grep -q "# Docker Dev Environment" "$shell_profile" 2>/dev/null; then
        log_info "Adding 'dev' command to $shell_profile"

        # Detect SSH agent socket location
        ssh_socket=""
        if [ -n "$SSH_AUTH_SOCK" ]; then
            ssh_socket="$SSH_AUTH_SOCK"
        elif [ -S "$HOME/.ssh/auth_sock" ]; then
            ssh_socket="$HOME/.ssh/auth_sock"
        else
            log_warning "SSH agent not found - SSH forwarding may not work"
        fi

        cat >> "$shell_profile" << EOF

# Docker Dev Environment
dev() {
    # Ensure Podman machine is running (macOS)
    if command -v podman machine >/dev/null 2>&1; then
        if ! podman machine list --format json 2>/dev/null | jq -r '.[0].Running' 2>/dev/null | grep -q true; then
            echo "Starting Podman machine..."
            podman machine start >/dev/null 2>&1
        fi
    fi

    # Set up SSH agent forwarding
    local ssh_args=""
    if [ -n "${ssh_socket}" ]; then
        ssh_args="-v ${ssh_socket}:/ssh-agent -e SSH_AUTH_SOCK=/ssh-agent"
    fi

    # Set up clipboard forwarding based on OS
    local clipboard_args=""
    case "\$(uname)" in
        Darwin)
            # macOS clipboard forwarding
            clipboard_args="-v /var/run/docker.sock:/var/run/docker.sock"
            ;;
        Linux)
            # Linux clipboard forwarding
            if [ -n "\$DISPLAY" ]; then
                clipboard_args="-e DISPLAY=\$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix"
            elif [ -n "\$WAYLAND_DISPLAY" ]; then
                clipboard_args="-e WAYLAND_DISPLAY=\$WAYLAND_DISPLAY -v \$XDG_RUNTIME_DIR/\$WAYLAND_DISPLAY:/tmp/\$WAYLAND_DISPLAY"
            fi
            ;;
    esac

    podman run -it --rm \\
        --security-opt no-new-privileges \\
        \$ssh_args \\
        \$clipboard_args \\
        -v ~/Projects:/workspace/projects \\
        -v ~/.devenv/data:/home/edgar/.local/share \\
        -v ~/.devenv/atuin:/home/edgar/.config/atuin \\
        -v ~/.devenv/claude:/home/edgar/.claude \\
        -v ~/.devenv/config:/home/edgar/.config \\
        -v /var/run/docker.sock:/var/run/docker.sock \\
        -e TERM_THEME="catppuccin-mocha" \\
        devenv:latest "\$@"
}

# Podman compatibility
alias docker=podman

# Quick dev commands
alias dev-git='dev lazygit'
alias dev-files='dev yazi'
alias dev-code='dev nvim'

EOF
        log_success "Shell function 'dev' added to $shell_profile"
    else
        log_success "Shell integration already configured"
    fi
fi

echo

# Step 4: Final setup validation
echo "🎯 Final setup validation..."

# Test container
log_info "Testing container startup..."
if podman run --rm devenv:latest echo "Container test successful" >/dev/null 2>&1; then
    log_success "Container startup test passed"
else
    log_error "Container startup test failed"
    exit 1
fi

# Check volumes
log_info "Verifying volume mounts..."
if [ -d ~/.devenv/data ] && [ -d ~/.devenv/config ]; then
    log_success "Volume directories ready"
else
    log_error "Volume directories missing"
    exit 1
fi

# Check SSH setup
if [ -f ~/.devenv/secrets/id_rsa ]; then
    log_success "SSH keys configured"
else
    log_warning "SSH keys not found (some features may not work)"
fi

echo

echo "🎉 Setup complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Quick start:"
echo "   1. Restart your terminal (or run: ${BLUE}source $shell_profile${NC})"
echo "   2. Type '${GREEN}dev${NC}' to enter your development environment"
printf "   3. Your projects are available in %s/workspace/projects/%s\n" "${BLUE}" "${NC}"
echo
echo "📚 Available tools:"
echo "   • ${PURPLE}Neovim${NC} (nvim) with LazyVim and Catppuccin Mocha theme"
echo "   • ${PURPLE}Claude Code${NC} (claude --dangerously-skip-permissions)"
echo "   • ${PURPLE}Git UI${NC} (lazygit) with beautiful diff viewer"
echo "   • ${PURPLE}File manager${NC} (yazi) with preview support"
echo "   • ${PURPLE}Terminal multiplexer${NC} (tmux) with persistent sessions"
echo "   • ${PURPLE}Modern CLI tools${NC} (rg, fd, fzf, lsd, dust, delta, btop)"
echo "   • ${PURPLE}Kubernetes tools${NC} (kubectl, helm, k9s, kubectx/kubens)"
echo "   • ${PURPLE}Node.js${NC} with nvm and latest LTS"
echo
echo "💡 Quick commands:"
echo "   • ${BLUE}dev${NC}           - Enter development environment"
echo "   • ${BLUE}dev-git${NC}       - Open lazygit"
echo "   • ${BLUE}dev-files${NC}     - Open yazi file manager"
echo "   • ${BLUE}dev-code${NC}      - Open Neovim"
echo
echo "🎨 Theme:"
echo "   Everything is themed with ${PURPLE}Catppuccin Mocha${NC} for a beautiful,"
echo "   consistent development experience."
echo
echo "📖 Documentation:"
echo "   • README.md - Complete tool documentation"
echo "   • CUSTOMIZATION.md - Personal configuration guide"
echo
echo "🔧 Next steps:"
printf "   • Add projects to %s~/Projects/%s\n" "${BLUE}" "${NC}"
printf "   • Customize configs in %s~/.devenv/config/%s\n" "${BLUE}" "${NC}"
echo "   • Set up git credentials in the container"

if [ ! -f ~/.devenv/secrets/atuin_key ]; then
    echo "   • Run ${BLUE}dev atuin register${NC} to set up history sync"
fi

echo
echo "Happy coding! 🚀"