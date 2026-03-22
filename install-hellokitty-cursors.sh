#!/bin/bash
set -e

SRC="${1:-$HOME/Downloads/hellokitty-dotfiles/hello-kitty-cursors}"

if [ ! -d "$SRC" ]; then
    echo "Error: Directory not found: $SRC"
    echo "Usage: $0 [path/to/hello-kitty-cursors/]"
    exit 1
fi

for cmd in xcursorgen icotool python3; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Missing: $cmd — sudo pacman -S icoutils xorg-xcursorgen python-pillow"
        exit 1
    fi
done

THEME_DIR="$HOME/.local/share/icons/HelloKittyY2K_Cursors"
rm -rf "$THEME_DIR"
mkdir -p "$THEME_DIR/cursors"

cat > "$THEME_DIR/index.theme" << 'EOF'
[Icon Theme]
Name=Hello Kitty Y2K
Comment=Full Hello Kitty Cursor Set
Inherits=Oxygen_White,oxygen,hicolor
EOF

WORK=$(mktemp -d)
trap "rm -rf $WORK" EXIT

# ═══════════════════════════════════════════════════════════════════════════════
# Alpha cleanup function — kills any lingering black background pixels
# ═══════════════════════════════════════════════════════════════════════════════

fix_alpha() {
    local png="$1"
    python3 - "$png" << 'PYEOF'
import sys
from PIL import Image

img = Image.open(sys.argv[1]).convert("RGBA")
w, h = img.size
changed = 0
for y in range(h):
    for x in range(w):
        r, g, b, a = img.getpixel((x, y))
        if a == 0:
            img.putpixel((x, y), (0, 0, 0, 0))
            changed += 1
        elif a < 10 and r < 10 and g < 10 and b < 10:
            img.putpixel((x, y), (0, 0, 0, 0))
            changed += 1
img.save(sys.argv[1])
PYEOF
}

# ═══════════════════════════════════════════════════════════════════════════════
# Static .cur conversion — uses icotool (handles alpha correctly for statics)
# ═══════════════════════════════════════════════════════════════════════════════

convert_cur() {
    local src="$1"
    local dest="$2"

    if [ ! -f "$SRC/$src" ]; then
        echo "  ⚠ NOT FOUND: $src"
        return 1
    fi

    rm -f "$WORK"/temp*.png

    # icotool extracts the best resolution PNG with correct alpha
    icotool -x "$SRC/$src" -o "$WORK/temp.png" 2>/dev/null

    # Pick the largest extracted file
    local best=""
    local best_size=0
    for f in "$WORK"/temp*.png; do
        [ -f "$f" ] || continue
        local sz
        sz=$(stat -c%s "$f" 2>/dev/null || echo 0)
        if [ "$sz" -gt "$best_size" ]; then
            best="$f"
            best_size="$sz"
        fi
    done

    if [ -z "$best" ] || [ ! -f "$best" ]; then
        echo "  ⚠ EXTRACT FAILED (icotool): $src"
        return 1
    fi

    # Safety: clean up any alpha issues
    fix_alpha "$best"

    echo "32 0 0 $best" > "$WORK/cursor.cfg"
    xcursorgen "$WORK/cursor.cfg" "$THEME_DIR/cursors/$dest"
    rm -f "$WORK"/temp*.png "$WORK"/cursor.cfg
    echo "  ✓ $src → $dest"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Animated .ani conversion — manual AND mask parsing to fix black backgrounds
# ═══════════════════════════════════════════════════════════════════════════════

convert_ani() {
    local src="$1"
    local dest="$2"
    local delay="${3:-80}"

    if [ ! -f "$SRC/$src" ]; then
        echo "  ⚠ NOT FOUND: $src"
        return 1
    fi

    rm -rf "$WORK/frames"
    mkdir -p "$WORK/frames"

    local nframes
    nframes=$(python3 - "$SRC/$src" "$WORK/frames" << 'PYEOF'
import struct, sys, os, tempfile, subprocess
from PIL import Image
from io import BytesIO

ani_path = sys.argv[1]
out_dir = sys.argv[2]
data = open(ani_path, "rb").read()

if data[:4] != b'RIFF' or data[8:12] != b'ACON':
    print("0")
    sys.exit(0)

# ── Collect raw icon frames from RIFF LIST/fram ──
frames_raw = []
pos = 12
while pos < len(data) - 8:
    cid = data[pos:pos+4]
    csz = struct.unpack_from('<I', data, pos+4)[0]
    if cid == b'LIST' and pos+12 <= len(data) and data[pos+8:pos+12] == b'fram':
        inner = pos + 12
        end = pos + 8 + csz
        while inner < end - 8:
            iid = data[inner:inner+4]
            isz = struct.unpack_from('<I', data, inner+4)[0]
            if iid == b'icon':
                frames_raw.append(data[inner+8:inner+8+isz])
            inner += 8 + isz + (isz % 2)
    pos += 8 + csz + (csz % 2)

if not frames_raw:
    print("0")
    sys.exit(0)

count = 0
for i, raw in enumerate(frames_raw):
    png_path = os.path.join(out_dir, f"frame{count:04d}.png")
    saved = False

    # ── Method 1: icotool on the raw frame ──
    # Save raw frame as temp .cur, run icotool, clean alpha
    try:
        with tempfile.NamedTemporaryFile(suffix='.cur', delete=False) as tf:
            tf.write(raw)
            tmp_cur = tf.name
        
        tmp_png = tmp_cur.replace('.cur', '.png')
        ret = subprocess.run(['icotool', '-x', tmp_cur, '-o', tmp_png],
                             capture_output=True, timeout=5)
        
        # icotool might create multiple files
        candidates = [tmp_png]
        base = tmp_png.replace('.png', '')
        for sfx in ['-1.png', '-2.png', '-3.png', '-4.png', '-5.png']:
            c = base + sfx
            if os.path.exists(c):
                candidates.append(c)
        
        best = None
        best_sz = 0
        for c in candidates:
            if os.path.exists(c):
                sz = os.path.getsize(c)
                if sz > best_sz:
                    best = c
                    best_sz = sz
        
        if best and best_sz > 0:
            img = Image.open(best).convert('RGBA')
            saved = True
        
        # Clean up temp files
        for c in [tmp_cur] + candidates:
            if os.path.exists(c):
                os.remove(c)
    except Exception:
        pass

    # ── Method 2: PIL direct open ──
    if not saved:
        try:
            img = Image.open(BytesIO(raw)).convert('RGBA')
            saved = True
        except Exception:
            pass

    # ── Method 3: Manual DIB + AND mask parse ──
    if not saved:
        try:
            if len(raw) < 22:
                continue
            reserved, itype, nimg = struct.unpack_from('<HHH', raw, 0)
            if nimg < 1:
                continue
            
            (wb, hb, cc, res, hx, hy, dsz, doff) = struct.unpack_from('<BBBBHHIH', raw, 6)
            aw = wb if wb else 256
            ah = hb if hb else 256
            idata = raw[doff:doff+dsz]
            
            if len(idata) < 40:
                continue
            
            hs = struct.unpack_from('<I', idata, 0)[0]
            bw, bh, planes, bpp = struct.unpack_from('<iiHH', idata, 4)
            aw = bw if bw > 0 else aw
            ah = abs(bh) // 2 if abs(bh) > ah else ah
            
            if bpp == 32 and hs >= 40:
                xor_off = hs
                xor_rb = ((aw * 32 + 31) // 32) * 4
                and_off = xor_off + xor_rb * ah
                and_rb = ((aw + 31) // 32) * 4
                
                img = Image.new('RGBA', (aw, ah))
                for y in range(ah):
                    sy = ah - 1 - y
                    for x in range(aw):
                        px = xor_off + sy * xor_rb + x * 4
                        if px + 4 <= len(idata):
                            b, g, r, a = struct.unpack_from('BBBB', idata, px)
                            img.putpixel((x, y), (r, g, b, a))
                
                # Apply AND mask
                for y in range(ah):
                    sy = ah - 1 - y
                    for x in range(aw):
                        mo = and_off + sy * and_rb + (x // 8)
                        if mo < len(idata):
                            bit = (idata[mo] >> (7 - (x % 8))) & 1
                            if bit == 1:
                                img.putpixel((x, y), (0, 0, 0, 0))
                saved = True
        except Exception:
            pass

    if not saved:
        continue

    # ── Apply AND mask cleanup to ALL methods ──
    # Even icotool/PIL results may have black bg on certain frames
    # Force transparent any pixel that is black with low-ish alpha
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = img.getpixel((x, y))
            if a == 0:
                img.putpixel((x, y), (0, 0, 0, 0))
            elif a < 10 and r < 10 and g < 10 and b < 10:
                img.putpixel((x, y), (0, 0, 0, 0))

    # ── If icotool/PIL was used, also try applying AND mask from raw data ──
    # This is the critical fix: even if PIL read the image fine, it may have
    # ignored the AND mask, leaving black pixels with alpha=255
    try:
        if len(raw) >= 22:
            reserved, itype, nimg = struct.unpack_from('<HHH', raw, 0)
            if nimg >= 1:
                (wb, hb, cc, res, hx, hy, dsz, doff) = struct.unpack_from('<BBBBHHIH', raw, 6)
                aw2 = wb if wb else 256
                ah2 = hb if hb else 256
                idata = raw[doff:doff+dsz]
                
                if len(idata) >= 40:
                    hs = struct.unpack_from('<I', idata, 0)[0]
                    bw, bh, planes, bpp = struct.unpack_from('<iiHH', idata, 4)
                    aw2 = bw if bw > 0 else aw2
                    ah2 = abs(bh) // 2 if abs(bh) > ah2 else ah2
                    
                    if bpp in (24, 32) and hs >= 40:
                        xor_rb = ((aw2 * bpp + 31) // 32) * 4
                        and_off = hs + xor_rb * ah2
                        and_rb = ((aw2 + 31) // 32) * 4
                        
                        # Scale factor if image was resized
                        sx = img.size[0] / aw2 if aw2 > 0 else 1
                        sy2 = img.size[1] / ah2 if ah2 > 0 else 1
                        
                        for my in range(ah2):
                            src_y = ah2 - 1 - my
                            for mx in range(aw2):
                                mo = and_off + src_y * and_rb + (mx // 8)
                                if mo < len(idata):
                                    bit = (idata[mo] >> (7 - (mx % 8))) & 1
                                    if bit == 1:
                                        # Map back to image coords
                                        ix = int(mx * sx)
                                        iy = int(my * sy2)
                                        if 0 <= ix < img.size[0] and 0 <= iy < img.size[1]:
                                            img.putpixel((ix, iy), (0, 0, 0, 0))
    except Exception:
        pass

    if img.size != (32, 32):
        img = img.resize((32, 32), Image.LANCZOS)
    
    img.save(png_path, 'PNG')
    count += 1

print(count)
PYEOF
    )

    if [ "$nframes" -eq 0 ] || [ -z "$nframes" ]; then
        echo "  ⚠ NO FRAMES from ANI: $src — trying as static"
        convert_cur "$src" "$dest"
        return $?
    fi

    > "$WORK/ani_cursor.cfg"
    for f in "$WORK"/frames/frame*.png; do
        [ -f "$f" ] || continue
        echo "32 0 0 $f $delay" >> "$WORK/ani_cursor.cfg"
    done

    xcursorgen "$WORK/ani_cursor.cfg" "$THEME_DIR/cursors/$dest"
    rm -rf "$WORK/frames" "$WORK/ani_cursor.cfg"
    echo "  ✓ $src → $dest ($nframes frames, ${delay}ms)"
}

# ═══════════════════════════════════════════════════════════════════════════════
echo "╔═════════════════════════════════════════╗"
echo "║  Hello Kitty Y2K Cursor Theme Builder    ║"
echo "╚═════════════════════════════════════════╝"
echo ""
echo "Source: $SRC"
echo "Output: $THEME_DIR"
echo ""
echo "Converting cursors..."

convert_cur "Hello Kitty normal select.cur"         "left_ptr"
convert_cur "Hello Kitty help select.cur"            "help"
convert_ani "Hello Kitty working in background.ani"  "left_ptr_watch" 80
convert_ani "Hello Kitty busy.ani"                   "watch"          80
convert_cur "Hello Kitty precision select.cur"       "crosshair"
convert_cur "Hello Kitty text select.cur"            "xterm"
convert_cur "Hello Kitty handwriting.cur"            "pencil"
convert_cur "Hello Kitty unavailable.cur"            "crossed_circle"
convert_cur "Hello Kitty vertical resize.cur"        "sb_v_double_arrow"
convert_cur "Hello Kitty horizontal resize.cur"      "sb_h_double_arrow"
convert_cur "Hello Kitty diagonal resize 1.cur"      "fd_double_arrow"
convert_cur "Hello Kitty diagonal resize 2.cur"      "bd_double_arrow"
convert_cur "Hello Kitty move.cur"                   "fleur"
convert_cur "Hello Kitty alternate select.cur"       "right_ptr"
convert_ani "Hello Kitty link select.ani"            "hand2"          80

# ═══════════════════════════════════════════════════════════════════════════════
echo ""
echo "Creating symlinks..."
cd "$THEME_DIR/cursors"

# ── left_ptr ──
ln -sf left_ptr      default
ln -sf left_ptr      arrow
ln -sf left_ptr      top_left_arrow
ln -sf left_ptr      pick
ln -sf left_ptr      left-arrow
ln -sf left_ptr      x-cursor
ln -sf left_ptr      X_cursor
ln -sf left_ptr      center_ptr
ln -sf left_ptr      pirate
ln -sf left_ptr      ul_angle
ln -sf left_ptr      ur_angle
ln -sf left_ptr      ll_angle
ln -sf left_ptr      lr_angle
# ── help ──
ln -sf help          question_arrow
ln -sf help          whats_this
ln -sf help          dnd-ask
ln -sf help          d9ce0ab605698f320427677b458ad60b
ln -sf help          5c6cd98b3f3ebcb1f9c7f1c204630408
# ── left_ptr_watch ──
ln -sf left_ptr_watch  progress
ln -sf left_ptr_watch  half-busy
ln -sf left_ptr_watch  08e8e1c95fe2fc01f976f1e063a24ccd
ln -sf left_ptr_watch  3ecb610c1bf2410f44200f48c40d3599
# ── watch ──
ln -sf watch         wait
# ── crosshair ──
ln -sf crosshair     cross
ln -sf crosshair     tcross
ln -sf crosshair     cross_reverse
ln -sf crosshair     diamond_cross
ln -sf crosshair     target
ln -sf crosshair     dotbox
ln -sf crosshair     dot_box_mask
ln -sf crosshair     draped_box
ln -sf crosshair     icon
ln -sf crosshair     plus
ln -sf crosshair     zoom-in
ln -sf crosshair     zoom-out
# ── xterm ──
ln -sf xterm         text
ln -sf xterm         ibeam
ln -sf xterm         vertical-text
# ── pencil ──
ln -sf pencil        draft
# ── crossed_circle ──
ln -sf crossed_circle  not-allowed
ln -sf crossed_circle  forbidden
ln -sf crossed_circle  no-drop
ln -sf crossed_circle  dnd-no-drop
ln -sf crossed_circle  circle
ln -sf crossed_circle  03b6e0fcb3499374a867c041f52298f0
# ── sb_v_double_arrow ──
ln -sf sb_v_double_arrow  v_double_arrow
ln -sf sb_v_double_arrow  ns-resize
ln -sf sb_v_double_arrow  n-resize
ln -sf sb_v_double_arrow  s-resize
ln -sf sb_v_double_arrow  size_ver
ln -sf sb_v_double_arrow  top_side
ln -sf sb_v_double_arrow  bottom_side
ln -sf sb_v_double_arrow  row-resize
ln -sf sb_v_double_arrow  split_v
ln -sf sb_v_double_arrow  based_arrow_up
ln -sf sb_v_double_arrow  based_arrow_down
ln -sf sb_v_double_arrow  sb_up_arrow
ln -sf sb_v_double_arrow  sb_down_arrow
ln -sf sb_v_double_arrow  double_arrow
ln -sf sb_v_double_arrow  00008160000006810000408080010102
ln -sf sb_v_double_arrow  2870a09082c103050810ffdffffe0204
# ── sb_h_double_arrow ──
ln -sf sb_h_double_arrow  h_double_arrow
ln -sf sb_h_double_arrow  ew-resize
ln -sf sb_h_double_arrow  e-resize
ln -sf sb_h_double_arrow  w-resize
ln -sf sb_h_double_arrow  size_hor
ln -sf sb_h_double_arrow  left_side
ln -sf sb_h_double_arrow  right_side
ln -sf sb_h_double_arrow  col-resize
ln -sf sb_h_double_arrow  split_h
ln -sf sb_h_double_arrow  sb_left_arrow
ln -sf sb_h_double_arrow  sb_right_arrow
ln -sf sb_h_double_arrow  028006030e0e7ebffc7f7070c0600140
ln -sf sb_h_double_arrow  14fef782d02440884392942c11205230
# ── fd_double_arrow ──
ln -sf fd_double_arrow  nwse-resize
ln -sf fd_double_arrow  nw-resize
ln -sf fd_double_arrow  se-resize
ln -sf fd_double_arrow  size_fdiag
ln -sf fd_double_arrow  top_left_corner
ln -sf fd_double_arrow  bottom_right_corner
ln -sf fd_double_arrow  c7088f0f3e6c8088236ef8e1e3e70000
# ── bd_double_arrow ──
ln -sf bd_double_arrow  nesw-resize
ln -sf bd_double_arrow  ne-resize
ln -sf bd_double_arrow  sw-resize
ln -sf bd_double_arrow  size_bdiag
ln -sf bd_double_arrow  top_right_corner
ln -sf bd_double_arrow  bottom_left_corner
ln -sf bd_double_arrow  fcf1c3c7cd4491d801f1e1c78f100000
# ── fleur ──
ln -sf fleur         move
ln -sf fleur         all-scroll
ln -sf fleur         size_all
ln -sf fleur         grabbing
ln -sf fleur         closedhand
ln -sf fleur         dnd-move
ln -sf fleur         dnd-none
ln -sf fleur         grab
ln -sf fleur         openhand
ln -sf fleur         4498f0e0c1937ffe01fd06f973665830
ln -sf fleur         9081237383d90e509aa00f00170e968f
ln -sf fleur         fcf21c00b30f7e3f83fe0dfd12e71cff
# ── right_ptr ──
ln -sf right_ptr     context-menu
ln -sf right_ptr     alternate
ln -sf right_ptr     right-arrow
# ── hand2 ──
ln -sf hand2         pointer
ln -sf hand2         hand
ln -sf hand2         hand1
ln -sf hand2         pointing_hand
ln -sf hand2         dnd-link
ln -sf hand2         dnd-copy
ln -sf hand2         alias
ln -sf hand2         copy
ln -sf hand2         link
ln -sf hand2         left_ptr_help
ln -sf hand2         dnd_no_data
ln -sf hand2         e29285e634086352946a0e7090d73106
ln -sf hand2         9d800788f1b08800ae810202380a0822
ln -sf hand2         640fb0e74195791501fd1ed57b41487f
ln -sf hand2         6407b0e94c12445c10a953fd12f63ab4
ln -sf hand2         b66166c04f8c3109214a4fbd64a50fc8

# ═══════════════════════════════════════════════════════════════════════════════
TOTAL=$(ls -1 "$THEME_DIR/cursors" | wc -l)
REAL=$(find "$THEME_DIR/cursors" -maxdepth 1 -type f | wc -l)
LINKS=$(find "$THEME_DIR/cursors" -maxdepth 1 -type l | wc -l)

echo ""
echo "═══════════════════════════════════════════"
echo "  ✓ $REAL cursors + $LINKS symlinks = $TOTAL total entries"
echo ""
echo "  Apply with:"
echo "    System Settings → Appearance → Cursors"
echo "    → Select 'Hello Kitty Y2K' → Apply"
echo ""
echo "  Or: plasma-apply-cursortheme HelloKittyY2K_Cursors"
echo "═══════════════════════════════════════════"
