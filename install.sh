#!/bin/bash

# --- 1. Define Package Lists ---
# Standard Arch Repository Packages
PACMAN_PKGS=(
    hyprland swww waybar kitty rofi swaync brightnessctl 
    bluez bluez-utils zsh blueman obsidian stow grim 
    slurp swappy wl-clipboard pipewire wireplumber 
    pipewire-alsa pipewire-pulse ttf-jetbrains-mono-nerd 
    nfs-utils xdg-desktop-portal-hyprland xdg-utils 
    neovim xdg-desktop-portal-gtk xorg-xwayland 
    nodejs npm tree
)

# AUR Packages (Require yay)
AUR_PKGS=(
    brave-bin
    eza             # Modern replacement for 'exa'
    ristretto       # Sometimes in extra, sometimes AUR; yay handles both
    wiremix-git     # Assuming the git version for wiremix
)

echo "🚀 Starting Installation Script..."

# --- 2. Install 'yay' (AUR Helper) if not present ---
if ! command -v yay &> /dev/null; then
    echo "📦 'yay' not found. Installing now..."
    sudo pacman -S --needed git base-devel
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay && makepkg -si --noconfirm
    cd - || exit
else
    echo "✅ 'yay' is already installed."
fi

# --- 3. Install Everything via yay ---
echo "📥 Installing all packages..."
yay -S --needed "${PACMAN_PKGS[@]}" "${AUR_PKGS[@]}"

# --- 4. Setup Oh-My-Zsh ---
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "🐚 Installing Oh-My-Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# --- 5. Fix Directory Conflicts for Stow ---
echo "🧹 Preparing ~/.config for symlinks..."
REMOVE_TARGETS=(
    "$HOME/.config/hypr"
    "$HOME/.config/waybar"
    "$HOME/.config/kitty"
    "$HOME/.config/rofi"
    "$HOME/.config/swaync"
    "$HOME/.config/wallpapers"
    "$HOME/.zshrc"
)

for target in "${REMOVE_TARGETS[@]}"; do
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo "Backing up $target to ${target}.bak"
        mv "$target" "${target}.bak"
    fi
done

# --- 6. Apply Symlinks via Stow ---
echo "🔗 Stowing configurations from ~/dot-rice..."
cd ~/dot-rice || { echo "❌ Error: ~/dot-rice not found!"; exit 1; }
stow -v -t ~ hypr waybar kitty rofi swaync bin zsh wallpapers-config

# --- 7. Final Services Setup ---
echo "⚙️ Enabling services..."
sudo systemctl enable --now bluetooth

# Set ZSH as default shell
if [ "$SHELL" != "/usr/bin/zsh" ]; then
    chsh -s "$(which zsh)"
fi

echo "✨ All done! Log out and back in to see the changes."
