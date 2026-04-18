#!/usr/bin/env bash
set -e

INSTALL_BIN="$HOME/.local/bin"
INSTALL_APPS="$HOME/.local/share/applications"
INSTALL_ICONS="$HOME/.local/share/icons/hicolor/512x512/apps"

echo ""
echo "  Aether — Wireless Android Mirror"
echo ""

# ── Install dependencies ───────────────────────────────────────────────────────
echo "  Installing dependencies..."

if command -v dnf &>/dev/null; then
    sudo dnf install -y python3-gobject gtk4 libadwaita android-tools scrcpy NetworkManager avahi-tools ffmpeg xdotool wmctrl python3-xlib

elif command -v apt &>/dev/null; then
    sudo apt install -y python3-gi gir1.2-gtk-4.0 gir1.2-adw-1 adb scrcpy network-manager avahi-utils ffmpeg xdotool wmctrl python3-xlib

elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm python-gobject gtk4 libadwaita android-tools scrcpy networkmanager avahi ffmpeg xdotool wmctrl python-xlib

else
    echo "  Warning: Could not detect package manager. Install dependencies manually."
    echo "  See README.md for instructions."
fi

# ── Install Aether ─────────────────────────────────────────────────────────────
echo ""
echo "  Installing Aether..."

mkdir -p "$INSTALL_BIN" "$INSTALL_APPS" "$INSTALL_ICONS"

cp aether "$INSTALL_BIN/aether"
chmod +x "$INSTALL_BIN/aether"

if [ -f "ae.png" ]; then
    cp ae.png "$INSTALL_ICONS/aether.png"
else
    echo "  Warning: ae.png not found, skipping icon."
fi

cat > "$INSTALL_APPS/io.github.aether.desktop" << DESKTOP
[Desktop Entry]
Name=Aether
Comment=Wireless Android Mirror — manage ADB devices and launch scrcpy
Exec=$INSTALL_BIN/aether
Icon=aether
Terminal=false
Type=Application
Categories=Utility;Network;
Keywords=android;adb;mirror;scrcpy;wireless;
StartupWMClass=aether
StartupNotify=true
DESKTOP

# Remove old desktop entry if present
rm -f "$INSTALL_APPS/aether.desktop"

gtk-update-icon-cache -f "$HOME/.local/share/icons/hicolor/" 2>/dev/null || true
update-desktop-database "$INSTALL_APPS" 2>/dev/null || true

echo ""
echo "  Done! Open Aether from your app drawer."
echo "  (You may need to log out and back in for the icon to appear.)"
echo ""
