# 🎀 Hello Kitty Y2K — Arch Linux KDE Plasma Rice

A **2000s-era Hello Kitty** themed desktop environment for KDE Plasma on Arch Linux.
Pink, sparkly, bubbly, and unapologetically cute — just like 2003.

## 📦 Components

| Layer              | Technology         | Theme                    |
|--------------------|--------------------|--------------------------|
| Desktop            | KDE Plasma 6       | HelloKittyY2K            |
| Theme Engine       | Kvantum            | HelloKittyY2K            |
| Window Decorations | Aurorae + Oxygen   | HelloKittyY2K            |
| Color Scheme       | KDE Colors         | HelloKittyY2K            |
| Terminal           | Konsole            | HelloKittyY2K            |
| Login Screen       | SDDM               | HelloKittyY2K            |
| Wallpaper          | Custom SVG          | Hello Kitty pattern      |

## 🚀 Quick Install

```bash
chmod +x install.sh
./install.sh
```

Then log out and back in. Select the HelloKittyY2K theme in:
- **System Settings → Appearance → Global Theme**
- **System Settings → Appearance → Colors → HelloKittyY2K**
- **System Settings → Appearance → Application Style → kvantum** (then open Kvantum Manager and select HelloKittyY2K)
- **System Settings → Appearance → Window Decorations → HelloKittyY2K**
- **System Settings → Startup and Shutdown → Login Screen (SDDM) → HelloKittyY2K**

## 🎨 Color Palette

| Name              | Hex       | Usage                        |
|-------------------|-----------|------------------------------|
| Kitty Pink        | `#FF69B4` | Primary / Accents            |
| Baby Pink         | `#FFB6C1` | Backgrounds / Hover          |
| Bubblegum         | `#FF1493` | Active / Focus               |
| Cream             | `#FFF0F5` | Base background              |
| Lavender Mist     | `#E6B8D4` | Secondary surfaces           |
| Hot Magenta       | `#FF00AA` | Highlights / Links           |
| Snow White        | `#FFFFFF` | Text backgrounds             |
| Deep Rose         | `#C71585` | Window title bars            |
| Soft Black        | `#4A2040` | Text color                   |
| Y2K Silver        | `#D4C5CC` | Borders / Inactive           |

## 🖼️ Screenshots

After installation your desktop will feature:
- Bubbly pink Aurorae window borders with rounded corners
- Glossy Kvantum widgets with Hello Kitty-inspired gradients
- A tiled Hello Kitty wallpaper pattern in pastel pink
- Pink SDDM login screen with a retro 2000s login box
- Konsole terminal with pink/magenta color scheme
- Oxygen-style beveled buttons and glossy scrollbars

## 📁 File Structure

```
hellokitty-dotfiles/
├── install.sh                    # One-click installer
├── kvantum/
│   └── HelloKittyY2K/
│       ├── HelloKittyY2K.kvconfig # Kvantum theme config
│       └── HelloKittyY2K.svg      # Kvantum SVG theme
├── aurorae/
│   └── HelloKittyY2K/
│       ├── HelloKittyY2Krc        # Aurorae decoration config
│       └── decoration.svg         # Window decoration SVG
├── color-schemes/
│   └── HelloKittyY2K.colors       # KDE color scheme
├── konsole/
│   └── HelloKittyY2K.colorscheme  # Konsole terminal colors
├── sddm/
│   └── HelloKittyY2K/
│       ├── theme.conf             # SDDM theme config
│       ├── metadata.desktop       # SDDM metadata
│       └── Main.qml               # SDDM login screen
├── wallpapers/
│   └── hellokitty-y2k.svg         # Tiled wallpaper
├── plasma/
│   └── desktoptheme/
│       └── HelloKittyY2K/
│           └── metadata.json      # Plasma theme metadata
└── scripts/
    └── plasma-settings.sh         # Apply plasma settings
```

## ⚙️ Dependencies

- `plasma-desktop` (KDE Plasma)
- `kvantum` (Qt theme engine)
- `sddm` (Login manager)
- `konsole` (Terminal)

Install with:
```bash
sudo pacman -S plasma-desktop kvantum sddm konsole
```

## 🔧 Manual Tweaks

### Panel
For the full Y2K look, right-click your panel → Edit Panel:
- Set panel height to 48px
- Use "Icons Only Task Manager"
- Add "Digital Clock" widget with pink text

### Fonts
Install a bubbly 2000s font:
```bash
# Example: use a rounded/bubbly font
yay -S ttf-comfortaa
```
Then set it in System Settings → Fonts.

### Cursor
For maximum 2000s energy:
```bash
yay -S xcursor-pinknblack
```

## 💖 Credits

Made with love and nostalgia for the Y2K aesthetic.
Hello Kitty is a trademark of Sanrio Co., Ltd. This is a fan-made theme for personal use.
