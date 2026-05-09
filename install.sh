#!/usr/bin/env bash
# Aether install script
# Installs dependencies carefully per distro, then installs Aether itself.

set -e

INSTALL_BIN="$HOME/.local/bin"
INSTALL_APPS="$HOME/.local/share/applications"
INSTALL_ICONS="$HOME/.local/share/icons/hicolor/512x512/apps"

# ── Colours ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; NC='\033[0m'
ok()   { echo -e "  ${GREEN}✓${NC}  $*"; }
warn() { echo -e "  ${YELLOW}!${NC}  $*"; }
fail() { echo -e "  ${RED}✗${NC}  $*"; }

echo ""
echo "  Aether — Wireless Android Mirror"
echo "  ─────────────────────────────────"
echo ""

# ── Detect distro ─────────────────────────────────────────────────────────────
if command -v dnf &>/dev/null; then
    DISTRO="fedora"
elif command -v apt &>/dev/null; then
    DISTRO="debian"
elif command -v pacman &>/dev/null; then
    DISTRO="arch"
else
    DISTRO="unknown"
fi

echo "  Detected distro family: $DISTRO"
echo ""

# ── Helper: check if a python module is importable ────────────────────────────
py_has() { python3 -c "import $1" 2>/dev/null; }

# ── Helper: check if a command exists and works ───────────────────────────────
cmd_ok() { command -v "$1" &>/dev/null; }

# ══════════════════════════════════════════════════════════════════════════════
#  FEDORA / RHEL / DNF
# ══════════════════════════════════════════════════════════════════════════════
install_fedora() {
    echo "  Installing dependencies via dnf..."
    echo ""

    # Refresh metadata first so package names resolve correctly
    sudo dnf makecache --quiet || true

    # ── Core Python / GTK stack ───────────────────────────────────────────────
    # python3-gobject  →  the GObject/GTK Python bindings (gi.repository)
    # gtk4             →  GTK4 runtime libraries
    # libadwaita       →  Adwaita widgets (Adw.ApplicationWindow etc.)
    echo "  [1/6] GTK4 + Python bindings..."
    sudo dnf install -y python3-gobject gtk4 libadwaita
    py_has gi && ok "python3-gobject (gi) ready" || { fail "python3-gobject import failed after install"; exit 1; }

    # ── ADB ───────────────────────────────────────────────────────────────────
    # android-tools    →  provides adb; Fedora ships this as android-tools
    echo "  [2/6] ADB (android-tools)..."
    sudo dnf install -y android-tools
    cmd_ok adb && ok "adb $(adb --version | head -1)" || { fail "adb not found after install"; exit 1; }

    # ── scrcpy ────────────────────────────────────────────────────────────────
    # scrcpy 2.x is required; Fedora's repo usually has a current version.
    # If dnf doesn't have it or it's too old, we tell the user.
    echo "  [3/6] scrcpy..."
    sudo dnf install -y scrcpy || warn "scrcpy not in dnf repos — see below for manual install"
    if cmd_ok scrcpy; then
        VER=$(scrcpy --version 2>&1 | grep -oP '\d+\.\d+' | head -1)
        MAJOR=$(echo "$VER" | cut -d. -f1)
        if [ "${MAJOR:-0}" -ge 2 ]; then
            ok "scrcpy $VER"
        else
            warn "scrcpy $VER is too old — Aether needs 2.x"
            warn "Install manually: https://github.com/Genymobile/scrcpy"
        fi
    else
        warn "scrcpy missing — install manually: https://github.com/Genymobile/scrcpy"
    fi

    # ── NetworkManager (nmcli) ────────────────────────────────────────────────
    # Used to detect the current Wi-Fi SSID for per-network IP profiles.
    # Usually pre-installed on Fedora desktop.
    echo "  [4/6] NetworkManager..."
    sudo dnf install -y NetworkManager
    cmd_ok nmcli && ok "nmcli ready" || warn "nmcli not found — Wi-Fi network detection will be skipped"

    # ── Window management tools ───────────────────────────────────────────────
    # xdotool + wmctrl + python3-xlib  →  borderless mirror window move/resize
    # These are X11/XWayland tools; on pure Wayland they gracefully no-op.
    echo "  [5/6] Window tools (xdotool, wmctrl, python3-xlib)..."
    sudo dnf install -y xdotool wmctrl python3-xlib
    cmd_ok xdotool && ok "xdotool ready" || warn "xdotool missing — mirror window drag may not work"
    cmd_ok wmctrl  && ok "wmctrl ready"  || warn "wmctrl missing — mirror window management may not work"
    py_has Xlib    && ok "python3-xlib ready" || warn "python3-xlib missing — native window move may not work"

    # ── avahi-tools + python3-qrcode ──────────────────────────────────────────
    # avahi-tools      →  avahi-browse, used for QR pairing (finding phone on mDNS)
    # avahi-daemon     →  the mDNS daemon avahi-browse talks to
    # python3-qrcode   →  generates the QR code image shown in the UI
    # python3-pillow   →  image processing for the QR code (usually already installed)
    echo "  [6/6] QR pairing tools (avahi, qrcode, pillow)..."
    sudo dnf install -y avahi avahi-tools python3-qrcode python3-pillow

    cmd_ok avahi-browse && ok "avahi-browse ready" || warn "avahi-browse missing — QR pairing will not work"
    py_has qrcode       && ok "python3-qrcode ready" || warn "python3-qrcode missing — QR code will not display"
    py_has PIL          && ok "python3-pillow ready" || warn "python3-pillow missing — QR code will not display"

    # Enable and start avahi-daemon (needed for avahi-browse to work).
    # Unmask first in case it was previously masked.
    echo ""
    echo "  Enabling avahi-daemon..."
    sudo systemctl unmask avahi-daemon.socket avahi-daemon.service 2>/dev/null || true
    sudo systemctl enable --now avahi-daemon 2>/dev/null \
        && ok "avahi-daemon enabled and running" \
        || warn "Could not start avahi-daemon — QR pairing may not work. Try: sudo systemctl start avahi-daemon"

    # ── Optional: ffmpeg ──────────────────────────────────────────────────────
    # Only used for H.265 codec detection at startup. Not required.
    sudo dnf install -y ffmpeg 2>/dev/null && ok "ffmpeg ready (optional)" || true
}

# ══════════════════════════════════════════════════════════════════════════════
#  DEBIAN / UBUNTU / APT
# ══════════════════════════════════════════════════════════════════════════════
install_debian() {
    echo "  Installing dependencies via apt..."
    echo ""

    sudo apt update -qq

    # ── Core Python / GTK stack ───────────────────────────────────────────────
    # python3-gi           →  GObject introspection bindings
    # gir1.2-gtk-4.0       →  GTK4 typelib (needed for gi.require_version)
    # gir1.2-adw-1         →  libadwaita typelib
    echo "  [1/6] GTK4 + Python bindings..."
    sudo apt install -y python3-gi gir1.2-gtk-4.0 gir1.2-adw-1 libgtk-4-1 libadwaita-1-0
    py_has gi && ok "python3-gi (gi) ready" || { fail "python3-gi import failed after install"; exit 1; }

    # ── ADB ───────────────────────────────────────────────────────────────────
    # adb is in the android-sdk-platform-tools-common / adb package.
    # On older Ubuntu it may be called android-tools-adb.
    echo "  [2/6] ADB..."
    sudo apt install -y adb 2>/dev/null || sudo apt install -y android-tools-adb 2>/dev/null || true
    cmd_ok adb && ok "adb $(adb --version | head -1)" || { fail "adb not found — install manually"; exit 1; }

    # ── scrcpy ────────────────────────────────────────────────────────────────
    # Ubuntu/Debian's repos are often behind on scrcpy. We check the version
    # and warn if it's too old. User may need to use the GitHub release binary.
    echo "  [3/6] scrcpy..."
    sudo apt install -y scrcpy 2>/dev/null || warn "scrcpy not in apt repos"
    if cmd_ok scrcpy; then
        VER=$(scrcpy --version 2>&1 | grep -oP '\d+\.\d+' | head -1)
        MAJOR=$(echo "$VER" | cut -d. -f1)
        if [ "${MAJOR:-0}" -ge 2 ]; then
            ok "scrcpy $VER"
        else
            warn "scrcpy $VER is too old (need 2.x). Install manually:"
            warn "  https://github.com/Genymobile/scrcpy/blob/master/doc/linux.md"
        fi
    else
        warn "scrcpy not installed. Install manually:"
        warn "  https://github.com/Genymobile/scrcpy/blob/master/doc/linux.md"
    fi

    # ── NetworkManager ────────────────────────────────────────────────────────
    echo "  [4/6] NetworkManager..."
    sudo apt install -y network-manager
    cmd_ok nmcli && ok "nmcli ready" || warn "nmcli not found — Wi-Fi network detection will be skipped"

    # ── Window management tools ───────────────────────────────────────────────
    echo "  [5/6] Window tools (xdotool, wmctrl, python3-xlib)..."
    sudo apt install -y xdotool wmctrl python3-xlib
    cmd_ok xdotool && ok "xdotool ready" || warn "xdotool missing"
    cmd_ok wmctrl  && ok "wmctrl ready"  || warn "wmctrl missing"
    py_has Xlib    && ok "python3-xlib ready" || warn "python3-xlib missing"

    # ── avahi + QR ───────────────────────────────────────────────────────────
    echo "  [6/6] QR pairing tools (avahi, qrcode, pillow)..."
    sudo apt install -y avahi-daemon avahi-utils python3-qrcode python3-pil

    cmd_ok avahi-browse   && ok "avahi-browse ready" || warn "avahi-browse missing — QR pairing will not work"
    py_has qrcode         && ok "python3-qrcode ready" || warn "python3-qrcode missing"
    py_has PIL            && ok "python3-pillow ready" || warn "python3-pillow missing"

    echo ""
    echo "  Enabling avahi-daemon..."
    sudo systemctl unmask avahi-daemon 2>/dev/null || true
    sudo systemctl enable --now avahi-daemon 2>/dev/null \
        && ok "avahi-daemon enabled and running" \
        || warn "Could not start avahi-daemon — QR pairing may not work"

    sudo apt install -y ffmpeg 2>/dev/null && ok "ffmpeg ready (optional)" || true
}

# ══════════════════════════════════════════════════════════════════════════════
#  ARCH / MANJARO / PACMAN
# ══════════════════════════════════════════════════════════════════════════════
install_arch() {
    echo "  Installing dependencies via pacman..."
    echo ""

    sudo pacman -Sy --noconfirm 2>/dev/null || true

    # ── Core Python / GTK stack ───────────────────────────────────────────────
    # python-gobject  →  GObject Python bindings (note: no '3' prefix on Arch)
    echo "  [1/6] GTK4 + Python bindings..."
    sudo pacman -S --noconfirm --needed python-gobject gtk4 libadwaita
    py_has gi && ok "python-gobject (gi) ready" || { fail "gi import failed after install"; exit 1; }

    # ── ADB ───────────────────────────────────────────────────────────────────
    echo "  [2/6] ADB (android-tools)..."
    sudo pacman -S --noconfirm --needed android-tools
    cmd_ok adb && ok "adb $(adb --version | head -1)" || { fail "adb not found"; exit 1; }

    # ── scrcpy ────────────────────────────────────────────────────────────────
    echo "  [3/6] scrcpy..."
    sudo pacman -S --noconfirm --needed scrcpy
    if cmd_ok scrcpy; then
        VER=$(scrcpy --version 2>&1 | grep -oP '\d+\.\d+' | head -1)
        ok "scrcpy $VER"
    else
        warn "scrcpy not installed — install via AUR or manually"
    fi

    # ── NetworkManager ────────────────────────────────────────────────────────
    echo "  [4/6] NetworkManager..."
    sudo pacman -S --noconfirm --needed networkmanager
    cmd_ok nmcli && ok "nmcli ready" || warn "nmcli not found — Wi-Fi detection will be skipped"
    # Make sure it's running
    sudo systemctl enable --now NetworkManager 2>/dev/null || true

    # ── Window management tools ───────────────────────────────────────────────
    echo "  [5/6] Window tools (xdotool, wmctrl, python-xlib)..."
    sudo pacman -S --noconfirm --needed xdotool wmctrl python-xlib
    cmd_ok xdotool && ok "xdotool ready" || warn "xdotool missing"
    cmd_ok wmctrl  && ok "wmctrl ready"  || warn "wmctrl missing"
    py_has Xlib    && ok "python-xlib ready" || warn "python-xlib missing"

    # ── avahi + QR ───────────────────────────────────────────────────────────
    echo "  [6/6] QR pairing tools (avahi, qrcode, pillow)..."
    sudo pacman -S --noconfirm --needed avahi python-qrcode python-pillow

    cmd_ok avahi-browse && ok "avahi-browse ready" || warn "avahi-browse missing — QR pairing will not work"
    py_has qrcode       && ok "python-qrcode ready" || warn "python-qrcode missing"
    py_has PIL          && ok "python-pillow ready" || warn "python-pillow missing"

    echo ""
    echo "  Enabling avahi-daemon..."
    sudo systemctl unmask avahi-daemon 2>/dev/null || true
    sudo systemctl enable --now avahi-daemon 2>/dev/null \
        && ok "avahi-daemon enabled and running" \
        || warn "Could not start avahi-daemon — QR pairing may not work"

    sudo pacman -S --noconfirm --needed ffmpeg 2>/dev/null && ok "ffmpeg ready (optional)" || true
}

# ══════════════════════════════════════════════════════════════════════════════
#  RUN DISTRO INSTALL
# ══════════════════════════════════════════════════════════════════════════════
case "$DISTRO" in
    fedora)  install_fedora ;;
    debian)  install_debian ;;
    arch)    install_arch   ;;
    *)
        warn "Could not detect your package manager."
        warn "Please install the following manually, then re-run this script:"
        echo ""
        echo "    - python3 + GTK4 bindings (python3-gobject / python3-gi)"
        echo "    - libadwaita"
        echo "    - adb (android-tools)"
        echo "    - scrcpy 2.x"
        echo "    - NetworkManager (nmcli)"
        echo "    - xdotool, wmctrl, python3-xlib"
        echo "    - avahi + avahi-browse"
        echo "    - python3-qrcode, python3-pillow"
        echo ""
        read -rp "  Continue installing Aether anyway? [y/N] " REPLY
        [[ "$REPLY" =~ ^[Yy]$ ]] || exit 1
        ;;
esac

# ══════════════════════════════════════════════════════════════════════════════
#  INSTALL AETHER
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo "  ─────────────────────────────────"
echo "  Installing Aether..."
echo ""

mkdir -p "$INSTALL_BIN" "$INSTALL_APPS" "$INSTALL_ICONS"

# Make sure ~/.local/bin is on PATH (common oversight on fresh installs)
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    warn "~/.local/bin is not in your PATH."
    warn "Add this to your ~/.bashrc or ~/.zshrc and restart your terminal:"
    warn "  export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

if [ ! -f "aether" ]; then
    fail "aether script not found in current directory."
    fail "Make sure you're running this from inside the cloned Aether folder."
    exit 1
fi

cp aether "$INSTALL_BIN/aether"
chmod +x "$INSTALL_BIN/aether"
ok "aether installed to $INSTALL_BIN/aether"

if [ -f "ae.png" ]; then
    cp ae.png "$INSTALL_ICONS/aether.png"
    ok "icon installed"
else
    warn "ae.png not found — icon will not appear in app drawer"
fi

if [ -f "phone.png" ]; then
    SHARE_DIR="$HOME/.local/share/aether"
    mkdir -p "$SHARE_DIR"
    cp phone.png "$SHARE_DIR/phone.png"
    ok "phone.png installed"
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

# Remove old desktop entry name if present
rm -f "$INSTALL_APPS/aether.desktop"

gtk-update-icon-cache -f "$HOME/.local/share/icons/hicolor/" 2>/dev/null || true
update-desktop-database "$INSTALL_APPS" 2>/dev/null || true
ok "desktop entry installed"

echo ""
echo "  ─────────────────────────────────"
ok "All done! Open Aether from your app drawer."
echo "  (You may need to log out and back in for the icon to appear.)"
echo ""
