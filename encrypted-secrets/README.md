# 🔐 Encrypted Secrets Structure

This directory contains encrypted personal configurations and secrets for your Docker development environment.

## 📁 Directory Structure

```
encrypted-secrets/
├── ssh/                    # SSH keys
│   ├── id_rsa.age         # Private SSH key (encrypted)
│   └── id_rsa.pub.age     # Public SSH key (encrypted)
│
├── git/                    # Git configuration
│   └── gitconfig.age      # Personal git config (encrypted)
│
├── claude/                 # Claude Code settings
│   ├── session.age        # Claude session data (encrypted)
│   └── api_key.age        # Claude API key (encrypted)
│
├── atuin/                  # Shell history sync
│   ├── key.age            # Atuin encryption key (encrypted)
│   └── config.toml.age    # Atuin configuration (encrypted)
│
├── api-keys/               # Development API keys
│   └── tokens.age         # Environment variables with API keys (encrypted)
│
├── configs/                # Personal tool configurations
│   ├── nvim/              # Neovim customizations
│   │   ├── keymaps.lua.age
│   │   └── plugins.lua.age
│   ├── tmux/              # Tmux customizations
│   │   └── custom.conf.age
│   └── zsh/               # Shell customizations
│       └── aliases.zsh.age
│
└── README.md              # This file
```

## 🔑 Encryption Setup

### 1. Generate Age Key Pair

```bash
# Generate encryption key
age-keygen -o private.key

# Extract public key
age-keygen -y private.key > public.key

# Keep your private key safe!
cp private.key ~/.devenv-setup/
```

### 2. Encrypt Files

```bash
# Encrypt SSH private key
age -r $(cat public.key) ~/.ssh/id_rsa > encrypted-secrets/ssh/id_rsa.age

# Encrypt SSH public key
age -r $(cat public.key) ~/.ssh/id_rsa.pub > encrypted-secrets/ssh/id_rsa.pub.age

# Encrypt git config
age -r $(cat public.key) ~/.gitconfig > encrypted-secrets/git/gitconfig.age

# Encrypt API keys file
age -r $(cat public.key) ~/my-api-keys.env > encrypted-secrets/api-keys/tokens.age
```

### 3. Decrypt Files (done automatically by setup scripts)

```bash
# Decrypt SSH key
age -d -i private.key encrypted-secrets/ssh/id_rsa.age > ~/.devenv/secrets/id_rsa

# Decrypt git config
age -d -i private.key encrypted-secrets/git/gitconfig.age > ~/.devenv/config/git/config
```

## 📝 Example Files

### SSH Keys (`ssh/`)
- **id_rsa.age**: Your private SSH key for Git authentication
- **id_rsa.pub.age**: Your public SSH key

### Git Config (`git/gitconfig.age`)
```ini
[user]
    name = Edgar Post
    email = edgar@example.com
    signingkey = ~/.ssh/id_rsa.pub

[core]
    editor = nvim
    pager = delta

[alias]
    lg = log --graph --oneline --decorate
    st = status -sb
```

### API Keys (`api-keys/tokens.age`)
```bash
# Development API Keys
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
ANTHROPIC_API_KEY=sk-ant-api03-xxxxxxxxxxxxxxxxxxxx
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxx
DOCKER_HUB_TOKEN=dckr_pat_xxxxxxxxxxxxxxxxxxxx

# Cloud Provider Keys
AWS_ACCESS_KEY_ID=AKIAxxxxxxxxxxxxxxxxxxxx
AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxx
AZURE_CLIENT_ID=xxxxxxxxxxxxxxxxxxxx

# Database URLs
DATABASE_URL=postgresql://user:pass@localhost:5432/mydb
REDIS_URL=redis://localhost:6379

# Service API Keys
STRIPE_SECRET_KEY=sk_test_xxxxxxxxxxxxxxxxxxxx
SENDGRID_API_KEY=SG.xxxxxxxxxxxxxxxxxxxx
```

### Atuin Config (`atuin/config.toml.age`)
```toml
# Atuin shell history configuration
sync_address = "https://api.atuin.sh"
sync_frequency = "1h"
search_mode = "fuzzy"
filter_mode = "global"
update_check = false
```

### Claude Code (`claude/session.age`)
Contains your Claude Code authentication session and preferences.

## 🔄 Usage Workflow

### Initial Setup
1. **Generate age keys**: `age-keygen -o private.key`
2. **Encrypt your secrets**: Use the encryption commands above
3. **Commit to git**: All `.age` files are safe to commit
4. **Keep private key secure**: Store in password manager

### New Machine Setup
1. **Clone repository**: Contains encrypted secrets
2. **Get private key**: From secure storage
3. **Run setup**: Scripts automatically decrypt and configure
4. **Start developing**: Everything is ready!

### Updating Secrets
1. **Decrypt**: `age -d -i private.key file.age > file`
2. **Edit**: Make your changes
3. **Re-encrypt**: `age -r $(cat public.key) file > file.age`
4. **Commit**: Updated encrypted file

## 🔒 Security Best Practices

### ✅ Do
- **Keep private key secure** in password manager
- **Use strong, unique password** for private key
- **Commit only .age files** to git
- **Regularly rotate keys** and secrets
- **Use different keys** for different environments

### ❌ Don't
- **Never commit raw secrets** to git
- **Don't share private key** over insecure channels
- **Don't use same key** for multiple purposes
- **Don't skip encryption** for "temporary" secrets

## 🛠️ Automation Scripts

The helper scripts automatically handle encryption/decryption:

```bash
# Interactive configuration setup
./scripts/helpers/add-config.sh

# Add encrypted SSH key
./scripts/helpers/add-ssh-key.sh

# Add encrypted Git config
./scripts/helpers/add-git-config.sh

# Check configuration status
./scripts/helpers/show-status.sh
```

## 🔄 Key Rotation

When rotating your age encryption key:

```bash
# 1. Generate new key pair
age-keygen -o new-private.key
age-keygen -y new-private.key > new-public.key

# 2. Re-encrypt all files with new key
for file in encrypted-secrets/**/*.age; do
    decrypted=$(age -d -i private.key "$file")
    echo "$decrypted" | age -r $(cat new-public.key) > "$file.new"
    mv "$file.new" "$file"
done

# 3. Replace old keys
mv private.key old-private.key
mv new-private.key private.key
mv public.key old-public.key
mv new-public.key public.key

# 4. Test decryption and commit
```

## 💾 Backup Strategy

- **Git repository**: Contains all encrypted secrets
- **Private key**: Store in multiple secure locations
- **Local backup**: Regular exports of decrypted configs
- **Cloud backup**: Encrypted repository in multiple git services

---

🔐 **Remember**: The security of this system depends on keeping your private key secure!

*For more information, see [CUSTOMIZATION.md](../CUSTOMIZATION.md)*