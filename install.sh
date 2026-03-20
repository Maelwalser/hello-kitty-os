#!/bin/bash
# ============================================================
#  🎀  Hello Kitty Y2K — Arch Linux KDE Plasma Theme Installer
#  ============================================================
#  Installs: Kvantum theme, Aurorae decorations, KDE colors,
#            Konsole colorscheme, SDDM theme, wallpaper,
#            and applies Plasma settings.
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
PINK='\033[38;5;213m'
MAGENTA='\033[38;5;198m'
WHITE='\033[1;37m'
RESET='\033[0m'

banner() {
    echo -e "${PINK}"
    echo "  ╔══════════════════════════════════════════════╗"
    echo "  ║                                              ║"
    echo "  ║    ♡  H E L L O   K I T T Y   Y 2 K  ♡     ║"
    echo "  ║                                              ║"
    echo "  ║     Arch Linux KDE Plasma Theme Installer    ║"
    echo "  ║                                              ║"
    echo "  ╚══════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

info() { echo -e "  ${PINK}✧${RESET} $1"; }
warn() { echo -e "  ${MAGENTA}⚠${RESET} $1"; }
success() { echo -e "  ${PINK}♡${RESET} $1"; }

banner

# ===== CHECK DEPENDENCIES =====
echo -e "${WHITE}Checking dependencies...${RESET}"

MISSING=()
for pkg in kvantum konsole sddm; do
    if ! pacman -Qi "$pkg" &>/dev/null; then
        MISSING+=("$pkg")
    fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
    warn "Missing packages: ${MISSING[*]}"
    read -p "  Install them now? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        sudo pacman -S --needed "${MISSING[@]}"
    else
        warn "Skipping package install. Some features may not work."
    fi
else
    info "All dependencies installed"
fi

# ===== CREATE DIRECTORIES =====
echo -e "\n${WHITE}Creating directories...${RESET}"

mkdir -p "$HOME/.config/Kvantum/HelloKittyY2K"
mkdir -p "$HOME/.local/share/aurorae/themes/HelloKittyY2K"
mkdir -p "$HOME/.local/share/color-schemes"
mkdir -p "$HOME/.local/share/konsole"
mkdir -p "$HOME/.local/share/wallpapers"
mkdir -p "$HOME/.local/share/plasma/desktoptheme/HelloKittyY2K"
info "Directories created"

# ===== INSTALL KVANTUM THEME =====
echo -e "\n${WHITE}Installing Kvantum theme...${RESET}"

cp "$SCRIPT_DIR/kvantum/HelloKittyY2K/HelloKittyY2K.kvconfig" \
   "$HOME/.config/Kvantum/HelloKittyY2K/"
cp "$SCRIPT_DIR/kvantum/HelloKittyY2K/HelloKittyY2K.svg" \
   "$HOME/.config/Kvantum/HelloKittyY2K/"

# Set as active Kvantum theme
mkdir -p "$HOME/.config/Kvantum"
cat > "$HOME/.config/Kvantum/kvantum.kvconfig" << 'EOF'
[General]
theme=HelloKittyY2K
EOF

success "Kvantum theme installed and activated"

# ===== INSTALL AURORAE DECORATION =====
echo -e "\n${WHITE}Installing Aurorae window decoration...${RESET}"

cp "$SCRIPT_DIR/aurorae/HelloKittyY2K/HelloKittyY2Krc" \
   "$HOME/.local/share/aurorae/themes/HelloKittyY2K/"
cp "$SCRIPT_DIR/aurorae/HelloKittyY2K/decoration.svg" \
   "$HOME/.local/share/aurorae/themes/HelloKittyY2K/"

success "Aurorae decoration installed"

# ===== INSTALL COLOR SCHEME =====
echo -e "\n${WHITE}Installing KDE color scheme...${RESET}"

cp "$SCRIPT_DIR/color-schemes/HelloKittyY2K.colors" \
   "$HOME/.local/share/color-schemes/"

success "Color scheme installed"

# ===== INSTALL KONSOLE COLORSCHEME =====
echo -e "\n${WHITE}Installing Konsole colorscheme...${RESET}"

cp "$SCRIPT_DIR/konsole/HelloKittyY2K.colorscheme" \
   "$HOME/.local/share/konsole/"

success "Konsole colorscheme installed"

# ===== INSTALL KITTY CONFIG =====
echo -e "\n${WHITE}Installing Kitty terminal config...${RESET}"

mkdir -p "$HOME/.config/kitty"
if [ -f "$HOME/.config/kitty/kitty.conf" ]; then
    cp "$HOME/.config/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf.bak"
    warn "Existing kitty.conf backed up to kitty.conf.bak"
fi
cp "$SCRIPT_DIR/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"

success "Kitty terminal config installed"

# ===== INSTALL WALLPAPER =====
echo -e "\n${WHITE}Installing wallpaper...${RESET}"

cp "$SCRIPT_DIR/wallpapers/hellokitty-y2k.svg" \
   "$HOME/.local/share/wallpapers/"

success "Wallpaper installed"

# ===== INSTALL PLASMA DESKTOP THEME =====
echo -e "\n${WHITE}Installing Plasma desktop theme metadata...${RESET}"

cp "$SCRIPT_DIR/plasma/desktoptheme/HelloKittyY2K/metadata.json" \
   "$HOME/.local/share/plasma/desktoptheme/HelloKittyY2K/"

success "Plasma theme metadata installed"

# ===== INSTALL SDDM THEME (requires sudo) =====
echo -e "\n${WHITE}Installing SDDM login theme...${RESET}"

SDDM_DIR="/usr/share/sddm/themes/HelloKittyY2K"
if [ -d "/usr/share/sddm/themes" ]; then
    read -p "  Install SDDM theme? (requires sudo) [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        sudo mkdir -p "$SDDM_DIR"
        sudo cp "$SCRIPT_DIR/sddm/HelloKittyY2K/Main.qml" "$SDDM_DIR/"
        sudo cp "$SCRIPT_DIR/sddm/HelloKittyY2K/theme.conf" "$SDDM_DIR/"
        sudo cp "$SCRIPT_DIR/sddm/HelloKittyY2K/metadata.desktop" "$SDDM_DIR/"

        # Set SDDM theme in config
        sudo mkdir -p /etc/sddm.conf.d
        sudo tee /etc/sddm.conf.d/hellokitty.conf > /dev/null << 'EOF'
[Theme]
Current=HelloKittyY2K
EOF
        success "SDDM theme installed and activated"
    else
        warn "Skipped SDDM theme installation"
    fi
else
    warn "SDDM themes directory not found. Is SDDM installed?"
fi

# ===== APPLY PLASMA SETTINGS =====
echo -e "\n${WHITE}Applying Plasma settings...${RESET}"

chmod +x "$SCRIPT_DIR/scripts/plasma-settings.sh"
bash "$SCRIPT_DIR/scripts/plasma-settings.sh"

# ===== DONE =====
echo ""
echo -e "${PINK}"
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║                                              ║"
echo "  ║     ♡  Installation Complete!  ♡             ║"
echo "  ║                                              ║"
echo "  ║  Next steps:                                 ║"
echo "  ║  1. Log out and back in                      ║"
echo "  ║  2. Open Kvantum Manager → select            ║"
echo "  ║     HelloKittyY2K                            ║"
echo "  ║  3. Set wallpaper in Desktop Settings        ║"
echo "  ║  4. Enjoy your Y2K rice! 🎀                  ║"
echo "  ║                                              ║"
echo "  ╚══════════════════════════════════════════════╝"
echo -e "${RESET}"
