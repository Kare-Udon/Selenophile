# Selenophile Appearance Theme System Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` or `superpowers:executing-plans` to implement this plan task-by-task. Track progress by updating checkbox (`- [ ]`) items in place.

**Goal:** 在设置菜单的“外观”页中加入主题选择能力，先支持系统默认、浅色、深色三种主题模式，并保持当前深色主题为默认视觉体验。暂不扩展多套配色风格，只把后续配色扩展所需的主题模型、token 解析、持久化和 UI 注入链路搭好。

**Architecture:** 新增独立的外观偏好模型和 store，不继续把 UI 偏好塞进 Moonraker 连接配置。`SelenophileTheme` 从静态 dark token 改为可根据主题模式解析的 token provider；主菜单、设置窗口、日志窗口和调试主面板继续复用同一套主题环境。SwiftUI 层使用 `preferredColorScheme(_:)` 控制窗口/弹出层的浅深外观，具体业务颜色通过主题 token 读取，避免各视图直接判断 light/dark。

**Tech Stack:** Swift 6.2, SwiftUI, AppKit, Observation, UserDefaults, Swift Testing, Swift Package Manager, Tuist/Xcode project

**References:**
- Apple SwiftUI `ColorScheme`: https://developer.apple.com/documentation/swiftui/colorscheme
- Apple SwiftUI `colorScheme` environment: https://developer.apple.com/documentation/swiftui/environmentvalues/colorscheme
- Apple SwiftUI `AppStorage`: https://developer.apple.com/documentation/SwiftUI/AppStorage
- Current theme entry: `Sources/Selenophile/SelenophileTheme.swift`
- Current settings shell: `Sources/Selenophile/SettingsView.swift`
- Current app state pattern: `Sources/Selenophile/AppLanguageStore.swift`

---

## Scope

- [x] 支持 `system` / `light` / `dark` 三种主题模式。
- [x] 当前默认视觉仍等同深色主题；旧用户无外观偏好时不发生突然变亮。
- [x] “外观”页从 placeholder 变成可保存、可预览的主题选择 UI。
- [x] 为后续多配色风格保留扩展点，但本轮不实现 palette/style 选择。
- [x] 不改变默认产品入口：仍是 `NSStatusItem + NSPopover`，调试窗口继续显式 opt-in。

## Non-Goals

- [x] 不新增完整 palette marketplace 或多套品牌配色。
- [x] 不重做设置页导航和整体 redesign。
- [x] 不把主题设置同步到 Widget，除非实现时发现当前 Widget 直接依赖 app theme；本轮先保持 Widget 独立。
- [x] 不修改 `run-menubar.sh`、启动参数或调试窗口开关。

---

## Milestone 1: 建立可测试的主题偏好模型

**Goal:** 把“用户选择的主题模式”和“当前实际生效的浅深主题”变成集中模型，后续 UI 只依赖这个模型。

**Files:**
- Create: `Sources/SelenophileKit/AppAppearanceMode.swift`
- Create: `Tests/SelenophileKitTests/AppAppearanceModeTests.swift`
- Modify as needed: `Package.swift`

- [x] Step 1: 写失败测试，锁定 raw value、Codable 兼容和系统模式解析行为。
- [x] Step 2: 新增 `AppAppearanceMode: String, CaseIterable, Codable, Sendable`，包含 `.system`, `.light`, `.dark`。
- [x] Step 3: 提供 `preferredColorScheme` 映射：`system -> nil`, `light -> .light`, `dark -> .dark`。
- [x] Step 4: 提供本地化 display key，不在视图里硬编码 `Light` / `Dark`。

**Validation:**
- `swift test --filter AppAppearanceMode`

**Risk:**
- `ColorScheme` 属于 SwiftUI；如果 `SelenophileKit` 不应依赖 SwiftUI，则模型只暴露中立枚举，`preferredColorScheme` 映射放在 app target extension。

---

## Milestone 2: 独立持久化外观偏好

**Goal:** 新增轻量外观 store，避免继续扩大 `MoonrakerConfiguration` 的职责。

**Files:**
- Create: `Sources/Selenophile/AppAppearanceStore.swift`
- Create: `Tests/SelenophileTests/AppAppearanceStoreTests.swift`
- Modify: `Sources/Selenophile/AppDelegate.swift`
- Modify: `Sources/Selenophile/SelenophileApp.swift`

- [x] Step 1: 定义 `AppAppearanceStore`，参考 `AppLanguageStore` 使用 `@Observable` 暴露 `selectedMode`。
- [x] Step 2: 用 `UserDefaults` 独立 key 持久化，缺省为 `.dark`，保证当前体验不变。
- [x] Step 3: 在 `AppDelegate` 初始化并注入菜单、设置、日志、调试主面板窗口。
- [x] Step 4: 保存后立即更新现有打开窗口；取消设置页预览时恢复已持久化值。

**Validation:**
- `swift test --filter AppAppearanceStore`
- `swift build`

**Risk:**
- 设置窗口和菜单 popover 是 AppKit 承载的 SwiftUI view，store 注入点必须覆盖 `NSHostingController(rootView:)` 的每一次重建。

---

## Milestone 3: 让主题 token 可解析 light/dark

**Goal:** 把 `SelenophileTheme.Colors` 从单套静态深色 token 改成基于当前主题解析的 token，同时尽量减少调用侧改动。

**Files:**
- Modify: `Sources/Selenophile/SelenophileTheme.swift`
- Modify: `Sources/Selenophile/MenuContentView.swift`
- Modify: `Sources/Selenophile/SettingsView.swift`
- Modify: `Sources/Selenophile/LogView.swift`
- Modify as needed: `Sources/Selenophile/MainPanelWindowController.swift`, `Sources/Selenophile/MenuBarStatusController.swift`

- [x] Step 1: 新增 `SelenophileTheme.Palette` 或 `SelenophileTheme.Tokens`，包含现有 dark token 和新增 light token。
- [x] Step 2: 建立 `EnvironmentKey` 或 view modifier 注入当前 tokens。
- [x] Step 3: 先迁移 `SelenophileWindowBackground`、card、button、textfield 这些共享组件。
- [x] Step 4: 再迁移 `MenuContentView`、`SettingsView`、`LogView` 中直接引用的 token。
- [x] Step 5: light token 先做可用的中性浅色版本：白/浅灰背景、深色文本、保留当前橙色 accent。

**Validation:**
- `swift build`
- 人工检查：深色模式与当前视觉接近；浅色模式文本、边框、输入框、反馈 banner 对比度可读。

**Risk:**
- 当前很多视图直接引用 `SelenophileTheme.Colors.*`。如果一次性全量迁移太大，先保留同名 facade，让 facade 读取环境 token，分批替换调用点。

---

## Milestone 4: 实现“外观”设置页

**Goal:** 把空的“外观”页替换成主题选择 UI，支持预览、保存和取消恢复。

**Files:**
- Modify: `Sources/Selenophile/SettingsView.swift`
- Modify: `Sources/SelenophileKit/AppLocalization.swift`
- Modify: `Sources/SelenophileKit/Resources/*/Localizable.strings`
- Modify: relevant tests under `Tests/SelenophileTests/`

- [x] Step 1: 给 `SettingsView` 增加 `appearanceStore`、`selectedAppearanceMode` 和预览/取消回调。
- [x] Step 2: 在 `.appearance` section 中添加主题模式选择控件，优先用 segmented picker 或 radio-style rows。
- [x] Step 3: 选择时即时预览；点 Save 后持久化；关闭/取消时恢复持久化值。
- [x] Step 4: 增加本地化 key：外观说明、跟随系统、浅色、深色、当前默认说明。
- [x] Step 5: 补齐中文文案；其他语言可先用英文占位，避免缺 key 回退。

**Validation:**
- `swift test --filter AppLocalization`
- `swift test --filter AppAppearanceStore`
- `swift build`

**Risk:**
- 现有设置页的 Save 同时保存 Moonraker 配置。外观设置不能因为连接配置无效而无法保存；实现时应允许外观偏好单独保存，或明确拆分保存路径。

---

## Milestone 5: 窗口级浅深外观验证与收口

**Goal:** 确认主题选择对 menubar popover、设置窗口、日志窗口和调试主面板都生效，并且不破坏现有启动/调试链路。

**Files:**
- Modify as needed: `Sources/Selenophile/AppDelegate.swift`
- Modify as needed: `Sources/Selenophile/MainPanelWindowController.swift`
- Modify as needed: `Sources/Selenophile/MenuBarStatusController.swift`
- Modify as needed: `README.md` only if user-facing behavior needs说明

- [x] Step 1: 对每个 `NSHostingController` root view 应用统一的 theme environment 和 `preferredColorScheme(_:)`。
- [x] Step 2: 打开设置窗口切换主题，确认已打开日志窗口/调试面板能更新或在重新打开后正确更新。
- [x] Step 3: 跑默认验证：`swift build`。
- [x] Step 4: 如涉及调试窗口链路，按仓库规则补跑 `swift test --filter AppLaunchConfiguration`。
- [x] Step 5: 若改到打包/menubar 脚本链路，补跑 `./Tests/build_dmg_test.sh`；本计划默认不触碰这部分。

**Manual Smoke Test:**
- [x] `./run-menubar.sh`
- [x] 打开 Settings -> Appearance，选择 Light，保存，关闭再打开仍为 Light。
- [x] 选择 Dark，保存后主 popover 和设置窗口回到当前深色视觉。
- [x] 选择 System 时，解析为 macOS 当前外观对应的明确 light/dark，避免从 Light 切回 System 后内容区停留亮色。
- [ ] 无初始 Moonraker 配置时仍能打开设置并修改外观。

---

## Definition of Done

- [x] 外观页不再显示 `settingsNoAdditionalOptions` placeholder。
- [x] 用户可以保存 `system` / `light` / `dark` 主题模式。
- [x] 默认值保持深色，现有用户体验不突变。
- [x] 设置保存、取消、关闭窗口恢复行为清晰且有测试覆盖。
- [x] 主题 token 支持 light/dark，调用侧不散落 ad-hoc `if colorScheme == ...`。
- [x] 中文、繁中、本地化 key 不缺失；其他语言至少有英文占位。
- [x] `swift build` 通过；新增模型/store 测试通过。

## Follow-Up After This Plan

- [ ] 在主题系统稳定后，再新增 `AppColorPalette` 或 `AccentStyle`，支持多种配色风格。
- [ ] 考虑把 Widget 也接入共享外观偏好，但需要先判断 Widget 是否应跟随 app 设置还是系统外观。
- [ ] 如外观偏好和语言偏好继续增长，再评估是否建立统一 `AppPreferencesStore`，把语言从 `MoonrakerConfiguration` 中迁出并做兼容迁移。
