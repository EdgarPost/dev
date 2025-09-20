#!/bin/bash

# Git Configuration Helper
# Helps users set up their Git configuration

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "   ${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "   ${GREEN}✓${NC} $1"; }
log_warning() { echo -e "   ${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "   ${RED}❌${NC} $1"; }

echo "📝 Git Configuration Setup"
echo

# Create config directory
mkdir -p ~/.devenv/config/git/

# Get user information
echo "Enter your Git configuration details:"
echo

read -p "Full name: " git_name
read -p "Email address: " git_email

# Optional signing key
echo
echo "Do you want to set up commit signing?"
echo "1) Use SSH key for signing (recommended)"
echo "2) Use GPG key for signing"
echo "3) Skip signing setup"
echo

read -p "Choose option (1-3): " signing_option

signing_config=""
case $signing_option in
    1)
        if [ -f ~/.devenv/secrets/id_rsa.pub ]; then
            signing_config="
[gpg]
    format = ssh

[user]
    signingkey = ~/.ssh/id_rsa.pub

[commit]
    gpgsign = true"
            log_success "SSH signing configured"
        else
            log_warning "SSH key not found. Set up SSH key first."
            signing_config=""
        fi
        ;;
    2)
        read -p "Enter GPG key ID: " gpg_key
        if [ ! -z "$gpg_key" ]; then
            signing_config="
[user]
    signingkey = $gpg_key

[commit]
    gpgsign = true"
            log_success "GPG signing configured"
        fi
        ;;
    3)
        log_info "Skipping signing setup"
        ;;
esac

# Create git config
cat > ~/.devenv/config/git/config << EOF
[user]
    name = $git_name
    email = $git_email$signing_config

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
    syntax-theme = Catppuccin-mocha

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

[rebase]
    autoStash = true

[alias]
    # Beautiful log
    lg = log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit

    # Short log
    lgs = log --color --graph --pretty=format:'%Cred%h%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit -10

    # Status shortcuts
    st = status -sb
    s = status

    # Add shortcuts
    a = add
    aa = add --all

    # Commit shortcuts
    c = commit
    cm = commit -m
    ca = commit --amend
    cane = commit --amend --no-edit

    # Branch shortcuts
    b = branch
    ba = branch -a
    bd = branch -d
    bD = branch -D

    # Checkout shortcuts
    co = checkout
    cob = checkout -b

    # Diff shortcuts
    d = diff
    ds = diff --staged
    dc = diff --cached

    # Push/Pull shortcuts
    p = push
    pf = push --force-with-lease
    pl = pull

    # Stash shortcuts
    ss = stash
    sp = stash pop
    sl = stash list

    # Reset shortcuts
    r = reset
    r1 = reset HEAD~1
    rh = reset --hard
    rs = reset --soft

    # Remote shortcuts
    rv = remote -v
    ra = remote add

    # Undo last commit but keep changes
    undo = reset HEAD~1 --mixed

    # Amend last commit
    amend = commit --amend --no-edit

    # Clean up merged branches
    cleanup = "!git branch --merged | grep -v '\\*\\|main\\|master\\|develop' | xargs -n 1 git branch -d"

    # Show what was changed in last commit
    last = show --stat

    # Show files changed in commit
    changed = diff-tree --no-commit-id --name-only -r

    # Find commits by message
    find = "!f() { git log --pretty=format:'%h %cd %s [%an]' --date=short --grep=\"\$1\"; }; f"

    # Show git aliases
    aliases = "!git config -l | grep alias | cut -c7-"

    # Sync with upstream
    sync = "!git fetch upstream && git checkout main && git merge upstream/main && git push origin main"

[color]
    ui = auto

[color "branch"]
    current = yellow reverse
    local = yellow
    remote = green

[color "diff"]
    meta = yellow bold
    frag = magenta bold
    old = red bold
    new = green bold

[color "status"]
    added = yellow
    changed = green
    untracked = cyan

[url "git@github.com:"]
    insteadOf = https://github.com/
EOF

log_success "Git configuration created"

# Show what was configured
echo
echo "📋 Git Configuration Summary:"
echo "   • Name: $git_name"
echo "   • Email: $git_email"
if [ ! -z "$signing_config" ]; then
    echo "   • Signing: Enabled"
fi
echo "   • Editor: Neovim"
echo "   • Default branch: main"
echo "   • Diff viewer: Delta with Catppuccin theme"
echo "   • Useful aliases: lg, st, aa, cm, co, etc."

echo
echo "✅ Git configuration complete!"
echo
echo "💡 Next steps:"
echo "   • Test configuration: ${GREEN}dev git config --list${NC}"
echo "   • View aliases: ${GREEN}dev git aliases${NC}"
echo "   • Make a test commit: ${GREEN}dev git commit -m \"test: verify git config\"${NC}"
echo
echo "🔧 Pro tip: Use ${GREEN}git lg${NC} for a beautiful commit history view!"