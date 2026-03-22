#!/usr/bin/env bash
set -euo pipefail

# ── Configuration ──────────────────────────────────────────────────
THEME_DIR="$HOME/.local/share/icons/HelloKittyY2K"
ASSET_DIR="pinkHelloKitty"  # adjust if your .ico files live elsewhere

# ── Helper: extract the LARGEST frame from an .ico ─────────────────
# ICO files contain multiple resolutions (16, 32, 48, 64, 128, 256…).
# [0] is the smallest. We want the biggest.
extract_best() {
    local ico="$1"
    local out="$2"
    local target_size="$3"  # e.g. 256 or 128

    # List all frames and their dimensions, pick the largest
    local best_index=0
    local best_width=0

    while IFS=' ' read -r idx dims; do
        w="${dims%%x*}"
        if (( w > best_width )); then
            best_width=$w
            best_index=$idx
        fi
    done < <(magick identify -format '%p %wx%h\n' "$ico" 2>/dev/null)

    echo "  → $ico: using frame [$best_index] (${best_width}px) → ${target_size}x${target_size}"

    # Extract the best frame and resize to target
    # Use -filter Lanczos for clean downscaling (or minimal upscaling)
    magick "${ico}[${best_index}]" -filter Lanczos -resize "${target_size}x${target_size}" \
        -background none -gravity center -extent "${target_size}x${target_size}" \
        "$out"
}

# ── 1. Clean slate ────────────────────────────────────────────────
echo "=== Rebuilding HelloKittyY2K icon theme ==="
rm -rf "$THEME_DIR/128x128" "$THEME_DIR/256x256"
mkdir -p "$THEME_DIR"/{256x256,128x128}/{places,apps,mimetypes}
mkdir -p "$THEME_DIR/scalable/apps"  # keep existing SVGs

# ── 2. Write corrected index.theme ────────────────────────────────
# Key changes:
#   - Added 256x256 directories (places, apps, mimetypes)
#   - Scalable SVGs cover 16–512 for the start menu icon
cat > "$THEME_DIR/index.theme" << 'EOF'
[Icon Theme]
Name=HelloKittyY2K
Comment=Y2K Hello Kitty Icon Theme with Oxygen Fallback
Inherits=oxygen,breeze,hicolor
Directories=scalable/apps,256x256/places,256x256/apps,256x256/mimetypes,128x128/places,128x128/apps,128x128/mimetypes

[scalable/apps]
Size=128
MinSize=16
MaxSize=512
Context=Applications
Type=Scalable

[256x256/places]
Size=256
MinSize=129
MaxSize=512
Context=Places
Type=Scalable

[256x256/apps]
Size=256
MinSize=129
MaxSize=512
Context=Applications
Type=Scalable

[256x256/mimetypes]
Size=256
MinSize=129
MaxSize=512
Context=MimeTypes
Type=Scalable

[128x128/places]
Size=128
MinSize=32
MaxSize=128
Context=Places
Type=Scalable

[128x128/apps]
Size=128
MinSize=32
MaxSize=128
Context=Applications
Type=Scalable

[128x128/mimetypes]
Size=128
MinSize=32
MaxSize=128
Context=MimeTypes
Type=Scalable
EOF

# ── 3. Extract icons at BOTH 256 and 128 from the best ICO frame ──
cd "$ASSET_DIR"

echo ""
echo "--- Places ---"

# Folders
for size in 256 128; do
    d="$THEME_DIR/${size}x${size}/places"
    extract_best "Folder.ico"     "$d/folder.png"          "$size"
    extract_best "Desktop.ico"    "$d/user-desktop.png"    "$size"
    extract_best "TrashEmpty.ico" "$d/user-trash.png"      "$size"
    extract_best "TrashFull.ico"  "$d/user-trash-full.png" "$size"

    # Symlinks
    ln -sf folder.png "$d/inode-directory.png"
    ln -sf folder.png "$d/user-home.png"
done

echo ""
echo "--- Mimetypes ---"
for size in 256 128; do
    d="$THEME_DIR/${size}x${size}/mimetypes"
    ln -sf ../places/folder.png "$d/inode-directory.png" 2>/dev/null || \
        cp "$THEME_DIR/${size}x${size}/places/folder.png" "$d/inode-directory.png"
done

echo ""
echo "--- Apps ---"
for size in 256 128; do
    d="$THEME_DIR/${size}x${size}/apps"

    # System Settings
    extract_best "Setting.ico"         "$d/systemsettings.png"        "$size"
    ln -sf systemsettings.png "$d/preferences-system.png"
    ln -sf systemsettings.png "$d/org.kde.systemsettings.png"

    # Dolphin / File Manager
    extract_best "Explorer.ico"        "$d/system-file-manager.png"   "$size"
    ln -sf system-file-manager.png "$d/org.kde.dolphin.png"
    ln -sf system-file-manager.png "$d/dolphin.png"

    # Web Browser / Vivaldi
    extract_best "InternetExpiorer.ico" "$d/internet-web-browser.png" "$size"
    ln -sf internet-web-browser.png "$d/vivaldi.png"
done

cd ..

# ── 4. Fix mimetypes symlinks (relative paths) ────────────────────
# The cross-directory symlink above may not work; copy instead
for size in 256 128; do
    src="$THEME_DIR/${size}x${size}/places/folder.png"
    dst="$THEME_DIR/${size}x${size}/mimetypes/inode-directory.png"
    if [ -f "$src" ] && [ ! -f "$dst" ]; then
        cp "$src" "$dst"
    fi
done

# ── 5. Verify what we built ───────────────────────────────────────
echo ""
echo "=== Final structure ==="
find "$THEME_DIR" -type f -name "*.png" -exec sh -c \
    'echo "$(identify -format "%wx%h" "$1" 2>/dev/null || echo "???") $1"' _ {} \;

echo ""
echo "=== Symlinks ==="
find "$THEME_DIR" -type l -exec ls -la {} \;

# ── 6. Nuke caches ───────────────────────────────────────────────
echo ""
echo "=== Clearing caches ==="
gtk-update-icon-cache -f -t "$THEME_DIR" 2>/dev/null || true
rm -f ~/.cache/icon-cache.kcache ~/.cache/icon-cache-*
rm -rf ~/.cache/plasma-svgelements-*
rm -rf ~/.cache/plasma_theme_*
kbuildsycoca6 --noincremental 2>/dev/null || true

# ── 7. Restart plasma ────────────────────────────────────────────
echo ""
echo "=== Restarting Plasma ==="
killall dolphin 2>/dev/null || true
kquitapp6 plasmashell 2>/dev/null || killall plasmashell 2>/dev/null || true
sleep 1
kstart plasmashell &

echo ""
echo "✅ Done! Icons rebuilt from highest-resolution ICO frames."
echo "   If Dolphin shows 256px icons, they'll now be crisp."
