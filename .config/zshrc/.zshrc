# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  git
  rails
  ruby
  bundler
  node
  npm
  yarn
  zsh-autosuggestions
  zsh-syntax-highlighting
  fzf
  z
)

source $ZSH/oh-my-zsh.sh

export EDITOR="cursor --wait"
export VISUAL="$EDITOR"

# Load p10k config (run `p10k configure` to regenerate)
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# --- Homebrew ---
if [[ -f /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# --- nvm ---
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ]          && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"

# --- rbenv ---
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init - zsh)"

# --- PostgreSQL (Homebrew) ---
export PATH="$(brew --prefix)/opt/postgresql@16/bin:$PATH"

# --- fzf ---
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# --- Editor ---
export EDITOR="cursor --wait"
export VISUAL="$EDITOR"

# --- Locale ---
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# --- Aliases ---
# General
alias ls='eza --color=always --icons=always --group-directories-first'
alias ll='eza --color=always --icons=always --group-directories-first -l --git -h'
alias reload='source ~/.zshrc'
alias zshrc='$EDITOR ~/.zshrc'

# Git
alias gbrm="git branch | grep -v 'master' | xargs git branch -D"

# PATH
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
