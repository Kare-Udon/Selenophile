# Selenophile

[English](README.md) | [简体中文](README.zh-Hans.md) | [日本語](README.ja.md)

A native macOS menu bar monitor for Klipper printers.

Selenophile keeps the current state of your Moonraker / Klipper printer visible from the macOS menu bar. It focuses on monitoring, not printer control: quick status, live progress, temperatures, timing, layers, speed, camera snapshots, and enough logs to understand connection problems.

<p>
  <img src="docs/assets/readme/menu-popover.jpg" alt="Selenophile menu bar popover showing a live Klipper print" width="420">
</p>

## Highlights

- Native macOS menu bar app with a compact popover.
- Live Moonraker status for Klipper printers.
- Print progress, filename, elapsed time, remaining time, layers, speed, nozzle temperature, and bed temperature.
- Optional camera snapshot preview from a Moonraker-relative or absolute image URL.
- Settings for connection, refresh rate, launch at login, interface language, automatic update checks, appearance mode, and color palette.
- Debug logs for connection, retry, status update, and camera request issues.
- Built for Apple Silicon Macs on macOS 14 or later.

## Screenshots

| Connection | General |
| --- | --- |
| <img src="docs/assets/readme/settings-connection.jpg" alt="Moonraker connection settings" width="420"> | <img src="docs/assets/readme/settings-general.jpg" alt="General settings with language, refresh rate, launch at login, and update checks" width="420"> |

| Appearance |
| --- |
| <img src="docs/assets/readme/settings-appearance.jpg" alt="Appearance settings with theme and color palette options" width="620"> |

## Requirements

- Apple Silicon Mac.
- macOS 14 or later.
- A Klipper printer with Moonraker enabled.

## Moonraker Setup

Open **Settings** from the menu bar popover and enter your Moonraker connection details.

- **Moonraker URL**: usually `http://printer.local:7125` or `http://<printer-ip>:7125`.
- **API Token**: optional. Most local Moonraker installations do not need a token unless authentication is enabled.
- **Camera Snapshot URL**: optional. You can use a full URL such as `http://printer.local/webcam/?action=snapshot`, or a relative path on the Moonraker host such as `/webcam/?action=snapshot`.

Use **Test Connection** before saving if you want to verify the URL and token.

## What Selenophile Does Not Do

Selenophile is a monitor. It does not upload G-code, start prints, pause prints, cancel prints, or edit Klipper configuration. Those actions should stay in your existing printer UI.

## Languages

The app interface supports multiple languages. This README is available in English, Simplified Chinese, and Japanese.

## Build From Source

Clone the repository and build with Swift Package Manager:

```bash
swift build
```

Run the test suite:

```bash
swift test
```

Launch the menu bar app locally:

```bash
./run-menubar.sh
```

Build a local app package:

```bash
./Scripts/build_dmg.sh
```

The Xcode project is maintained through Tuist. If you use Tuist locally:

```bash
tuist generate --no-open
```

Release and update distribution notes live in [docs/sparkle-github-distribution.md](docs/sparkle-github-distribution.md).

## Contributing

Issues and pull requests are welcome. For code changes, keep the menu bar app focused on monitoring and run the relevant Swift tests before submitting.

## License

Selenophile is released under the [MIT License](LICENSE).
