#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="$HOME/.local/share/icons/HelloKittyY2K"

echo "╔═════════════════════════════════════════╗"
echo "║  Hello Kitty Y2K Cursor Theme Builder    ║"
echo "╚═════════════════════════════════════════╝"
echo ""

# Check for source cursors
if [ -z "$1" ]; then
    echo "Usage: $0 <folder_with_cur_ani_files>"
    echo ""
    echo "Example:"
    echo "  $0 ~/Downloads/hello-kitty-cursors/"
    echo ""
    echo "The folder should contain these files:"
    echo "  Hello Kitty normal select.cur"
    echo "  Hello Kitty busy.ani"
    echo "  Hello Kitty link select.ani"
    echo "  ... etc."
    echo ""
    echo "Files can have number prefixes like '021   Hello Kitty normal select.cur'"
    exit 1
fi

SOURCE_DIR="$1"

if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Directory not found: $SOURCE_DIR"
    exit 1
fi

# Make sure Oxygen White cursors are available as fallback
if [ ! -d "/usr/share/icons/oxy-white" ] && \
   [ ! -d "$HOME/.local/share/icons/oxy-white" ] && \
   [ ! -d "/usr/share/icons/Oxygen_White" ]; then
    echo "⚠ Oxygen White cursors not found!"
    echo "  Install them for fallback cursors:"
    echo "    sudo pacman -S oxygen-cursors"
    echo ""
    echo "  Continuing anyway (missing cursors will use system default)..."
    echo ""
fi

# Remove old theme
if [ -d "$OUTPUT_DIR" ]; then
    echo "Removing old cursor theme..."
    rm -rf "$OUTPUT_DIR"
fi

# Build the theme
python3 "$SCRIPT_DIR/build_cursor_theme.py" "$SOURCE_DIR" "$OUTPUT_DIR"

echo ""
echo "Clearing cursor caches..."
rm -rf ~/.cache/cursors* 2>/dev/null || true

echo ""
echo "Theme installed to: $OUTPUT_DIR"
echo ""
echo "═══════════════════════════════════════════"
echo "NEXT STEPS:"
echo ""
echo "1. Install Oxygen White fallback cursors (if not already):"
echo "     sudo pacman -S oxygen-cursors"
echo ""
echo "2. Apply the cursor theme:"
echo "     System Settings → Appearance → Cursors"
echo "     → Select 'Hello Kitty Y2K' → Apply"
echo ""
echo "   OR apply via command line:"
echo "     plasma-apply-cursortheme HelloKittyY2K"
echo "═══════════════════════════════════════════"
