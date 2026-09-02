# Clipboard

A fast, native clipboard manager that lives quietly in your macOS menu bar.

[![Platform](https://img.shields.io/badge/platform-macOS-black)](#download)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![Privacy](https://img.shields.io/badge/data%20collection-none-brightgreen)](#privacy)

## Privacy

**Your clipboard is safe. Clipboard does not collect, transmit, or share any data — ever.**

- Every clip is stored **only** on your Mac, in a local SQLite database in your user Library folder.
- The app makes **zero network requests**. There's no analytics, no telemetry, no crash reporting, no accounts, no sign-in.
- The shipped build runs inside Apple's App Sandbox and is **not granted the network-client entitlement** — it is technically incapable of making an outbound connection, not just promising not to. (The only exception: tapping a link in the About tab, like "Report a Bug," opens your default browser — a separate process outside the app's sandbox.)
- The app is open source, so you don't have to take any of this on faith — read [`lib/services/database_service.dart`](lib/services/database_service.dart) and [`macos/Runner/Release.entitlements`](macos/Runner/Release.entitlements) yourself.

## Features

- **Menu bar popup** — click the tray icon for instant access to recent clips
- **Full history window** — search and browse everything you've copied
- **Trash** — deleted clips are recoverable, not gone
- **Settings** — control history size and launch-at-login
- **One menu bar icon, two gestures** — single click toggles the popup; double-click opens a menu with History, Trash, Settings, About, and Quit
- **Launch at login** — optional, off by default
- Native macOS vibrancy ("glass") window styling

## Download

Get the latest build from the [**Releases page**](https://github.com/coder-shanta/macos-clipboard/releases/latest):

1. Download `Clipboard-<version>.dmg`
2. Open the DMG and drag **Clipboard** into **Applications**
3. Launch it from Applications or Spotlight — it lives in your menu bar; there's no Dock icon or window that opens automatically

### First launch (Gatekeeper)

This build is signed ad-hoc but not notarized by Apple, so macOS will warn that it's from an "unidentified developer" the first time you open it. To run it anyway:

- Right-click (or Control-click) **Clipboard.app** → **Open** → **Open**, or
- **System Settings → Privacy & Security**, scroll down, and click **Open Anyway** next to the Clipboard warning

You only need to do this once.

## Building from source

Requires [Flutter](https://flutter.dev) with macOS desktop support enabled.

```bash
git clone https://github.com/coder-shanta/macos-clipboard.git
cd macos-clipboard
flutter pub get
flutter build macos --release
```

The built app lands at `build/macos/Build/Products/Release/Clipboard.app`.

## Feedback

Found a bug, or have an idea for a feature? Use the **About** tab in the app (double-click the menu bar icon → About) — it links straight to a pre-filled GitHub issue — or open one directly:

- 🐛 [Report a bug](https://github.com/coder-shanta/macos-clipboard/issues/new?template=bug_report.yml)
- 💡 [Request a feature](https://github.com/coder-shanta/macos-clipboard/issues/new?template=feature_request.yml)

## License

[MIT](LICENSE) © Shanta Miah
