#!/bin/bash
# ============================================================
#  🎀  Hello Kitty Y2K — Uninstaller
# ============================================================

set -euo pipefail

PINK='\033[38;5;213m'
RESET='\033[0m'

echo -e "${PINK}Removing Hello Kitty Y2K theme...${RESET}"

# Kvantum
rm -rf "$HOME/.config/Kvantum/HelloKittyY2K"
sed -i 's/theme=HelloKittyY2K/theme=/' "$HOME/.config/Kvantum/kvantum.kvconfig" 2>/dev/null || true
echo "  ✧ Kvantum theme removed"

# Aurorae
rm -rf "$HOME/.local/share/aurorae/themes/HelloKittyY2K"
echo "  ✧ Aurorae decoration removed"

# Color scheme
rm -f "$HOME/.local/share/color-schemes/HelloKittyY2K.colors"
echo "  ✧ Color scheme removed"

# Konsole
rm -f "$HOME/.local/share/konsole/HelloKittyY2K.colorscheme"
rm -f "$HOME/.local/share/konsole/HelloKittyY2K.profile"
echo "  ✧ Konsole colorscheme removed"

# Kitty
if [ -f "$HOME/.config/kitty/kitty.conf.bak" ]; then
    mv "$HOME/.config/kitty/kitty.conf.bak" "$HOME/.config/kitty/kitty.conf"
    echo "  ✧ Kitty config restored from backup"
else
    echo "  ℹ No kitty backup found — remove ~/.config/kitty/kitty.conf manually if needed"
fi

# Wallpaper
rm -f "$HOME/.local/share/wallpapers/hellokitty-y2k.svg"
echo "  ✧ Wallpaper removed"

# Plasma theme
rm -rf "$HOME/.local/share/plasma/desktoptheme/HelloKittyY2K"
echo "  ✧ Plasma theme removed"

# SDDM (requires sudo)
if [ -d "/usr/share/sddm/themes/HelloKittyY2K" ]; then
    read -p "  Remove SDDM theme? (requires sudo) [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        sudo rm -rf "/usr/share/sddm/themes/HelloKittyY2K"
        sudo rm -f "/etc/sddm.conf.d/hellokitty.conf"
        echo "  ✧ SDDM theme removed"
    fi
fi

echo ""
echo -e "${PINK}♡ Uninstall complete. Log out and back in to reset.${RESET}"
echo "  You may want to select a different theme in System Settings."
