# Selenophile Agent Guide

## Project Shape

- Selenophile is a macOS menu bar app for Moonraker/Klipper printer status.
- The normal product entry is `NSStatusItem` plus `NSPopover`; debug windows must stay explicit opt-in behavior.
- Tuist manifests are the app-bundle source of truth. SwiftPM is still useful for fast tests and fallback packaging.
- Core logic lives in `Sources/SelenophileKit/`; app UI and AppKit wiring live in `Sources/Selenophile/`.
- Widget code exists in `Sources/SelenophileWidgetExtension/`, but do not include it in the main app or release package unless the user explicitly changes that scope. The user currently has no Apple Developer account.

## Architecture Rules

- Keep networking, decoding, persistence, and state transitions out of SwiftUI view bodies.
- Prefer model/client/store changes before view patches when behavior changes.
- Keep launch argument parsing centralized in `AppLaunchConfiguration`.
- Reuse `MenuContentView` for debug main-panel windows; do not fork a separate automation UI.
- Runtime localization should resolve through SwiftPM `Bundle.module` behavior, including Tuist-generated app bundles.
- Appearance changes must flow through shared `AppAppearanceStore` and root `preferredColorScheme`.

## Common Commands

- Fast package build: `swift build`
- Full tests: `swift test`
- Launch product app locally: `./run-menubar.sh`
- Launch with debug UI window: `./run-menubar.sh --debug-ui-window`
- Stop app: `./stop-menubar.sh`
- Generate Tuist project: `tuist generate --no-open`
- Build app bundle with Xcode: `xcodebuild -project Selenophile.xcodeproj -scheme Selenophile -configuration Debug -derivedDataPath .build/tuist-derived build`
- Build local DMG: `./Scripts/build_dmg.sh`

## Verification

- App launch wiring, debug-window switches, `AppLaunchConfiguration`, `AppDelegate`, or `run-menubar.sh`: run `swift build`.
- Launch argument parser changes: run `swift test --filter AppLaunchConfiguration`.
- Packaging or DMG script changes: run `./Tests/build_dmg_test.sh`.
- Resource, localization, icon, or real app-bundle behavior: prefer `tuist generate --no-open` plus `xcodebuild` over SwiftPM-only verification.
- Shell script changes: run `bash -n` on the touched scripts.

## Release Notes

- Current intended version is `0.1.0`, but always confirm with the user before changing release/version values.
- Version-related values include `MARKETING_VERSION`, `BUILD_NUMBER`, DMG names, bundle version metadata, and release docs.
- Keep `run-menubar.sh`, README usage, and release scripts synchronized when changing launch flags or package behavior.
- Local ad-hoc signing is acceptable for development. Do not add Developer ID, notarization, or App Store assumptions unless the user asks.

## Git Hygiene

- The worktree may contain user changes. Do not revert unrelated dirty files.
- Keep edits tightly scoped and stage only files that belong to the current task.
- Generated Xcode project files may be dirty; check whether Tuist manifest changes require regeneration before touching them.
