<div align="center">

<img src="ae.png" width="120" alt="Aether Logo" />

# Aether
### Wireless Android Mirror for Linux

Mirror your Android phone over Wi-Fi — no USB, no terminal, no hassle.

![Early Version](https://img.shields.io/badge/status-early%20version-orange)
![Platform](https://img.shields.io/badge/platform-Linux-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Python](https://img.shields.io/badge/python-3.10%2B-blue)

> ⚠️ **This is a very early version of Aether.** Expect rough edges, missing features, and occasional bugs. Feedback and contributions are very welcome.

</div>

---

## What is Aether?

Aether is a clean GTK4 desktop app that lets you wirelessly mirror your Android phone to your Linux PC using ADB and scrcpy — all through a simple GUI. No typing commands, no fiddling with IPs. Just pair once and click Mirror.

---

## Features

- **One-click mirroring** — select a device, hit Mirror, done
- **Wireless pairing** — pairs over Wi-Fi using Android's built-in Wireless Debugging
- **Per-network profiles** — remembers your phone's IP per Wi-Fi network (home, work, etc.)
- **Auto-reconnect** — saved devices reconnect without re-entering anything
- **Per-device settings** — resolution, FPS, bitrate, codec, screen behaviour — all configurable per device
- **H.265 support** — uses H.265 if your system supports it, falls back to H.264 automatically
- **Auto disconnect** — ADB disconnects cleanly 30 seconds after you close the mirror window
- **Minimal UI** — phone-shaped window, dark theme, no clutter

---

## Requirements

| Package | Purpose |
|---|---|
| `python3` | Runtime |
| `python3-gobject` | GTK4 Python bindings |
| `gtk4` | UI toolkit |
| `libadwaita` | GNOME-style widgets |
| `adb` (android-tools) | Android Debug Bridge |
| `scrcpy` | Screen mirroring engine |
| `nmcli` (NetworkManager) | Wi-Fi SSID detection |
| `avahi-tools` *(optional)* | mDNS device discovery |
| `ffmpeg` *(optional)* | H.265 codec detection |

---

## Installation

### 1. Install dependencies

**Fedora:**
```bash
sudo dnf install python3-gobject gtk4 libadwaita android-tools scrcpy NetworkManager avahi-tools ffmpeg
```

**Ubuntu / Debian:**
```bash
sudo apt install python3-gi gir1.2-gtk-4.0 gir1.2-adw-1 adb scrcpy network-manager avahi-utils ffmpeg
```

**Arch Linux:**
```bash
sudo pacman -S python-gobject gtk4 libadwaita android-tools scrcpy networkmanager avahi ffmpeg
```

### 2. Clone and install Aether

```bash
git clone https://github.com/ShuBan863/Aether
cd Aether
chmod +x install.sh
./install.sh
```

Then open **Aether** from your app drawer.

---

## First-time Setup

1. On your Android phone: go to **Settings → Developer options → Wireless debugging** and turn it **ON**
2. Open **Aether** on your Linux PC
3. Click **Add Device** (the + row at the bottom of the list)
4. On your phone, tap **"Pair device with pairing code"** — enter the IP:port and 6-digit code shown into Aether
5. Once paired, enter the main ADB IP:port shown on the Wireless Debugging screen
6. Your device is saved — next time just click it and hit **Mirror**

---

## Usage

| Action | How |
|---|---|
| Mirror a device | Click device → click **Mirror** |
| Stop mirroring | Click **Stop** |
| Edit device settings | Click the ⚙ icon on any device row |
| Add a new device | Click **Add Device** (the + row) |
| Switch networks | Aether auto-uses the saved IP for your current Wi-Fi |

---

## Per-device Settings

Each device can be individually configured:

- **Resolution** — 480p, 720p, 1080p, 1440p, 2160p
- **Max FPS** — 15–120
- **Video Bitrate** — 4M to 32M
- **Video Codec** — H.264 or H.265
- **Turn off screen** — saves phone battery while mirroring
- **Stay awake** — prevents phone from sleeping during mirror

---

## Config File

Settings are stored in plain JSON at:

```
~/.config/aether/devices.json
```

---

## Known Limitations (Early Version)

- No automatic network scanning / mDNS discovery yet — you enter the IP manually
- No multi-monitor support
- Tested primarily on Fedora with GNOME — other distros may need minor adjustments
- No auto-update mechanism

---

## License

MIT — do whatever you want with it.

---

<div align="center">
Made by <a href="https://github.com/ShuBan863">ShuBan863</a>
</div>
