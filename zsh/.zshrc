# --- Package prerequisites ---
# REQUIRED_PACKAGES=(
#     keychain
#     zoxide
#     starship
#     fzf
#     zsh
# )

# Function to check if a package is installed
# is_installed() {
#     pacman -Qi "$1" &> /dev/null
# }

# Install missing packages silently unless needed
# MISSING=()
# for pkg in "${REQUIRED_PACKAGES[@]}"; do
#     if ! is_installed "$pkg"; then
#         MISSING+=("$pkg")
#     fi
# done

# if [ ${#MISSING[@]} -gt 0 ]; then
#     echo "Installing missing packages: ${MISSING[*]}"
#     sudo pacman -S --needed "${MISSING[@]}" || {
#         echo "❌ Package installation failed. Aborting setup."
#         return 1
#     }
# fi

# --- SSH key setup with keychain ---
SSH_KEY="$HOME/.ssh/id_ed25519"

# Stop further scripts if key doesn't exist
if [ ! -f "$SSH_KEY" ]; then
	echo "❌ No SSH key found at $SSH_KEY."
	echo "Generate one with: ssh-keygen -t ed25519 -C \"your_email@example.com\""
	return 1
fi

# Start keychain and add your key (quiet mode)
eval $(keychain --quiet --eval "$SSH_KEY")

# --- Zinit setup ---
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"

# Download Zinit if missing
if [ ! -d "$ZINIT_HOME" ]; then
	echo "⬇️  Installing Zinit..."
	mkdir -p "$(dirname "$ZINIT_HOME")"
	git clone --quiet https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# zinit Load starship
zinit ice depth=1
zinit light starship/starship

# Add in zsh plugins
zinit light-mode for \
	zsh-users/zsh-syntax-highlighting \
	zsh-users/zsh-completions \
	zsh-users/zsh-autosuggestions \
	Aloxaf/fzf-tab

# Add in snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found

# Remap autosuggest accept to Ctrl+F
bindkey '^F' autosuggest-accept

# --- History setup ---
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Load completions
autoload -U compinit && compinit

zinit cdreplay -q

# --- Completion styling ---
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-color '${(s.:.)LS_COLORS}'
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# --- Aliases ---
alias ls='ls --color'
alias c='clear'

# --- Initialize tools ---
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"
eval "$(starship init zsh)"

## [Completion]
## Completion scripts setup. Remove the following line to uninstall
[[ -f /home/shasha/.dart-cli-completion/zsh-config.zsh ]] && . /home/shasha/.dart-cli-completion/zsh-config.zsh || true
## [/Completion]

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

export NARGO_HOME="/home/shasha/.nargo"

export PATH="$PATH:$NARGO_HOME/bin"

export NARGO_HOME="/home/shasha/.nargo"

export PATH="$PATH:$NARGO_HOME/bin"
export PATH="${HOME}/.bb:${PATH}"
export PATH="/home/shasha/.bb:$PATH"

# pnpm
export PNPM_HOME="/home/shasha/.local/share/pnpm"
case ":$PATH:" in
*":$PNPM_HOME:"*) ;;
*) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
export PATH="/home/shasha/.bb:$PATH"

export ANDROID_SDK_ROOT=/opt/android-sdk
export ANDROID_HOME=/opt/android-sdk
export PATH=$PATH:/opt/android-sdk/cmdline-tools/latest/bin
export PATH=$PATH:/opt/android-sdk/platform-tools
export PATH=$PATH:/opt/android-sdk/emulator
