#!/bin/bash

# Interactive configuration addition script
# Helps users add their personal configurations to the development environment

set -e

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

echo "🔧 Docker Development Environment - Configuration Manager"
echo "========================================================"
echo
echo "This tool helps you add your personal configurations to the development environment."
echo
echo "What would you like to add?"
echo
echo "${PURPLE}1)${NC} SSH Key (existing or generate new)"
echo "${PURPLE}2)${NC} Git Configuration (name, email, aliases)"
echo "${PURPLE}3)${NC} API Keys and Tokens"
echo "${PURPLE}4)${NC} Neovim Configuration"
echo "${PURPLE}5)${NC} Tmux Configuration"
echo "${PURPLE}6)${NC} Shell Aliases and Functions"
echo "${PURPLE}7)${NC} Show current configuration status"
echo "${PURPLE}8)${NC} Exit"
echo

read -p "Choose an option (1-8): " choice

# Handle empty input
if [ -z "$choice" ]; then
    log_warning "No option selected. Defaulting to option 7 (show status)"
    choice="7"
fi

case $choice in
    1)
        echo
        echo "🔑 SSH Key Setup"
        echo "==============="
        ./scripts/helpers/add-ssh-key.sh
        ;;
    2)
        echo
        echo "📝 Git Configuration"
        echo "==================="
        ./scripts/helpers/add-git-config.sh
        ;;
    3)
        echo
        echo "🔐 API Keys and Tokens"
        echo "====================="
        ./scripts/helpers/add-api-keys.sh
        ;;
    4)
        echo
        echo "📝 Neovim Configuration"
        echo "======================"
        ./scripts/helpers/add-nvim-config.sh
        ;;
    5)
        echo
        echo "🖥️  Tmux Configuration"
        echo "====================="
        ./scripts/helpers/add-tmux-config.sh
        ;;
    6)
        echo
        echo "🐚 Shell Configuration"
        echo "======================"
        ./scripts/helpers/add-shell-config.sh
        ;;
    7)
        echo
        echo "📊 Current Configuration Status"
        echo "==============================="
        ./scripts/helpers/show-status.sh
        ;;
    8)
        echo
        log_info "Goodbye! Happy coding! 🚀"
        exit 0
        ;;
    *)
        log_error "Invalid choice: '$choice'"
        log_error "Please select 1-8."
        exit 1
        ;;
esac

echo
echo "Configuration complete! 🎉"
echo
echo "💡 Next steps:"
echo "   • Run the container to test your changes: ${GREEN}dev${NC}"
echo "   • See all available options: ${GREEN}./scripts/helpers/add-config.sh${NC}"
echo "   • View documentation: ${GREEN}cat README.md${NC}"