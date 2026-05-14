# Selenophile

[English](README.md) | [简体中文](README.zh-Hans.md) | [日本語](README.ja.md)

面向 Klipper 打印机的原生 macOS 菜单栏监控工具。

Selenophile 会把 Moonraker / Klipper 打印机的当前状态放在 macOS 菜单栏里。它专注于监控而不是控制：快速查看状态、实时进度、温度、时间、层数、速度、相机快照，以及用于排查连接问题的日志。

<p>
  <img src="docs/assets/readme/menu-popover.jpg" alt="Selenophile 菜单栏弹窗显示 Klipper 打印状态" width="420">
</p>

## 亮点

- 原生 macOS 菜单栏应用，弹窗紧凑清晰。
- 通过 Moonraker 实时读取 Klipper 打印状态。
- 显示打印进度、文件名、已用时间、剩余时间、层数、速度、喷嘴温度和热床温度。
- 支持可选相机快照预览，可使用 Moonraker 主机上的相对路径或完整图片 URL。
- 支持连接设置、刷新频率、登录启动、界面语言、外观模式和配色方案。
- 提供连接、重试、状态更新和相机请求相关调试日志。
- 面向 Apple Silicon Mac，要求 macOS 14 或更高版本。

## 截图

| 连接设置 | 通用设置 |
| --- | --- |
| <img src="docs/assets/readme/settings-connection.jpg" alt="Moonraker 连接设置" width="420"> | <img src="docs/assets/readme/settings-general.jpg" alt="语言、刷新频率和登录启动设置" width="420"> |

| 外观设置 |
| --- |
| <img src="docs/assets/readme/settings-appearance.jpg" alt="主题和配色设置" width="620"> |

## 系统要求

- Apple Silicon Mac。
- macOS 14 或更高版本。
- 已启用 Moonraker 的 Klipper 打印机。

## Moonraker 设置

从菜单栏弹窗打开 **Settings**，填写 Moonraker 连接信息。

- **Moonraker URL**：通常是 `http://printer.local:7125` 或 `http://<printer-ip>:7125`。
- **API Token**：可选。大多数本地 Moonraker 安装默认不需要 token，只有启用认证时才需要填写。
- **Camera Snapshot URL**：可选。可以使用完整 URL，例如 `http://printer.local/webcam/?action=snapshot`；也可以使用 Moonraker 主机上的相对路径，例如 `/webcam/?action=snapshot`。

保存前可以使用 **Test Connection** 验证 URL 和 token。

## Selenophile 不做什么

Selenophile 是监控工具，不是打印控制工具。它不会上传 G-code、开始打印、暂停打印、取消打印，也不会修改 Klipper 配置。这些操作应继续在你现有的打印机 UI 中完成。

## 语言

应用界面支持多语言。README 提供英文、简体中文和日文版本。

## 从源码构建

克隆仓库后，可以用 Swift Package Manager 构建：

```bash
swift build
```

运行测试：

```bash
swift test
```

本地启动菜单栏应用：

```bash
./run-menubar.sh
```

构建本地 app 包：

```bash
./Scripts/build_dmg.sh
```

Xcode 工程由 Tuist 维护。如果你本地使用 Tuist：

```bash
tuist generate --no-open
```

发布和更新分发说明见 [docs/sparkle-github-distribution.md](docs/sparkle-github-distribution.md)。

## 贡献

欢迎提交 issue 和 pull request。代码改动应保持菜单栏应用专注于监控，并在提交前运行相关 Swift 测试。

## 许可证

Selenophile 使用 [MIT License](LICENSE) 发布。
