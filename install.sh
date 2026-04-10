#!/usr/bin/env bash
# Aether installer
set -e

BOLD="\033[1m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
RED="\033[0;31m"
RESET="\033[0m"

echo -e "${BOLD}${CYAN}"
echo "  ░█████╗░███████╗████████╗██╗░░██╗███████╗██████╗░"
echo "  ██╔══██╗██╔════╝╚══██╔══╝██║░░██║██╔════╝██╔══██╗"
echo "  ███████║█████╗░░░░░██║░░░███████║█████╗░░██████╔╝"
echo "  ██╔══██║██╔══╝░░░░░██║░░░██╔══██║██╔══╝░░██╔══██╗"
echo "  ██║░░██║███████╗░░░██║░░░██║░░██║███████╗██║░░██║"
echo "  ╚═╝░░╚═╝╚══════╝░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝"
echo -e "${RESET}"
echo -e "${BOLD}  Wireless Android Mirror — Installer${RESET}"
echo ""

# ── Check dependencies ──
echo -e "${CYAN}▸ Checking dependencies…${RESET}"

MISSING=()
for cmd in python3 adb scrcpy zenity nmcli; do
    if ! command -v "$cmd" &>/dev/null; then
        MISSING+=("$cmd")
    fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
    echo -e "${RED}  ✗ Missing: ${MISSING[*]}${RESET}"
    echo ""
    echo "  Install missing packages with:"
    echo "    sudo dnf install ${MISSING[*]}"
    echo ""
    echo "  Note: scrcpy may need to be installed via:"
    echo "    sudo dnf install scrcpy   OR   flatpak install flathub in.srev.scrcpy"
    echo ""
    read -rp "  Continue anyway? [y/N] " ans
    [[ "$ans" =~ ^[Yy]$ ]] || exit 1
fi

# check PyGObject / GTK4
if ! python3 -c "import gi; gi.require_version('Gtk','4.0'); gi.require_version('Adw','1')" 2>/dev/null; then
    echo -e "${RED}  ✗ PyGObject / GTK4 bindings not found${RESET}"
    echo "    Install with:  sudo dnf install python3-gobject gtk4 libadwaita"
    read -rp "  Continue anyway? [y/N] " ans
    [[ "$ans" =~ ^[Yy]$ ]] || exit 1
fi

echo -e "${GREEN}  ✓ Dependencies OK${RESET}"
echo ""

# ── Install ──
echo -e "${CYAN}▸ Installing Aether…${RESET}"

BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/applications"
mkdir -p "$BIN_DIR" "$APP_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# copy main script
cp "$SCRIPT_DIR/aether" "$BIN_DIR/aether"
chmod +x "$BIN_DIR/aether"
echo -e "  ${GREEN}✓${RESET} Installed  $BIN_DIR/aether"

# copy desktop entry (expand %h → actual home)
sed "s|%h|$HOME|g" "$SCRIPT_DIR/aether.desktop" > "$APP_DIR/aether.desktop"
echo -e "  ${GREEN}✓${RESET} Installed  $APP_DIR/aether.desktop"

# remove old pixel9-scrcpy entries if present
for old in \
    "$HOME/.local/bin/pixel9-scrcpy" \
    "$HOME/.local/share/applications/pixel9-scrcpy.desktop" \
    "$HOME/.local/share/applications/adb-toggle.desktop"; do
    if [[ -f "$old" ]]; then
        rm "$old"
        echo -e "  ${CYAN}↳ Removed old file: $old${RESET}"
    fi
done

# update desktop database
if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "$APP_DIR" 2>/dev/null || true
fi

echo ""
echo -e "${GREEN}${BOLD}  ✓ Aether installed successfully!${RESET}"
echo ""
echo -e "  Run it from your app drawer by searching  ${BOLD}Aether${RESET}"
echo -e "  Or from terminal:  ${BOLD}aether${RESET}"
echo ""
