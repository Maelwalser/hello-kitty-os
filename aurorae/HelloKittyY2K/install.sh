#!/bin/bash
set -e

THEME_DIR="$HOME/.local/share/aurorae/themes/HelloKittyY2K"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "╔══════════════════════════════════════╗"
echo "║  Hello Kitty Y2K - v3 Installer      ║"
echo "╚══════════════════════════════════════╝"

# Remove old version
if [ -d "$THEME_DIR" ]; then
    echo "[1/4] Removing old installation..."
    rm -rf "$THEME_DIR"
fi

# Install
echo "[2/4] Installing theme..."
mkdir -p "$THEME_DIR"
for f in metadata.desktop HelloKittyY2Krc decoration.svg \
         close.svg minimize.svg maximize.svg restore.svg \
         alldesktops.svg keepabove.svg keepbelow.svg shade.svg; do
    if [ -f "$SCRIPT_DIR/$f" ]; then
        cp "$SCRIPT_DIR/$f" "$THEME_DIR/$f"
        echo "  ✓ $f"
    fi
done

# Nuke ALL caches - this is critical
echo "[3/4] Clearing all Plasma/KSvg caches..."
rm -rf ~/.cache/plasma* 2>/dev/null || true
rm -rf ~/.cache/ksvg* 2>/dev/null || true
rm -rf ~/.cache/kwin* 2>/dev/null || true
rm -rf ~/.cache/aurorae* 2>/dev/null || true
find ~/.cache -maxdepth 2 -name "*.kcache" -delete 2>/dev/null || true
find ~/.cache -maxdepth 2 -name "*svg*" -delete 2>/dev/null || true

echo "[4/4] Verifying installation..."
echo ""
echo "Installed files:"
ls -la "$THEME_DIR/"
echo ""
echo "Element IDs in decoration.svg:"
grep -oP 'id="[^"]*"' "$THEME_DIR/decoration.svg" | sort
echo ""
echo "Element IDs in close.svg:"
grep -oP 'id="[^"]*"' "$THEME_DIR/close.svg" | sort
echo ""

echo "═══════════════════════════════════════"
echo "NEXT STEPS:"
echo ""
echo "1. Restart KWin (REQUIRED):"
echo "   • Wayland: kwin_wayland --replace &"
echo "   • X11:     kwin_x11 --replace &"
echo ""
echo "2. Go to: System Settings → Window Management"
echo "          → Window Decorations"
echo ""
echo "3. Select 'Hello Kitty Y2K'"
echo ""
echo "4. IMPORTANT: Set 'Window border size' to 'Normal'"
echo "   (not 'No Borders' or 'No Side Borders')"
echo ""
echo "5. Click Apply"
echo "═══════════════════════════════════════"
