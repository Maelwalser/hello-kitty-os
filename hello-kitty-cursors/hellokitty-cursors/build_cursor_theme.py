#!/usr/bin/env python3
"""
Hello Kitty Y2K Cursor Theme Builder
Converts Windows .cur/.ani files to a Linux Xcursor theme.
Falls back to Oxygen-White for any missing cursors.
"""

import struct
import os
import sys
import shutil
from pathlib import Path
from io import BytesIO
from PIL import Image

# ─── Configuration ───────────────────────────────────────────────────────────

# Map each Hello Kitty cursor file to its X11 cursor name(s)
# First name is the primary, rest are symlinks
CURSOR_MAP = {
    "Hello Kitty normal select.cur": [
        "default", "left_ptr", "top_left_arrow", "arrow",
    ],
    "Hello Kitty help select.cur": [
        "help", "question_arrow", "whats_this", "dnd-ask",
    ],
    "Hello Kitty working in background.ani": [
        "progress", "left_ptr_watch", "half-busy",
        "08e8e1c95fe2fc01f976f1e063a24ccd",  # GTK progress hash
    ],
    "Hello Kitty busy.ani": [
        "wait", "watch",
    ],
    "Hello Kitty precision select.cur": [
        "crosshair", "cross", "tcross", "cross_reverse", "diamond_cross",
    ],
    "Hello Kitty text select.cur": [
        "text", "xterm", "ibeam",
    ],
    "Hello Kitty handwriting.cur": [
        "pencil", "draft",
    ],
    "Hello Kitty unavailable.cur": [
        "not-allowed", "forbidden", "no-drop", "crossed_circle",
        "03b6e0fcb3499374a867c041f52298f0",  # GTK no-drop hash
    ],
    "Hello Kitty vertical resize.cur": [
        "ns-resize", "n-resize", "s-resize", "size_ver",
        "sb_v_double_arrow", "top_side", "bottom_side",
        "v_double_arrow", "row-resize",
        "00008160000006810000408080010102",  # GTK ns-resize hash
    ],
    "Hello Kitty horizontal resize.cur": [
        "ew-resize", "e-resize", "w-resize", "size_hor",
        "sb_h_double_arrow", "left_side", "right_side",
        "h_double_arrow", "col-resize",
        "028006030e0e7ebffc7f7070c0600140",  # GTK ew-resize hash
    ],
    "Hello Kitty diagonal resize 1.cur": [
        "nwse-resize", "nw-resize", "se-resize", "size_fdiag",
        "top_left_corner", "bottom_right_corner",
        "fd_double_arrow",
        "c7088f0f3e6c8088236ef8e1e3e70000",  # GTK nwse hash
    ],
    "Hello Kitty diagonal resize 2.cur": [
        "nesw-resize", "ne-resize", "sw-resize", "size_bdiag",
        "top_right_corner", "bottom_left_corner",
        "bd_double_arrow",
        "fcf1c3c7cd4491d801f1e1c78f100000",  # GTK nesw hash
    ],
    "Hello Kitty move.cur": [
        "move", "fleur", "all-scroll", "grabbing",
        "closedhand", "dnd-move", "size_all",
        "4498f0e0c1937ffe01fd06f973665830",  # GTK move hash
    ],
    "Hello Kitty alternate select.cur": [
        "right_ptr", "context-menu", "alternate",
    ],
    "Hello Kitty link select.ani": [
        "pointer", "hand", "hand1", "hand2", "pointing_hand",
        "e29285e634086352946a0e7090d73106",  # GTK pointer hash
        "9d800788f1b08800ae810202380a0822",  # GTK hand2 hash
    ],
}

# ─── CUR/ICO Parser ──────────────────────────────────────────────────────────

def parse_cur_file(data):
    """
    Parse a .cur file (ICO format variant).
    Returns list of (image_pil, hotx, hoty) tuples.
    """
    reserved, img_type, num_images = struct.unpack_from('<HHH', data, 0)
    
    results = []
    for i in range(num_images):
        offset = 6 + i * 16
        (width, height, color_count, reserved2,
         hotspot_x, hotspot_y, size_bytes, file_offset) = struct.unpack_from(
            '<BBBBHHIH', data, offset
        )
        
        # Width/height 0 means 256
        w = width if width != 0 else 256
        h = height if height != 0 else 256
        
        # For .ico files, hotspot fields are planes/bpp; for .cur they're hotspot
        hotx = hotspot_x
        hoty = hotspot_y
        
        # Extract the image data
        img_data = data[file_offset:file_offset + size_bytes]
        
        # Check if it's a PNG (starts with PNG signature)
        if img_data[:4] == b'\x89PNG':
            img = Image.open(BytesIO(img_data)).convert('RGBA')
        else:
            # BMP DIB header - parse manually
            img = parse_dib_to_image(img_data, w, h)
        
        if img is not None:
            results.append((img, hotx, hoty))
    
    return results


def parse_dib_to_image(dib_data, nominal_w, nominal_h):
    """Parse a DIB (device-independent bitmap) from a CUR/ICO entry."""
    try:
        header_size = struct.unpack_from('<I', dib_data, 0)[0]
        
        if header_size >= 40:
            (bmp_w, bmp_h, planes, bpp,
             compression, img_size, xppm, yppm,
             colors_used, colors_important) = struct.unpack_from(
                '<iiHHIIiiII', dib_data, 4
            )
        else:
            return None
        
        # Height in DIB is doubled (includes AND mask)
        actual_h = abs(bmp_h) // 2
        actual_w = bmp_w if bmp_w > 0 else nominal_w
        if actual_h == 0:
            actual_h = nominal_h
        
        offset = header_size
        
        if bpp == 32:
            # 32-bit BGRA
            pixels = []
            for y in range(actual_h - 1, -1, -1):
                row = []
                for x in range(actual_w):
                    px_off = offset + (y * actual_w + x) * 4
                    if px_off + 4 <= len(dib_data):
                        b, g, r, a = struct.unpack_from('BBBB', dib_data, px_off)
                        row.append((r, g, b, a))
                    else:
                        row.append((0, 0, 0, 0))
                pixels.append(row)
            
            img = Image.new('RGBA', (actual_w, actual_h))
            for y, row in enumerate(pixels):
                for x, px in enumerate(row):
                    img.putpixel((x, y), px)
            return img
            
        elif bpp in (24, 8, 4, 1):
            # Use Pillow's ICO reader as fallback
            try:
                # Reconstruct a minimal ICO file
                ico_header = struct.pack('<HHH', 0, 2, 1)  # type=2 for CUR
                w_byte = actual_w if actual_w < 256 else 0
                h_byte = actual_h if actual_h < 256 else 0
                ico_entry = struct.pack('<BBBBHHIH',
                    w_byte, h_byte, 0, 0, 0, 0, len(dib_data), 22)
                ico_data = ico_header + ico_entry + dib_data
                img = Image.open(BytesIO(ico_data)).convert('RGBA')
                return img
            except Exception:
                return None
        else:
            return None
            
    except Exception as e:
        print(f"  Warning: DIB parse failed: {e}")
        return None


# ─── ANI Parser ───────────────────────────────────────────────────────────────

def parse_ani_file(data):
    """
    Parse a .ani (animated cursor) file.
    Returns (frames, delays_ms) where frames is list of (image, hotx, hoty)
    and delays_ms is list of per-frame delays in milliseconds.
    """
    # ANI is a RIFF file
    if data[:4] != b'RIFF':
        raise ValueError("Not a RIFF file")
    
    file_size = struct.unpack_from('<I', data, 4)[0]
    form_type = data[8:12]
    
    if form_type != b'ACON':
        raise ValueError(f"Not an ACON file, got {form_type}")
    
    frames = []
    rates = []
    num_frames = 0
    num_steps = 0
    display_rate = 60  # Default jiffies (1/60th sec)
    sequence = None
    
    pos = 12
    while pos < min(len(data), file_size + 8):
        if pos + 8 > len(data):
            break
            
        chunk_id = data[pos:pos+4]
        chunk_size = struct.unpack_from('<I', data, pos+4)[0]
        chunk_data_start = pos + 8
        
        if chunk_id == b'anih':
            # ANI header
            if chunk_size >= 36:
                (header_size, num_frames_h, num_steps_h, _, _,
                 _, _, display_rate_h, flags) = struct.unpack_from(
                    '<IIIIIIIII', data, chunk_data_start
                )
                num_frames = num_frames_h
                num_steps = num_steps_h
                display_rate = display_rate_h
                
        elif chunk_id == b'rate':
            # Per-frame display rates in jiffies
            n = chunk_size // 4
            rates = list(struct.unpack_from(f'<{n}I', data, chunk_data_start))
            
        elif chunk_id == b'seq ':
            # Frame sequence
            n = chunk_size // 4
            sequence = list(struct.unpack_from(f'<{n}I', data, chunk_data_start))
            
        elif chunk_id == b'LIST':
            list_type = data[chunk_data_start:chunk_data_start+4]
            
            if list_type == b'fram':
                # Contains 'icon' chunks, each is a complete .cur file
                inner_pos = chunk_data_start + 4
                list_end = chunk_data_start + chunk_size
                
                while inner_pos < list_end:
                    if inner_pos + 8 > len(data):
                        break
                    inner_id = data[inner_pos:inner_pos+4]
                    inner_size = struct.unpack_from('<I', data, inner_pos+4)[0]
                    
                    if inner_id == b'icon':
                        cur_data = data[inner_pos+8:inner_pos+8+inner_size]
                        try:
                            cur_frames = parse_cur_file(cur_data)
                            if cur_frames:
                                # Take the largest/best frame
                                best = max(cur_frames, key=lambda f: f[0].size[0])
                                frames.append(best)
                        except Exception as e:
                            print(f"  Warning: Failed to parse icon frame: {e}")
                    
                    inner_pos += 8 + inner_size
                    if inner_size % 2 == 1:
                        inner_pos += 1  # RIFF padding
        
        pos = chunk_data_start + chunk_size
        if chunk_size % 2 == 1:
            pos += 1  # RIFF padding
    
    # Build delay list (convert jiffies to milliseconds)
    if not rates:
        delays_ms = [int(display_rate * (1000 / 60))] * len(frames)
    else:
        delays_ms = [int(r * (1000 / 60)) for r in rates]
    
    # Apply sequence if present
    if sequence and frames:
        sequenced_frames = []
        sequenced_delays = []
        for i, idx in enumerate(sequence):
            if idx < len(frames):
                sequenced_frames.append(frames[idx])
                if i < len(delays_ms):
                    sequenced_delays.append(delays_ms[i])
                else:
                    sequenced_delays.append(delays_ms[-1])
        frames = sequenced_frames
        delays_ms = sequenced_delays
    
    # Ensure delays list matches frames
    while len(delays_ms) < len(frames):
        delays_ms.append(delays_ms[-1] if delays_ms else 100)
    
    return frames, delays_ms[:len(frames)]


# ─── Xcursor Writer ──────────────────────────────────────────────────────────

def write_xcursor(output_path, cursor_images):
    """
    Write an Xcursor file.
    cursor_images: list of (pil_image, hotx, hoty, delay_ms)
        delay_ms=0 for static cursors
    """
    XCURSOR_MAGIC = 0x72756358  # "Xcur"
    XCURSOR_IMAGE_TYPE = 0xfffd0002
    XCURSOR_HEADER_SIZE = 16
    XCURSOR_VERSION = 0x00010000
    XCURSOR_IMAGE_HEADER_SIZE = 36
    
    # Build image chunks
    chunks = []
    for img, hotx, hoty, delay in cursor_images:
        w, h = img.size
        nominal_size = w  # Use width as nominal size
        
        # Convert to ARGB pixel data (Xcursor format)
        pixels = bytearray()
        for y in range(h):
            for x in range(w):
                r, g, b, a = img.getpixel((x, y))
                # Xcursor uses premultiplied ARGB in little-endian
                if a > 0 and a < 255:
                    r = (r * a) // 255
                    g = (g * a) // 255
                    b = (b * a) // 255
                pixels.extend(struct.pack('<BBBB', b, g, r, a))
        
        chunk_header = struct.pack('<IIIIIIIII',
            XCURSOR_IMAGE_HEADER_SIZE,  # header size
            XCURSOR_IMAGE_TYPE,          # type
            nominal_size,                # subtype (nominal size)
            1,                           # version
            w,                           # width
            h,                           # height
            hotx,                        # xhot
            hoty,                        # yhot
            delay,                       # delay
        )
        chunks.append((nominal_size, chunk_header + bytes(pixels)))
    
    ntoc = len(chunks)
    
    # Calculate offsets
    toc_start = XCURSOR_HEADER_SIZE
    toc_size = ntoc * 12  # Each TOC entry is 12 bytes
    data_start = toc_start + toc_size
    
    # Build TOC
    toc = bytearray()
    offset = data_start
    for nominal_size, chunk_data in chunks:
        toc.extend(struct.pack('<III',
            XCURSOR_IMAGE_TYPE,
            nominal_size,
            offset
        ))
        offset += len(chunk_data)
    
    # Build file header
    header = struct.pack('<IIII',
        XCURSOR_MAGIC,
        XCURSOR_HEADER_SIZE,
        XCURSOR_VERSION,
        ntoc
    )
    
    # Write file
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'wb') as f:
        f.write(header)
        f.write(bytes(toc))
        for _, chunk_data in chunks:
            f.write(chunk_data)


# ─── Theme Builder ────────────────────────────────────────────────────────────

def build_theme(source_dir, output_dir):
    """Build the complete cursor theme."""
    
    cursors_dir = os.path.join(output_dir, 'cursors')
    os.makedirs(cursors_dir, exist_ok=True)
    
    # Write index.theme
    with open(os.path.join(output_dir, 'index.theme'), 'w') as f:
        f.write("[Icon Theme]\n")
        f.write("Name=Hello Kitty Y2K\n")
        f.write("Comment=Hello Kitty Y2K cursor theme\n")
        f.write("Inherits=oxy-white\n")
        f.write("Example=default\n")
    
    print("Building Hello Kitty Y2K cursor theme...")
    print(f"  Source: {source_dir}")
    print(f"  Output: {output_dir}")
    print()
    
    created_cursors = set()
    
    for filename, cursor_names in CURSOR_MAP.items():
        filepath = None
        
        # Find the file (flexible matching)
        for f in Path(source_dir).iterdir():
            if f.name.lower() == filename.lower():
                filepath = f
                break
            # Also try matching without the number prefix
            name_part = f.name
            # Strip leading number+spaces pattern like "021   "
            stripped = name_part.lstrip('0123456789').lstrip()
            if stripped.lower() == filename.lower():
                filepath = f
                break
        
        if filepath is None:
            # Try finding by partial match
            for f in Path(source_dir).iterdir():
                if filename.lower().replace('.cur', '').replace('.ani', '') in f.name.lower():
                    filepath = f
                    break
        
        if filepath is None:
            print(f"  ⚠ NOT FOUND: {filename}")
            continue
        
        print(f"  Processing: {filepath.name}")
        
        try:
            data = filepath.read_bytes()
            primary_name = cursor_names[0]
            
            if filepath.suffix.lower() == '.ani':
                frames, delays = parse_ani_file(data)
                if not frames:
                    print(f"    ⚠ No frames extracted from ANI")
                    continue
                
                cursor_images = []
                for (img, hotx, hoty), delay in zip(frames, delays):
                    # Ensure reasonable size (32px is standard)
                    if img.size[0] != 32 or img.size[1] != 32:
                        # Scale hotspot proportionally
                        scale_x = 32 / img.size[0]
                        scale_y = 32 / img.size[1]
                        hotx = int(hotx * scale_x)
                        hoty = int(hoty * scale_y)
                        img = img.resize((32, 32), Image.LANCZOS)
                    cursor_images.append((img, hotx, hoty, delay))
                
                print(f"    ✓ {len(frames)} frames, delays={delays[:3]}{'...' if len(delays)>3 else ''}ms")
                
            elif filepath.suffix.lower() == '.cur':
                cur_frames = parse_cur_file(data)
                if not cur_frames:
                    print(f"    ⚠ No images extracted from CUR")
                    continue
                
                # Take the best (largest) frame
                img, hotx, hoty = max(cur_frames, key=lambda f: f[0].size[0])
                
                # Resize to 32 if needed
                if img.size[0] != 32 or img.size[1] != 32:
                    scale_x = 32 / img.size[0]
                    scale_y = 32 / img.size[1]
                    hotx = int(hotx * scale_x)
                    hoty = int(hoty * scale_y)
                    img = img.resize((32, 32), Image.LANCZOS)
                
                cursor_images = [(img, hotx, hoty, 0)]
                print(f"    ✓ {img.size[0]}x{img.size[1]}, hotspot=({hotx},{hoty})")
            else:
                print(f"    ⚠ Unknown format: {filepath.suffix}")
                continue
            
            # Write the primary Xcursor file
            primary_path = os.path.join(cursors_dir, primary_name)
            write_xcursor(primary_path, cursor_images)
            created_cursors.add(primary_name)
            
            # Create symlinks for aliases
            for alias in cursor_names[1:]:
                alias_path = os.path.join(cursors_dir, alias)
                if os.path.exists(alias_path) or os.path.islink(alias_path):
                    os.remove(alias_path)
                os.symlink(primary_name, alias_path)
                created_cursors.add(alias)
            
            print(f"    → {primary_name} + {len(cursor_names)-1} symlinks")
            
        except Exception as e:
            print(f"    ✗ ERROR: {e}")
            import traceback
            traceback.print_exc()
    
    print()
    print(f"Created {len(created_cursors)} cursor entries")
    print(f"Missing cursors will fall back to Oxygen White (Inherits=oxy-white)")
    
    return created_cursors


# ─── Main ─────────────────────────────────────────────────────────────────────

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <source_dir_with_cur_ani_files>")
        print(f"       {sys.argv[0]} <source_dir> <output_dir>")
        print()
        print("Example:")
        print(f"  {sys.argv[0]} ~/Downloads/hello-kitty-cursors/")
        sys.exit(1)
    
    source_dir = sys.argv[1]
    if len(sys.argv) >= 3:
        output_dir = sys.argv[2]
    else:
        output_dir = os.path.expanduser('~/.local/share/icons/HelloKittyY2K')
    
    if not os.path.isdir(source_dir):
        print(f"Error: Source directory not found: {source_dir}")
        sys.exit(1)
    
    print("Available cursor files:")
    for f in sorted(Path(source_dir).iterdir()):
        if f.suffix.lower() in ('.cur', '.ani', '.crs'):
            print(f"  {f.name}")
    print()
    
    build_theme(source_dir, output_dir)
    
    print()
    print("═══════════════════════════════════════════")
    print("INSTALLATION COMPLETE!")
    print()
    print("Apply the cursor theme:")
    print("  System Settings → Appearance → Cursors")
    print("  → Select 'Hello Kitty Y2K' → Apply")
    print()
    print("Make sure 'oxy-white' (Oxygen White) is also installed")
    print("for the fallback cursors to work:")
    print("  sudo pacman -S oxygen-cursors")
    print("═══════════════════════════════════════════")
