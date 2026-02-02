# Porticide

<p align="center">
  <img src="https://img.shields.io/badge/macOS-13.0+-blue.svg" alt="macOS 13.0+">
  <img src="https://img.shields.io/badge/Swift-6.0-orange.svg" alt="Swift 6.0">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="MIT License">
</p>

Kill local dev servers from your menu bar. No more terminal archaeology.

> **⚠️ MVP Status**: This is a working MVP built quickly to solve a personal need. It works but hasn't been polished or extensively tested. Use at your own risk.

## Why

Running multiple projects locally gets messy fast. You've got Vite on 5173, Streamlit on 8501, Next.js on 3000, some Flask API you forgot about still holding port 5000. Your Mac fans are screaming, Docker containers are piling up, and you just want to start fresh without hunting through `ps aux` or memorizing PIDs.

Porticide lives in your menu bar and shows exactly what's eating your ports. One click to kill anything.

## What it does

- Scans ports 3000–9999 and tells you what's running
- Detects common services (Vite, Next, Django, Flask, Streamlit, Docker, etc)
- Shows which project folder each service is running from
- Kills processes instantly without confirmations (optional: enable confirmation dialog)
- Filters out macOS system stuff so you only see your dev servers
- Refreshes automatically every 3 seconds

## Installation

```bash
git clone https://github.com/zontaggio/porticide.git
cd porticide
swift build
.build/arm64-apple-macosx/debug/Porticide &
```

Or open `Porticide.xcodeproj` in Xcode and hit Run.

## Usage

Click the menu bar icon. See your ports. Kill what you don't need.

Settings let you change the port range, refresh interval, and toggle confirmations.

## Requirements

macOS 13+ with Xcode 15+ to build from source.

## Development

```bash
swift build                                  # Build the app
swift test                                   # Run tests
.build/arm64-apple-macosx/debug/Porticide &  # Launch the app in background
```

To work in Xcode: `open Porticide.xcodeproj`

## How it works

Uses `lsof` to scan ports and parse process info. Some system processes need sudo to kill (Porticide will tell you).

## License

MIT — see [LICENSE](LICENSE)
