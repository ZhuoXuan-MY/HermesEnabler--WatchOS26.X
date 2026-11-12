# HermesEnabler 1.5 — watchOS 27.0 模拟器运行记录与界面预览补丁

> **适用项目：** 原作者 [pookjw/HermesEnabler](https://github.com/pookjw/HermesEnabler) **1.5**（不是本仓库的 Ultra 1 / watchOS 26.6.1 研究版本）。  
> **运行环境：** Xcode 中的 Apple Watch Ultra 3（49 mm）Simulator，watchOS 27.0。  
> **进度：** 针对原作者源码制作了模拟器专用 UI 预览补丁，**已上传并核对与 1.5 标签的原始文件一致；没有在 Xcode 编译或在模拟器安装验证**。  
> **安全边界：** 仅预览 UI，**不提供模拟器 MobileGestalt 权限、备份、系统修改或原生 Hermès 解锁**。原作者 1.5 的真机代码不变。

## 事情经过：实际做了什么

1. **原作者 1.5 更新核查。** 我先比较上游 [HermesEnabler 1.5](https://github.com/pookjw/HermesEnabler/releases/tag/1.5)、`BQCore.m`、[PR #51](https://github.com/pookjw/HermesEnabler/pull/51) 和 [PR #52](https://github.com/pookjw/HermesEnabler/pull/52)，确认上游新增 watchOS 27.2 beta 1 适配、备份管理与写入核验，但没有提供 Ultra 1 / `23U95` 已验证的写入通路。另有独立记录：[上游 1.5 兼容性核查](Upstream-HermesEnabler-v1.5-Compatibility.md)。
2. **在 Xcode 模拟器运行的是原作者项目。** 我提供的截图显示 Xcode 正在运行 `HermesEnabler2`，目标为 **Apple Watch Ultra 3 Simulator / watchOS 27.0**；模拟器中的弹窗为 `MobileGestalt 存取失敗`，提示可能缺少 App Group ID 或 watchOS 不兼容。
3. **进一步提供控制台截图。** 运行日志出现 `[bqtool] escape: all strategies failed (last=-5)`，目标路径为 `.../SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches`。附近的 `CoreUI: No theme registered` 和 `cannot add handler` 不足以证明是 MobileGestalt 访问失败的根因。截图没有证明原作者项目在真实 watchOS 27 手表上失败。
4. **先前错误地处理了另一个仓库。** 最初将模拟器 UI 防护提交到了本仓库的 `HermesEnabler2/ContentModel.swift`（[`27085063`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/27085063c1a7d86f21016e8544038912f74986c6)）及 `ContentView.swift`（[`c5b44149`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/c5b44149ee62dd3aa9165c95704eaa26977cdbd8)）。确认项目不符后已**分别恢复原文件**（[`0cb47be`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/0cb47be30332ae8d4c9e15ae4dbd6bfa121e9f88)、[`314ff4d`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/314ff4d8c57398bea77d254ac2da4ef623b29cf4)）。**本仓库原有 Ultra 1 研究界面和功能未被这个补丁取代。**
5. **回到原作者 HermesEnabler 1.5。** 我读取上游 `1.5` 标签的 `HermesEnabler2/ContentView.swift`，发现首页使用 `ContentModel` 判断备份、激活时调用 `refreshBackups()` 和 `refreshCapabilityStates()`；点击 `Create Initial Backup` 会请求实际的受保护 MobileGestalt 访问。该路径对模拟器并未提供只浏览 UI 的特殊处理。
6. **生成单文件模拟器预览补丁。** 在原作者 `ContentView.swift` 上添加编译期 `#if targetEnvironment(simulator)` 分支：模拟器直接进入模拟 UI 页面，功能区可导航，开关禁用，备份页只显示不可使用说明；不建立 `ContentModel`、不触发 MobileGestalt 查询／备份／写入／respring。正常真机代码保留在 `#else` 分支。**这不是修复原生系统权限，而是避免用模拟器错误判断真机功能。**
7. **代码匹配核验。** 补丁使用的原作者 `1.5` 源文件 SHA（Git blob）为 `951eb9aeb56f4860a0e52b5221770a2763f6d0a9`；生成补丁时逐行比较原文件，补丁包含原文件 **77 行**及修改后 **173 行**。检查了 Swift 编译条件配对和入口一致性。**尚未通过 Xcode 编译、模拟器运行或实机测试。**

## 已上传 GitHub 的文件

| 文件 | 内容和使用方式 |
|---|---|
| [`patches/HermesEnabler-1.5-watchOS-Simulator-UI-Preview.patch`](../patches/HermesEnabler-1.5-watchOS-Simulator-UI-Preview.patch) | 原作者 1.5 的 `git apply` 补丁，只修改上游 `HermesEnabler2/ContentView.swift` |
| [`patches/upstream-1.5/ContentView.swift`](../patches/upstream-1.5/ContentView.swift) | 补丁应用后的**完整 Swift 源码**，方便查看差异、手动对照；**不要误放进本仓库 Ultra 1 研究工程** |
| [本研究记录](Upstream-HermesEnabler-v1.5-Simulator-Preview.md) | 截图内容、错误、之前的误修改与恢复、后续验证步骤 |

**两个项目不要混用：** 本仓库已有的 `HermesEnabler2/ContentView.swift` 属于我的 watchOS 26 研究项目；上面 `patches/upstream-1.5/ContentView.swift` 属于原作者 1.5 的**可选模拟器 UI 补丁**。没有向 `pookjw/HermesEnabler` 仓库提交修改。

## 在 Mac 上应用（仅原作者 1.5 源码）

首先进入本地 **pookjw/HermesEnabler 1.5 项目根目录**，也就是能找到 `HermesEnabler2/ContentView.swift` 的那个文件夹。以下命令从我的研究仓库下载补丁并在应用前检查版本／本地改动，检查失败则不修改源码：

```bash
PATCH_FILE="$PWD/HermesEnabler-1.5-Simulator-UI-Preview.patch"
curl -fL --retry 2 \
  "https://raw.githubusercontent.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/main/patches/HermesEnabler-1.5-watchOS-Simulator-UI-Preview.patch" \
  -o "$PATCH_FILE"

git apply --check "$PATCH_FILE" && git apply "$PATCH_FILE"
```

随后在 Xcode 里选 **Apple Watch Ultra 3 / watchOS 27.0 Simulator**，执行 **Product → Clean Build Folder**，重新运行。**预期**打开 `Simulator Preview`，可以浏览只读界面，不再要求先建立 MobileGestalt 备份；这仍是需要真实 Xcode 输出核实的预期，而不是我已亲自验证过的运行结果。

如果要撤销这一个补丁，在同一上游项目根目录执行：

```bash
git apply -R "$PWD/HermesEnabler-1.5-Simulator-UI-Preview.patch"
```

## 与原来的 Ultra 1 项目是什么关系？

我的目标设备仍是 **Apple Watch Ultra 第一代 `Watch6,18` / watchOS 26.6.1 `23U95`**。已完成的 MobileGestalt 只读诊断、`EPERM` 写入失败、表盘资格判断和 V0–V30 历史都在 [本仓库中文 README](../README.zh-CN.md) 中。这个**原作者 1.5 的模拟器 UI 补丁没有改变**上述结论，项目仍是 **BLOCKED — 原生 Hermès 未解锁**。

> **记录规范：** 保留截图所证实的模拟器环境和日志；本次修改源文件、生成补丁的 GitHub commit 时间只表示提交时间，不冒充 Xcode 实测时间；后续若执行验证应另行记录真实输出与构建结果。
