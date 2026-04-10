#!/usr/bin/env bash
set -e

INSTALL_BIN="$HOME/.local/bin"
INSTALL_APPS="$HOME/.local/share/applications"
INSTALL_ICONS="$HOME/.local/share/icons/hicolor/512x512/apps"

echo ""
echo "  Installing Aether..."
echo ""

# Create dirs
mkdir -p "$INSTALL_BIN" "$INSTALL_APPS" "$INSTALL_ICONS"

# Install the main script
cp aether "$INSTALL_BIN/aether"
chmod +x "$INSTALL_BIN/aether"

# Install the icon
if [ -f "ae.png" ]; then
    cp ae.png "$INSTALL_ICONS/aether.png"
else
    echo "  Warning: ae.png not found, skipping icon."
fi

# Write the desktop entry
cat > "$INSTALL_APPS/aether.desktop" << EOF
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
EOF

# Refresh caches
gtk-update-icon-cache -f "$HOME/.local/share/icons/hicolor/" 2>/dev/null || true
update-desktop-database "$INSTALL_APPS" 2>/dev/null || true

echo ""
echo "  Done! Open Aether from your app drawer."
echo "  (You may need to log out and back in for the icon to appear.)"
echo ""
