#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
# Colors & Logging
# ─────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${BLUE}${BOLD}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}${BOLD}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}${BOLD}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}${BOLD}[ERROR]${RESET} $*" >&2; }

die() { error "$*"; exit 1; }

# ─────────────────────────────────────────────
# Safety checks
# ─────────────────────────────────────────────
[[ $EUID -eq 0 ]] && die "Do not run this script as root."
command -v pacman &>/dev/null || die "This script requires an Arch-based system."

# ─────────────────────────────────────────────
# Config
# ─────────────────────────────────────────────
DOTFILES_REPO="https://github.com/Shashwat-0077/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"
DOTFILES_STOW_DIR="$DOTFILES_DIR/stow"
ZSH_PATH="/bin/zsh"

PACMAN_PACKAGES=(
    nvidia-dkms linux-headers nvidia-utils nvidia-settings cmake ninja
)

YAY_PACKAGES=(
    hyprland wayland wayland-protocols kitty wofi neovim zed git curl wget unzip zip stow
    ttf-jetbrains-mono-nerd noto-fonts noto-fonts-cjk noto-fonts-emoji
    keychain zoxide starship fzf zsh ttf-liberation supergfxctl qt6-base
    qt6-declarative qt6-wayland qt6-svg qt6-imageformats qt6-5compat qt6-tools
    qt6-shadertools quickshell-git swww
)

# ─────────────────────────────────────────────
# Functions
# ─────────────────────────────────────────────
install_yay() {
    if command -v yay &>/dev/null; then
        success "yay is already installed."
        return
    fi

    info "Installing yay..."
    local tmp_dir
    tmp_dir=$(mktemp -d)
    trap "rm -rf '$tmp_dir'" RETURN

    git clone https://aur.archlinux.org/yay.git "$tmp_dir/yay" \
        || die "Failed to clone yay repository."
    (cd "$tmp_dir/yay" && makepkg -si --noconfirm) \
        || die "Failed to build/install yay."

    success "yay installed."
}

install_packages() {
    info "Installing base-devel and git..."
    sudo pacman -S --needed --noconfirm base-devel git \
        || die "Failed to install base dependencies."

    info "Updating system..."
    yay -Syu --noconfirm || die "System update failed."

    info "Installing packages via yay..."
    yay -S --needed --noconfirm "${YAY_PACKAGES[@]}" \
        || die "Failed to install yay packages."

    success "Packages installed."
}

setup_shell() {
    if [[ "$SHELL" == "$ZSH_PATH" ]]; then
        success "Zsh is already the default shell."
        return
    fi

    if ! grep -q "$ZSH_PATH" /etc/shells; then
        warn "Zsh not found in /etc/shells. Skipping shell change."
        return
    fi

    info "Setting Zsh as default shell..."
    chsh -s "$ZSH_PATH" || die "Failed to set Zsh as default shell."
    success "Default shell set to Zsh."
}

setup_nvidia() {
    info "Installing NVIDIA packages..."
    sudo pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}" \
        || die "Failed to install NVIDIA packages."

    info "Enabling DRM modeset..."
    sudo mkdir -p /etc/modprobe.d
    echo "options nvidia_drm modeset=1" \
        | sudo tee /etc/modprobe.d/nvidia.conf > /dev/null

    info "Configuring Early KMS in mkinitcpio.conf..."
    if ! grep -q "nvidia_drm" /etc/mkinitcpio.conf; then
        sudo sed -i \
            '/^MODULES=/ s/)/ nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' \
            /etc/mkinitcpio.conf \
            || die "Failed to update mkinitcpio.conf."
    else
        warn "NVIDIA modules already present in mkinitcpio.conf. Skipping."
    fi

    info "Rebuilding initramfs..."
    sudo mkinitcpio -P || die "mkinitcpio failed."

    info "Enabling services..."
    sudo systemctl enable --now dkms.service    || warn "Failed to enable dkms.service."
    sudo systemctl enable --now supergfxd.service || warn "Failed to enable supergfxd.service."

    success "NVIDIA setup complete."
}

setup_dotfiles() {
    # Back up existing Hypr config instead of deleting it
    local hypr_config="$HOME/.config/hypr"
    if [[ -d "$hypr_config" ]]; then
        local backup="${hypr_config}.bak.$(date +%Y%m%d_%H%M%S)"
        warn "Existing Hypr config found. Backing up to: $backup"
        mv "$hypr_config" "$backup"
    fi

    if [[ -d "$DOTFILES_DIR" ]]; then
        info "Dotfiles directory exists. Pulling latest changes..."
        git -C "$DOTFILES_DIR" pull || die "Failed to pull dotfiles."
    else
        info "Cloning dotfiles..."
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR" \
            || die "Failed to clone dotfiles repository."
    fi

    [[ -d "$DOTFILES_STOW_DIR" ]] \
        || die "Stow directory not found: $DOTFILES_STOW_DIR"

    info "Stowing dotfiles..."
    cd "$DOTFILES_STOW_DIR"
    for pkg in */; do
        pkg="${pkg%/}"  # strip trailing slash
        info "Stowing $pkg..."
        stow --target="$HOME" "$pkg" || die "stow failed on package: $pkg"
    done
    cd "$HOME"

    success "Dotfiles setup complete."
}

# ─────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────
main() {
    echo -e "\n${BOLD}╔══════════════════════════════╗"
    echo -e   "║     Arch Setup Script        ║"
    echo -e   "╚══════════════════════════════╝${RESET}\n"

    install_yay
    install_packages
    setup_shell
    setup_nvidia
    setup_dotfiles

    echo -e "\n${GREEN}${BOLD}✔ Setup complete!${RESET}"
    warn "A reboot is recommended to apply all changes."
}

main "$@"
