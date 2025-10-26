# --- SSH key setup with keychain ---
SSH_KEY="$HOME/.ssh/id_ed25519"

# Stop further scripts if key doesn't exist
if [ ! -f "$SSH_KEY" ]; then
    echo "No SSH key found at $SSH_KEY."
    echo "Generate one with: ssh-keygen -t ed25519 -C \"your_email@example.com\""
    return 1
fi

# Start keychain and add your key (modern syntax, quiet mode)
# This will ask passphrase **once per login** and keep the key in agent
eval $(keychain --quiet --eval "$SSH_KEY")


# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
    mkdir -p "$(dirname $ZINIT_HOME)"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi


# Check if zoxide is installed, install if missing
if ! command -v zoxide &> /dev/null; then
    echo "zoxide not found, installing via pacman..."
    sudo pacman -S --needed zoxide
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# zinit Load starship
zinit ice depth=1; zinit light starship/starship

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


# Remap autosuggest accept to Ctrl+Space
bindkey '^F' autosuggest-accept


# History
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

#Load completions 
autoload -U compinit && compinit

zinit cdreplay -q

# Completion Styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-color '${(s.:.)LS_COLORS}'
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Aliases
alias ls='ls --color'


eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"
eval "$(starship init zsh)"
