# Selenophile WidgetKit Extension Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a native macOS WidgetKit extension that presents Selenophile printer status in small, medium, and large widget families with the same calm card design used in the browser preview.

**Architecture:** Keep the live Moonraker connection in the main menu bar app and expose only a compact, serializable widget snapshot through shared storage. Add a WidgetKit extension target that reads that snapshot, renders three widget families with SwiftUI, and asks the host app to refresh timelines when status changes. This keeps the widget passive and reliable while reusing the existing status model and design language.

**Tech Stack:** Swift 6.2, SwiftUI, WidgetKit, App Group shared storage, existing `SelenophileKit` models, Tuist/Xcode project manifest updates.

---

### Task 1: Add a shared widget snapshot model and persistence layer

**Files:**
- Create: `Sources/SelenophileKit/WidgetSnapshot.swift`
- Create: `Sources/SelenophileKit/WidgetSnapshotStore.swift`
- Modify: `Sources/SelenophileKit/AppConfig.swift`
- Modify: `Sources/SelenophileKit/PrinterStatusStore.swift`
- Create: `Tests/SelenophileKitTests/WidgetSnapshotStoreTests.swift`

- [ ] **Step 1: Define the snapshot payload**

Create a `WidgetSnapshot` type that is `Codable`, `Equatable`, and `Sendable`. It should contain only widget-safe fields:

```swift
public struct WidgetSnapshot: Codable, Equatable, Sendable {
    public var statusLabel: String
    public var connectionLabel: String
    public var title: String
    public var progress: Double
    public var progressLabel: String
    public var remainingTime: String
    public var elapsedTime: String
    public var nozzle: String
    public var bed: String
    public var layer: String
    public var speed: String
    public var summary: String
    public var tone: WidgetTone
}
```

Add a small `WidgetTone` enum for the visual state variants used by the widget view.

- [ ] **Step 2: Add a shared persistence store**

Create a store that reads/writes the snapshot into the App Group container:

```swift
public final class WidgetSnapshotStore {
    public init(fileManager: FileManager = .default)
    public func load() -> WidgetSnapshot?
    public func save(_ snapshot: WidgetSnapshot)
    public func clear()
}
```

Use a dedicated file path inside the shared container so the widget can load it even if the host app is not running.

- [ ] **Step 3: Export a snapshot from printer state**

Add a helper on `PrinterStatusStore` that converts the current printer status into a `WidgetSnapshot`.

The conversion should:
- preserve the existing status copy
- clamp progress into `0...1`
- normalize missing values into `--`
- keep the widget snapshot independent from the heavier `PrinterStatusStore`

- [ ] **Step 4: Write tests for snapshot serialization**

Add tests that confirm:
- a snapshot can be encoded and decoded without loss
- the App Group file path is stable
- clearing the store removes the saved file
- a printer status with partial data still produces a valid snapshot

---

### Task 2: Add the WidgetKit extension target to the project manifests

**Files:**
- Modify: `Project.swift`
- Modify: `Package.swift`
- Create: `Sources/SelenophileWidgetExtension/SelenophileWidget.swift`
- Create: `Sources/SelenophileWidgetExtension/WidgetEntry.swift`
- Create: `Sources/SelenophileWidgetExtension/WidgetView.swift`
- Create: `Sources/SelenophileWidgetExtension/WidgetProvider.swift`

- [ ] **Step 1: Add the extension target to Tuist**

Add a WidgetKit app extension target in `Project.swift` with:
- product: app extension
- bundle id under `com.udon.selenophile`
- dependency on `SelenophileKit`
- App Group entitlement for shared snapshot access

- [ ] **Step 2: Keep SwiftPM in sync for library/test resolution**

Update `Package.swift` so the shared library and tests still build cleanly with the new snapshot types. The widget extension itself should remain project-target based rather than forcing SwiftPM to do packaging work it does not own.

- [ ] **Step 3: Create the WidgetKit scaffolding files**

Add the extension entry point and provider using `WidgetKit` and `SwiftUI`.

The provider should:
- load the latest shared snapshot
- fall back to a neutral placeholder snapshot if nothing exists yet
- produce a timeline with a conservative refresh policy

- [ ] **Step 4: Verify the target graph compiles conceptually**

Confirm the new widget target depends only on shared code and does not import the host app target, so there is no circular dependency.

---

### Task 3: Build the widget views and families

**Files:**
- Create: `Sources/SelenophileWidgetExtension/WidgetCardView.swift`
- Create: `Sources/SelenophileWidgetExtension/WidgetFamilyView.swift`
- Modify: `Sources/SelenophileWidgetExtension/WidgetView.swift`

- [ ] **Step 1: Implement the calm card layout**

Build the widget UI around the approved design:
- soft light background
- rounded card shell
- warm accent progress bar
- strong title and status hierarchy
- compact metadata row

- [ ] **Step 2: Render the three family sizes**

Implement `systemSmall`, `systemMedium`, and `systemLarge` layouts.

Expected differences:
- `systemSmall`: status, title, progress, minimal summary
- `systemMedium`: add nozzle, bed, and remaining time
- `systemLarge`: add layer and speed on top of medium

- [ ] **Step 3: Handle tone-specific styling**

Map `WidgetTone` to accent, muted, danger, and neutral treatments.

- [ ] **Step 4: Support tap-through behavior**

Make the widget open the main app or settings screen when tapped, using a deep link or app URL scheme that the host app can handle.

---

### Task 4: Publish snapshots from the main app and refresh timelines

**Files:**
- Modify: `Sources/SelenophileKit/PrinterStatusStore.swift`
- Modify: `Sources/Selenophile/AppDelegate.swift`
- Modify: `Sources/SelenophileKit/AppConfig.swift`

- [ ] **Step 1: Save snapshots whenever printer status changes**

Whenever the store receives a new printer status or a meaningful state transition, write a fresh `WidgetSnapshot` to the shared store.

- [ ] **Step 2: Trigger WidgetCenter reloads**

After saving a new snapshot, ask WidgetKit to reload timelines for the Selenophile widget kind.

- [ ] **Step 3: Clear widget state on disconnect or configuration reset**

If the user disconnects or removes configuration, write a neutral placeholder snapshot so the widget does not show stale printer data.

- [ ] **Step 4: Ensure the host app still behaves the same**

The menu bar app should continue to manage the live connection and settings window exactly as before; widget publishing is a side effect only.

---

### Task 5: Validate the native widget build

**Files:**
- Modify: any files touched above if test fixes are needed
- Create or modify: widget-specific tests if necessary

- [ ] **Step 1: Run the relevant test suite**

Run the `SelenophileKit` tests and any new widget snapshot tests.

- [ ] **Step 2: Build the app and widget targets**

Run the project build path that exercises both the host app and the WidgetKit extension.

- [ ] **Step 3: Review packaging and entitlement details**

Confirm the App Group identifier, bundle ids, and widget kind string are consistent across the host app and extension.

- [ ] **Step 4: Commit the finished implementation**

Use a focused commit message after the implementation and review loops complete.

