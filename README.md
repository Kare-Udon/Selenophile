# Selenophile

Selenophile 是一个面向 Moonraker / Klipper 的 macOS 菜单栏应用，用来查看打印状态、连接状态和相机相关信息，并提供设置与调试日志入口。

## 项目特性

- 菜单栏常驻运行
- 连接 Moonraker 后实时显示打印状态
- 支持相机快照获取与状态展示
- 提供设置窗口和调试日志窗口
- 内置自动重试与日志记录能力

## 仓库结构

- `Sources/Selenophile/`：应用层 UI、窗口和菜单栏控制逻辑
- `Sources/SelenophileKit/`：核心数据模型、网络客户端和状态管理
- `Tests/`：单元测试
- `Scripts/`：构建、打包和启动脚本
- `Selenophile.xcodeproj/`、`Selenophile.xcworkspace/`：Xcode/Tuist 生成的工程入口
- `docs/`：项目设计文档和实施计划

## 本地开发

### 生成工程

如果你使用 Tuist：

```bash
tuist generate --no-open
```

### 运行测试

```bash
swift test
```

### 启动应用

```bash
./run-menubar.sh
```

停止应用：

```bash
./stop-menubar.sh
```

## 初始提交建议

适合提交到 git 的内容：

- 源码：`Sources/`
- 测试：`Tests/`
- 工程定义：`Package.swift`、`Project.swift`、`Tuist.swift`
- Xcode / Tuist 工程文件：`Selenophile.xcodeproj/`、`Selenophile.xcworkspace/`
- 脚本：`Scripts/`、`run-menubar.sh`、`stop-menubar.sh`
- 配置与文档：`version.env`、`docs/`、`README.md`

不建议提交的内容：

- 构建产物：`.build/`、`Derived/`、`Selenophile.app/`
- 本地状态：`.DS_Store`、`xcuserdata/`、`*.xcuserstate`
- 本地协作缓存：`.codex/`、`.superpowers/`

## 许可证

当前仓库尚未添加许可证文件，如需开源发布，建议补充 `LICENSE`。
