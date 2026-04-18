#!/usr/bin/env bash
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${BLUE}==>${NC} $1"; }
ok()   { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}!${NC} $1"; }

# =============================================================================
# 0. CONFIGURATION — edit these before running
# =============================================================================

GIT_NAME="Your Name"
GIT_EMAIL="you@example.com"

# Homebrew formulae
BREW_FORMULAE=(
  borders
  git
  curl
  wget
  fzf
  eza          # modern ls replacement
  rbenv
  ruby-build
  node         # LTS fallback (nvm will manage versions too)
  yarn
  gh           # GitHub CLI
  jq
  htop
  postgresql@16
  redis
)

# Homebrew casks (GUI apps) — comment out anything you don't want
BREW_CASKS=(
  iterm2
  google-chrome
  raycast
  cursor
  slack
  spotify
  aerospace          # tiling window manager
  jordanbaird-ice    # menu bar manager (Ice)
)

# =============================================================================
# 1. XCODE COMMAND LINE TOOLS
# =============================================================================

log "Checking Xcode Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
  xcode-select --install
  warn "Xcode CLT installer launched — complete it, then re-run this script."
  exit 1
else
  ok "Xcode CLT already installed"
fi

# =============================================================================
# 2. HOMEBREW
# =============================================================================

log "Setting up Homebrew..."
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
else
  ok "Homebrew already installed"
fi

log "Updating Homebrew..."
brew update --quiet

brew tap FelixKratz/formulae

log "Installing formulae..."
for formula in "${BREW_FORMULAE[@]}"; do
  if brew list "$formula" &>/dev/null; then
    ok "$formula already installed"
  else
    brew install "$formula" && ok "Installed $formula"
  fi
done

log "Installing casks..."
for cask in "${BREW_CASKS[@]}"; do
  if brew list --cask "$cask" &>/dev/null; then
    ok "$cask already installed"
  else
    brew install --cask "$cask" && ok "Installed $cask"
  fi
done

# =============================================================================
# 3. POSTGRESQL & REDIS — start services
# =============================================================================

log "Starting PostgreSQL, Redis and Borders services..."
brew services start postgresql@16 2>/dev/null || true
brew services start redis          2>/dev/null || true
brew services start borders       2>/dev/null || true
ok "PostgreSQL, Redis and Borders services started"

# =============================================================================
# 4. OH MY ZSH
# =============================================================================

log "Setting up Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  ok "Oh My Zsh installed"
else
  ok "Oh My Zsh already installed"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# =============================================================================
# 5. POWERLEVEL10K
# =============================================================================

log "Installing Powerlevel10k..."
if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "$ZSH_CUSTOM/themes/powerlevel10k"
  ok "Powerlevel10k installed"
else
  ok "Powerlevel10k already installed"
fi

# =============================================================================
# 6. ITERM2 — CATPPUCCIN MOCHA THEME
# =============================================================================

log "Downloading iTerm2 Catppuccin Mocha theme..."
mkdir -p "$HOME/.config"
CATPPUCCIN_FILE="$HOME/.config/catppuccin-mocha.itermcolors"

if [ ! -f "$CATPPUCCIN_FILE" ]; then
  curl -fsSL \
    "https://raw.githubusercontent.com/catppuccin/iterm/main/colors/catppuccin-macchiato.itermcolors" \
    -o "$CATPPUCCIN_FILE"
  # Auto-import into iTerm2 if it's running
  open "$CATPPUCCIN_FILE" 2>/dev/null || true
  ok "Catppuccin Mocha downloaded — will auto-import when iTerm2 opens"
else
  ok "Catppuccin theme already downloaded"
fi

# =============================================================================
# 7. NVM (NODE VERSION MANAGER)
# =============================================================================

log "Setting up nvm..."
if [ ! -d "$HOME/.nvm" ]; then
  NVM_VERSION=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest \
    | grep '"tag_name"' | cut -d'"' -f4)
  curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
  ok "nvm installed"
else
  ok "nvm already installed"
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

log "Installing Node LTS via nvm..."
nvm install --lts
nvm alias default node
ok "Node $(node -v) set as default"

# =============================================================================
# 8. RBENV + RUBY
# =============================================================================

log "Setting up rbenv + Ruby..."
rm -f "$HOME/.rbenv/shims/.rbenv-shim"

LATEST_RUBY=$(rbenv install -l 2>/dev/null | grep -E '^\s*[0-9]+\.[0-9]+\.[0-9]+$' | tail -1 | tr -d ' ')
log "Installing Ruby $LATEST_RUBY..."
if rbenv versions | grep -q "$LATEST_RUBY"; then
  ok "Ruby $LATEST_RUBY already installed"
else
  rbenv install "$LATEST_RUBY"
  ok "Ruby $LATEST_RUBY installed"
fi
rbenv global "$LATEST_RUBY"

log "Installing core Ruby gems..."
gem install bundler rails --no-document
ok "bundler + rails installed"

# =============================================================================
# 9. GIT CONFIGURATION
# =============================================================================

log "Configuring Git..."
git config --global user.name  "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
git config --global init.defaultBranch main
git config --global core.editor "nano"
ok "Git configured"

# =============================================================================
# 10. MISC FILES
# =============================================================================

log "Creating .hushlogin..."
touch "$HOME/.hushlogin"
ok ".hushlogin created (suppresses 'last login' message)"

# =============================================================================
# 11. MACOS SYSTEM DEFAULTS
# =============================================================================

log "Applying macOS system defaults..."

# --- Dock ---
defaults write com.apple.dock orientation                  -string "left"
defaults write com.apple.dock autohide                     -bool true

# --- Battery percentage in menu bar ---
defaults write com.apple.menuextra.battery ShowPercent     -string "YES"

# --- Disable Siri ---
defaults write com.apple.assistant.support 'Assistant Enabled' -bool false
defaults write com.apple.Siri StatusMenuVisible            -bool false
defaults write com.apple.Siri UserHasDeclinedEnable        -bool true
launchctl disable "user/$UID/com.apple.Siri.agent" 2>/dev/null || true
ok "Siri disabled"

# --- Finder ---
defaults write com.apple.finder ShowPathbar                -bool true
defaults write com.apple.finder ShowStatusBar              -bool true
defaults write com.apple.finder _FXShowPosixPathInTitle    -bool true
defaults write com.apple.finder FXDefaultSearchScope       -string "SCcf"
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write NSGlobalDomain AppleShowAllExtensions       -bool true
# Show ~/Library folder
chflags nohidden ~/Library
# Show hidden files (dotfiles visible in Finder)
defaults write com.apple.finder AppleShowAllFiles          -bool true

# --- Screenshots → ~/Desktop/Screenshots ---
mkdir -p "$HOME/Desktop/Screenshots"
defaults write com.apple.screencapture location            "$HOME/Desktop/Screenshots"

# --- Keyboard ---
# Disable auto-capitalise
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled     -bool false
# Disable "add full stop with double-space"
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
# Disable smart quotes and dashes
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled  -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled   -bool false
# Disable autocorrect
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# --- Trackpad ---
# Natural scroll: OFF
defaults write NSGlobalDomain com.apple.swipescrolldirection       -bool false
# Tap to click: ON
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write com.apple.AppleMultitouchTrackpad Clicking          -bool true
# Right-click: bottom-right corner tap
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick          -bool false
defaults write com.apple.AppleMultitouchTrackpad TrackpadCornerSecondaryClick                 -int 2
defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick                           -bool false

ok "macOS defaults applied"

# =============================================================================
# 12. Copy config files
# =============================================================================

log "Copying config files..."
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.config"
cp "$DOTFILES_DIR/zshrc/.zshrc" "$HOME/.zshrc"
cp "$DOTFILES_DIR/p10k/.p10k.zsh" "$HOME/.p10k.zsh"
cp "$DOTFILES_DIR/aerospace/.aerospace.toml" "$HOME/.aerospace.toml"
ok "Config files copied"

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  Setup complete! 🎉${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "A few things to do manually:"
echo ""
echo "  1.  Edit GIT_NAME / GIT_EMAIL at the top of this script"
echo "  2.  In iTerm2: Profiles → Colors → Color Presets → Import"
echo "      File: ~/.config/catppuccin-mocha.itermcolors"
echo "  3.  Enable Nightshift"
echo "  4.  1Password: sign in and enable the browser extension"
echo "  5.  Raycast: launch and complete onboarding, disable Spotlight shortcut"
echo ""