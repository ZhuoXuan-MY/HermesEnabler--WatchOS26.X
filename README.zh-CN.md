# HermesEnabler 2

[English](README.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

![原作者截图](https://raw.githubusercontent.com/pookjw/HermesEnabler/main/image.png)

> 仅支持 watchOS 27.0 至 27.3 beta 1。

## 安装

### 安装 IPA

1. 从 [Releases](https://github.com/pookjw/HermesEnabler/releases) 下载 IPA。
2. 使用 [Sideloadly](https://sideloadly.io) 安装。
3. 在 iPhone 上打开 **Watch（手表）App → 我的手表 → App**，安装 **HermesEnabler2**。
4. 在 Apple Watch 上打开 **HermesEnabler2**，并按照应用中的步骤操作。

### 使用 Xcode 构建

1. 在 Xcode 中打开 [HermesEnabler2.xcodeproj](HermesEnabler2.xcodeproj)。
2. 选择 Apple Watch 作为运行目标，然后点击 **Run**。
3. 在 Apple Watch 上打开 **HermesEnabler2**，并按照应用中的步骤操作。

## 注意事项

- 在 Sideloadly 中关闭 **Use automatic bundle ID**，并使用固定的 Bundle Identifier。每次更新时都使用相同的 Bundle Identifier 和 Apple ID，以便保留现有应用数据和备份。
- 删除应用前，请务必通过 HermesEnabler2 应用恢复 MobileGestalt 备份。

## 致谢

本项目包含来自 [Gester](https://github.com/sasobhabha/Gester) 的代码。

使用风险由您自行承担。

---

## RO23 非官方研究合并版（Ultra 1 / 23U95）

**原生 Hermès 表盘尚未解锁。** 原版由 [Jinwoo Kim（@pookjw）](https://github.com/pookjw/HermesEnabler) 开发；@ZhuoXuan-MY 负责 RO23 实机测试和 [Issue #17](https://github.com/pookjw/HermesEnabler/issues/17) 记录。这不是作者官方提供的 watchOS 26 解锁版。23U95 界面只开放只读研究入口，隐藏受保护缓存写入按钮。[中文研究进度](research/RO23-STATUS.zh-CN.md) · [英文进度](research/RO23-STATUS.md) · [Xcode 编译更新](BUILDING.md)。
