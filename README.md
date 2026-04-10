# Aether
### Wireless Android Mirror

A clean, polished GTK4 desktop app for mirroring your Android phone wirelessly via ADB and scrcpy — no terminal required after first setup.

---

## Features

- **Phone-shaped GUI** — intuitive vertical layout mirroring your device list
- **One-click mirroring** — click a device, click Mirror, done
- **Auto-discovery** — scans your local network via mDNS or port scan to find your phone
- **Per-network profiles** — saves IP:port per WiFi SSID; works seamlessly at home, work, anywhere
- **Auto-reconnect** — remembers paired devices; reconnects automatically without typing anything
- **Per-device settings** — resolution, FPS, bitrate, codec, screen behavior — all configurable per device
- **Auto disconnect** — ADB disconnects 30 seconds after you close the mirror window
- **H.265 auto-detection** — uses H.265 if your system supports it, falls back to H.264

---

## Requirements

```
python3
python3-gobject   (PyGObject / GTK4 bindings)
gtk4
libadwaita
adb               (android-tools)
scrcpy
nmcli             (NetworkManager CLI)
avahi-tools       (optional, for mDNS discovery)
ffmpeg            (optional, for H.265 detection)
```

Install on Fedora:
```bash
sudo dnf install python3-gobject gtk4 libadwaita android-tools scrcpy NetworkManager avahi-tools ffmpeg
```

---

## Install

```bash
git clone https://github.com/yourusername/aether
cd aether
chmod +x install.sh
./install.sh
```

Then open **Aether** from your app drawer.

---

## First-time setup

1. On your Android phone: **Settings → Developer options → Wireless debugging** → turn ON
2. Open Aether on your laptop
3. Tap **Add Device** (the + at the bottom of the list)
4. Aether scans your network — select your phone when it appears
5. On your phone tap **"Pair device with pairing code"** and enter the code in Aether
6. Done — your device is saved. Next time, just click it and hit Mirror.

---

## Usage

| Action | How |
|--------|-----|
| Mirror a device | Click device in list → click **Mirror** button |
| Stop mirroring | Click **Stop Mirror** button |
| Change settings | Click the ⚙ icon on any device row |
| Add new device | Click **Add Device** (last row with +) |
| New network | Aether auto-discovers on first connect; saves for future |

---

## Config

Settings stored at `~/.config/aether/devices.json` — human-readable JSON.

---

## License

MIT
