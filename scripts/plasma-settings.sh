#!/bin/bash
# ============================================================
#  Hello Kitty Y2K — KDE Plasma Settings Applicator
#  Run after install.sh to configure Plasma settings
# ============================================================

set -euo pipefail

echo "🎀 Applying Hello Kitty Y2K Plasma settings..."

# --- Color Scheme ---
if command -v plasma-apply-colorscheme &>/dev/null; then
    plasma-apply-colorscheme HelloKittyY2K 2>/dev/null || true
    echo "  ✧ Color scheme applied"
fi

# --- Kvantum as Application Style ---
if command -v kwriteconfig6 &>/dev/null; then
    KW="kwriteconfig6"
elif command -v kwriteconfig5 &>/dev/null; then
    KW="kwriteconfig5"
else
    echo "  ⚠ kwriteconfig not found, skipping kconfig settings"
    exit 0
fi

# Application style → kvantum
$KW --file kdeglobals --group KDE --key widgetStyle kvantum
$KW --file kdeglobals --group KDE --key ColorScheme HelloKittyY2K
echo "  ✧ Widget style set to Kvantum"

# --- Window Decoration (Aurorae) ---
$KW --file kwinrc --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae
$KW --file kwinrc --group org.kde.kdecoration2 --key theme __aurorae__svg__HelloKittyY2K
echo "  ✧ Window decoration set to Aurorae/HelloKittyY2K"

# --- Window border size ---
$KW --file kwinrc --group org.kde.kdecoration2 --key BorderSize Normal

# --- Titlebar buttons (keep close/max/min on right) ---
$KW --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft ""
$KW --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight "IAX"

# --- Desktop Effects (for that glossy feel) ---
$KW --file kwinrc --group Plugins --key blurEnabled true
$KW --file kwinrc --group Plugins --key contrastEnabled true
$KW --file kwinrc --group Plugins --key slidingpopupsEnabled true
$KW --file kwinrc --group Plugins --key fadeEnabled true
$KW --file kwinrc --group Plugins --key loginEnabled true

# --- Blur settings ---
$KW --file kwinrc --group Effect-Blur --key BlurStrength 8
$KW --file kwinrc --group Effect-Blur --key NoiseStrength 4

# --- Panel opacity ---
$KW --file plasmashellrc --group PlasmaViews --group Panel\ 2 --key panelOpacity 0.85

# --- Wallpaper (set via script - user may need to set manually) ---
echo "  ℹ Wallpaper: Set manually in Desktop Settings → Wallpaper"
echo "    Use: ~/.local/share/wallpapers/hellokitty-y2k.svg"

# --- Konsole profile ---
if [ -d "$HOME/.local/share/konsole" ]; then
    # Create a default profile pointing to our colorscheme
    cat > "$HOME/.local/share/konsole/HelloKittyY2K.profile" << 'PROFILE'
[Appearance]
ColorScheme=HelloKittyY2K
Font=Hack,11,-1,5,50,0,0,0,0,0

[General]
Name=Hello Kitty Y2K
Parent=FALLBACK/
TerminalCenter=true
TerminalMargin=8

[Scrolling]
HistoryMode=2
ScrollBarPosition=2
PROFILE
    echo "  ✧ Konsole profile created"

    # Set as default
    $KW --file konsolerc --group "Desktop Entry" --key DefaultProfile HelloKittyY2K.profile
    echo "  ✧ Konsole default profile set"
fi

# --- Cursor (suggest installing a pink cursor theme) ---
echo ""
echo "  💡 TIP: For a matching cursor, install a pink cursor theme:"
echo "     yay -S xcursor-pinknblack"
echo "     Then set in System Settings → Cursors"

# --- Fonts (suggest bubbly/rounded fonts for 2000s look) ---
echo ""
echo "  💡 TIP: For the full 2000s look, install rounded fonts:"
echo "     sudo pacman -S ttf-comfortaa"
echo "     Or: yay -S ttf-quicksand"
echo "     Then set in System Settings → Fonts"

# --- Reload KWin ---
if command -v qdbus6 &>/dev/null; then
    qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
elif command -v qdbus &>/dev/null; then
    qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
fi

echo ""
echo "🎀 Done! Log out and back in for all changes to take full effect."
echo "   Open Kvantum Manager and select 'HelloKittyY2K' to complete the look."
