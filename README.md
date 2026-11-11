# HermesEnabler · watchOS 26.x 兼容性研究

**原生 Hermès 表盘研究项目｜Apple Watch Ultra 第一代（Watch6,18 / n199ap）**

**当前状态：BLOCKED — 当前技术路线受阻，尚未实现原生 Hermès 表盘解锁。**

[简体中文](README.zh-CN.md) · [English](#english-summary) · [完整开发记录](#完整开发记录) · [原作者项目](https://github.com/pookjw/HermesEnabler) · [Issue #17](https://github.com/pookjw/HermesEnabler/issues/17)

## 项目简介

我基于 [pookjw/HermesEnabler](https://github.com/pookjw/HermesEnabler)，研究在 **Apple Watch Ultra 第一代、watchOS 26.6.1（23U95）** 上启用原生 Hermès 表盘的可行性。仓库保存了我使用 Mac、Xcode、真实 Apple Watch 和匹配固件开展的测试、源码、分析与失败记录，部分代码及文档由 AI 辅助完成。

**本仓库不是已验证可用的解锁工具，也不提供适用于该设备/固件的成功解锁 IPA。** 项目暂时保留为公开研究档案，而不是删除或宣称所有未来方案都不可能。

| 范围 | 说明 |
|---|---|
| **研究设备** | Apple Watch Ultra 第一代 · `Watch6,18` / `n199ap` |
| **目标系统** | watchOS **26.6.1** · Build **`23U95`** |
| **研究目标** | 让系统真正识别、添加并持续显示**原生** Hermès 表盘 |
| **项目状态** | **BLOCKED — 未解锁，暂停没有新证据的尝试** |
| **研究范围** | MobileGestalt、ClockKit、NanoTimeKit、表盘资格判断与系统权限 |

## 研究结果

| 已验证的事实 | 结果 |
|---|---|
| MobileGestalt 缓存读取 | **成功**；`DeviceBrand` 为 `0`，真实描述符是 **index 103 / offset 0x338 / validity 0x164F**。旧记录中的 index 206 / 0x670 已纠正 |
| 受保护系统文件写入 | **失败**；在本机 `open(O_RDWR)` 返回 **`EPERM`**，Class 13 sandbox extension 也没有赋予写入权限 |
| Hermès 2025 资格 | 对应固件的静态类别检查不接受实测 `deviceCategory=4` |
| Hermès Circulaire / Poodle 资格 | 已验证表盘文件完整，识别为 `com.apple.NTKPoodleFaceBundle`；匹配固件的静态资格函数对实测条件计算为 **restricted** |
| 表盘管理器例外路径 | 已识别为 ClockKit `_CLKIsFaceSnapshotService`，**不是**面向普通设备的通用解锁权限 |
| 原生 Hermès 表盘实际启动 | **未成功，尚无已验证的持续显示结果** |

这些结论来自真实设备只读日志、匹配的 **23U95** 固件和可复现的静态分析。其他机型或 watchOS 27 上的工具结果，不能当成 Ultra 1 / 23U95 已获得权限的证据。

## 为什么暂时停止

现有方法还不能对受保护的手表系统缓存取得写入权限；而且**即使取得写入权限，仍需要独立通过表盘资格和添加检查**。我已经停止重复运行相同的离线探针，不继续发布只有“强制启用”按钮、却不能真正解锁系统的版本。

**恢复研究需要新的实证：** 在同一机型及固件上可复现的有效系统访问路径、修改后的安全读回与持久化，以及在手表上实际添加和显示原生 Hermès 表盘。当前三个目标均未达成。

## 阅读指南

| 内容 | 入口 |
|---|---|
| **V0–V14.1 早期实机操作** | [Issue #17 原始证据及完整复盘](research/RO23-PRE-V14.2-HISTORY.md) |
| **现状、限制与复现边界** | [中文研究状态](research/RO23-STATUS.zh-CN.md) · [English status](research/RO23-STATUS.md) |
| **关键技术研究** | [Poodle 完整资格检查](research/RO23-V24-Poodle-Full-Gate.md) · [ClockKit 能力确认](research/RO23-V25-Poodle-Selector-ClockKit.md) · [受保护写入可行性](research/RO23-V26-WatchOS-Sandbox-Feasibility.md) |
| **外部方案核验** | [EscapeOS v0.3.2](research/RO23-V30-EscapeOS-v0.3.2-Compatibility.md) |
| **构建与历史改动** | [BUILDING](BUILDING.md) · [CHANGELOG](CHANGELOG.md) |
| **原始、未删减的旧版首页** | [旧 README 完整快照](research/ARCHIVE-Full-README-2026-11-11.md) · [旧中文 README](research/ARCHIVE-Full-README.zh-CN-2026-11-11.md) |

> **关于旧代号：** 早期文件和诊断符号使用 `RO23` 作为内部研究记录前缀。它**不是手表型号、watchOS 版本或官方产品名称**。现在项目对外统一称为 **HermesEnabler · watchOS 26.x 兼容性研究**；为保证历史代码、脚本和链接可追溯，已有文件路径中的旧前缀暂不重命名。

## 完整开发记录

我将每次实际测试、代码修改、问题定位与结论保留在下方时间线。**可以展开查看全部 53 条历史记录**，无需在首页首屏阅读所有日志。新增工作也会继续接到这里。

<details>
<summary><strong>展开：V14.2–V30 与后续文档更新（GitHub 提交时间，新 → 旧）</strong></summary>

| 北京时间／来源 | 版本或事项 | 实际工作与结果 | 原始提交／证据 |
|---|---|---|---|
| **23:54** | **项目首页重构（文档维护）** | 对外统一名称为 **HermesEnabler · watchOS 26.x 兼容性研究**，取消以不明内部代号命名的首页；将状态、成果、阻碍与文档导航置于顶部，把全部历史折叠展示。旧版中英 README 已完整归档，同时清理其他语言的过时安装说明。**仅文档修改，手表状态不变。** | [`37db667`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/37db667e79727dbc74ec0568708a5e0483cdf7b0) |
| **23:43** | **项目状态正式调整为 BLOCKED** | 依据 Ultra 1 / `23U95` 已验证的受保护 MobileGestalt 写入 `EPERM`、Class 13 令牌不赋予写权限，以及独立的 Hermès 表盘资格限制，决定**当前路线暂停**。保留 V0–V30 全部研究、源码、日志和 Git 历史，**不删除/归档仓库、不发布假解锁版本**。仅在同型号同固件取得可复现权限与原生表盘成功证据后恢复。此轮仅修改文档，没有对手表采取行动。 | [`fbaa159`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/fbaa1593b44df447b7fdccab8fb839b14a2494d5) |
| **23:28** | **V30：EscapeOS v0.3.2 验证** | 针对我提出的新候选方案检查发布版、`Info.plist`、`AppGroupListing.swift`、`SandboxEscape.swift`、`worse_query.m` 与签名 entitlement。确认它是 **iPhone / iOS 26 App 数据与普通 App Groups 工具**；没有 watchOS 目标，普通 `group.` 容器 ≠ Watch `systemgroup.com.apple.mobilegestaltcache`；未获取 23U95 系统写权限。**无设备试写、无 Hermès 解锁**。[完整核验](research/RO23-V30-EscapeOS-v0.3.2-Compatibility.md)。 | [`db4d4d5`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/db4d4d5e7799c551804ee60fc0938a931e74060b) |
| **23:23** | **V14.2 以前历史重建／文档补录** | 核对 [Issue #17](https://github.com/pookjw/HermesEnabler/issues/17) 原帖及10条评论、早期本仓库诊断记录，补齐 V0、V1–V14.1 各阶段的真实动作与结果；将 Issue 评论的**发布时间**和真实操作时间分开，保留错误 index206→正确 index103 的更正，新增 [前史完整报告](research/RO23-PRE-V14.2-HISTORY.md)。**本次只是补写文档，不是重新运行旧实验。** | [`dddba1a`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/dddba1a65df9000018eed3263598b2636a7b4e1d) |
| **23:15** | **V29.1 Filza / MG 编辑器替代路径核查** | 确认 iPhone 上的 Filza 只能访问其实际获授权的设备文件，不能直接改写独立的 Apple Watch 受保护 `plist`；WorstGestalt 的 iOS 26 成功声明不代表 watchOS 26 成功；配对手表备份包含表盘设置却不能证明可替换 MG 缓存。Apple 官方 watchOS 27 兼容列表**不含 Ultra 1**。因此 23U95 手表端 `EPERM` 写入阻塞仍未解决；本轮没有执行设备写入或解锁。 | [`c5ae0a4`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/c5ae0a47aafd3529a4f68a94e9b0d9c5e9ee80f8) |
| **22:39** | **V29 系统写入权限专项核查：尚未解决** | 对照 `BQCore.m` 既有读写路径与 `worse_query`、Erosion、WatchRegion 的实际源码；确定 Ultra 4 / watchOS 27.3 beta 的系统缓存写入不能直接视为 Ultra 1 / 23U95 可用；`worse_query` 在 iOS 26 无 MobileGestalt 写入能力，公开 watchOS 26.6.1 越狱表无可用工具。**本轮无手表连接、无权限提升、无系统写入、无解锁**；目标仍需真实写入与重启持久化验证。 | [`abfb7d0`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/abfb7d0280a29844cda3cd32f105f0a85a86760d) |
| **22:25** | **V28 强制修改可行性（源码实审）** | 按“强行修改”的要求直接审查 `BQCore.m`，确认 `BQSetHermesEnabled` 的固件白名单**不含 23U95**，而此前真实 `BQSaveGestalt` 受保护写入因 `EPERM` 被系统拒绝。删除 App 版本检查不能获得写权限；决定停用 V27.3 的无效离线任务，未向手表写入，未创建假解锁开关。验收只看真实系统写入、普通原生表盘添加和手表显示。 | [`ddcdd1e`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/ddcdd1e1b51b4cfc0a10454b41a2d4f325933eca) |
| **22:13** | **V27.2 真实 ClockKit 函数解析成功** | 我在 Mac 对真实 Watch6,18 / 23U95 dyld 缓存运行 V27.2，8 项查询均成功。确认 `0x55CE73DC → 0x49C76990 = _CLKIsFaceSnapshotService`，以及 `0x55CE731C → 0x49C2ED64 = _CLKInternalBuild`；两者都在 ClockKit。前者是表盘快照服务谓词，**不能视为普通设备的 Hermès 解锁授权**。按真实函数边界纠正 48 条指令越界误读。未安装/启动表盘。 | [`819bd60`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/819bd6038171e54e870904a0e8b1d5d49efa6a6c) |
| **22:12** | **V27.3 快照服务及表盘添加检查脚本** | 在现有 [PR #1](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/pull/1) 分支新增只读分析：追踪 `_CLKIsFaceSnapshotService` 初始化调用 `0x49C99CFC`，并分别检查 `_NTKCanAddWatchFace` 的配置、可用性、受限表盘判断。**脚本尚未在我的 Mac 上运行**，无任何设备写入。 | [`e30ff95`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/e30ff957822f5a1fd6bbef351533d4ac1cf622cd) |
| **22:05** | **V27.2 真实函数入口追踪脚本** | 根据我实际提供的 23U95 Stub Island 反汇编，新加离线只读脚本，直接检查 `0x49C76990`、`0x49C2ED64` 的所属映像、函数、偏移与前 48 条指令；脚本已提交，**尚未在我的 Mac 上运行**。原生表盘未解锁。 | [`178dfc2`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/178dfc222a70a2fd1eb75a0297dd6e68665449cf) |
| **22:05** | **V27.1 真实固件日志回收** | 我已在 Mac 上执行 V27.1，确认两个地址属于 dsc.18 的 `__TEXT_STUBS` 跳板；`ADRP+ADD+BR` 分别跳往 **`0x49C76990`**（受限表盘例外）及 **`0x49C2ED64`**（内部构建相关）。4 次失败均为 Stub Island 的 `a2f/a2o` 归属查询失败，4 组反汇编成功；未运行 `--extended`，未证明功能解锁。 | [`a19d7c0`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/a19d7c06f1c2c534ebd5ae6796b631d21f30f2ae) |
| **21:57** | **V27.1 离线 Stub 审计工具** | 在独立研究分支增加 `a2s/a2f/a2o/disass` 的只读脚本，同时核对两处 NanoTimeKit 调用位置；准备时只有模拟命令验证，随后才得到我的真实 Mac 结果。代码未合入 `main`，见 [PR #1](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/pull/1)。 | [`5ae5706`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/5ae5706b7b9993852dd21ab6ce533fc997fe672e) |
| **19:28** | **V27 受限表盘特殊跳板追踪** | 保留 V26 的 watchOS 沙箱适配研究；新增只读离线工具检查 NanoTimeKit 的 `0x55CE73DC`（受限表盘例外）与 `0x55CE731C`（内部构建相关）两个不同跳板，使用 `a2f/a2o/disass` 且限制终端输出。尚待 Mac 实测，未修改手表或解锁。 | [`7217f81`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/7217f8131b70be0b2fadc7a3ec347c5dda9bd1ff) |
| **19:21** | **V26 watchOS 沙箱逃逸评估** | 核查 `worse_query` 与 `WatchRegion` 真正源码；发现后者面向 watchOS 27，并声称在 Ultra 4 / 27.3 beta 修改过 MG 地区缓存，但目前 Ultra 1 / 23U95 未验证、RO23 签名无 App Group。未运行漏洞或写系统，仅继续非普通资格路径研究。 | [`a00a01b`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/a00a01b8792bc827e99373b40258ebdec179f524) |
| **18:54** | **V25 Poodle 能力方法解析** | 直接读取已上传的真实 23U95 Zeus 与 ClockKit 二进制：解析 `0x469C0` 为 `supportsPDRCapability:`，核实 ClockKit `0x49C6E724` 始终返回 true；交叉验证 `deviceCategory`、`collectionType` 跳板并新增可复现的只读 Python 工具。Poodle 仍受限，未解锁。 | [`440fc7c`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/440fc7c2e2ff91b608b4fe3a004e464ae12a1ece) |
| **18:41** | **V24 Poodle 完整函数验证** | 成功分析 23U95 原始 Zeus 反汇编，从 51,891 行输出中定位 Poodle 的 29 条指令；证实对 Ultra 1 已测属性，不论额外能力函数返回什么，完整 `isRestrictedForDevice:` 静态逻辑都返回受限制。修复 LLVM/otool 脚本，仅输出目标指令，未解锁。 | [`056cfc7`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/056cfc7b883a9e9fc87f0821c6bffd29df240680) |
| **18:33** | **V23 反汇编工具修复** | 我的 Mac 已成功验证 23U95 Zeus 二进制 SHA-256，但缺少 `llvm-objdump`；修改原 V21 脚本，在 LLVM 不可用时自动使用 Xcode `otool` 并仅打印 Poodle 目标指令。无需重装工具或修改手表。 | [`bf32ec8`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/bf32ec8452e31539f5e3855f9ba760174530c776) |
| **18:24** | **V22.2 实机验证** | 记录 Ultra 1 真正运行 V22：`deviceCategory=4`、`collectionType=9`、`NTKInternalBuild=false`、`NTKShowHardwareSpecificFaces=false`。Poodle 的已知后续分支若执行会受限，但 `NTKPoodleFace` 在诊断进程未注册，完整资格结果尚未知；没有系统写入或解锁。 | [`5314247`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/531424766cc2f3d9462b6d191668869f10c2b224) |
| **18:15** | **V22.1 首页修复** | 修复 V22 按钮找不到的问题：把 **V22 · Poodle eligibility** 移到手表首页第一个操作，放到 V16 长日志之前；增加 `RO23 V22.1 installed` 标记，未改动签名或系统写入。 | [`066dfd1`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/066dfd1a079b6bbc7c05cd7c46700e8cef8d1e22) |
| **18:07** | **V22** | 开发手表首页 `V22 · Poodle eligibility` 按钮：读取真实 ClockKit/NanoTimeKit 属性，计算 Poodle 已知条件分支；仅在类已注册时读取原始资格判断，不加载或安装表盘。尚待 Xcode 实机编译验证。 | [`d9453c1`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/d9453c1fadff007ac933a69f0f3eb2387653964e) |
| **17:55** | **V21** | 对照真实 Circulaire 表盘和 23U95 Zeus 固件，梳理 Poodle 设备限制分支；新增只读反汇编脚本，前置分支仍待验证。 | [`2a87325`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/2a87325d31162c17da1d8d6e25b331a4fb77ec2c) |
| **17:49** | **V20.1** | 解析我上传的 249,760 字节 Hermès Circulaire 文件，全部 ZIP CRC 通过；确认 Bundle ID 为 `com.apple.NTKPoodleFaceBundle`。 | [`8c182a7`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/8c182a7f9e4d71211017cd0082b3ca3d64bb4230) |
| **17:35** | **V20** | 新增本地只读 `.watchface` 分析脚本，读取 ZIP、`face.json`、Bundle ID、SHA-256，并研究导入错误分类。 | [`315db1c`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/315db1cd08939e4bffe7fb51d1f0fde0a16979c0) |
| **17:28** | **V19.4** | 记录 `CreateWatchFace` 组件的 `UltraFaceWasAddedToLibrary=YES` 及两个缓存构建号，未修改配置文件。 | [`3f4b98c`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/3f4b98c940cea5a8839ee3b876bd38d3ead25c24) |
| **17:24** | **V19.3** | 读取 iPhone Watch 容器中的 `com.apple.ClockKit.plist`，确认唯一键 `HandFactoryCachedBuild=24B5089g`。 | [`f4c60a8`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/f4c60a84e282d5ae30d6fcf843c0f347e90a1188) |
| **17:21** | **V19.2** | 整理 Filza 实机目录：Bridge 的 `Library/Preferences`、`SyncedPreferences`、`Application Support`，识别敏感同步令牌路径。 | [`557565d`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/557565d264553b17f1ba83dbaa61723d7ab7e0a2) |
| **17:13** | **V19.1** | 审计已上传的 Filza 27.2.2 源码，并核实 iPhone 可列出 `com.apple.Bridge` 数据容器；提示 WebDAV/SSH 风险。 | [`d22a7de`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/d22a7dee6215de180eb925c1d4f25ed09d1c439b) |
| **16:55** | **V19** | 比较 iOS 26 `worse_query` 容器访问范围与 iPhone–Watch 配对、表盘同步路径，未证明手表系统写入权限。 | [`c97e1da`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/c97e1daa80d10faf850e7455e67096b6c7c69e2f) |
| **16:44** | **V18** | 定位受限制表盘查找中的额外判断 `0x55CE73DC`，确认其身份尚未解析，添加离线符号追踪说明。 | [`8fee633`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/8fee633be877108bdad637780f54f41e71ddaa30) |
| **16:37** | **V17** | 梳理 NanoTimeKit 表盘注册、按 Bundle ID/旧 Style 查找及 `_NTKCanAddWatchFace` 的独立准入检查。 | [`7440080`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/74400800cb412b48ec1bfba5b680374f6518fc5c) |
| **15:56** | **V16 实机记录** | 记录我在 Ultra 1 上测得的 `NTKInternalBuild=false`、`NTKShowHardwareSpecificFaces=false`、`NTKShowInternalFaces=false`。 | [`fe5d177`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/fe5d17798c3c4a07995fb90094d3d09197f59749) |
| **15:42** | **V16.1** | 修正 V16 检测入口：将按钮和版本标记直接放到手表 App 首页，避免只能在二级页面找到。 | [`11e835f`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/11e835f23bbc807d57a6484c3f70514e116341f3) |
| **15:37** | **V16** | 新增 `_NTKInternalBuild` 只读检测，并补充 Poodle、Bellona 与硬件专属表盘判断的静态分析。 | [`51fe35e`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/51fe35e1db3880789c022f1552331e5b2ff28e18) |
| **15:27** | **V15** | 将 V13、V14.1、MobileGestalt 缓存的实机日志写入研究记录，分析 NanoTimeKit 的内部前置条件。 | [`b7d33b6`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/b7d33b6b88a46e5bf97f562869ddea148bf21a09) |
| **15:07** | **V14.2.1** | 修复 `Boolean` 与系统类型命名冲突（改为 `RO23ReadBool`），移除无法使用的占位 App Group entitlement。 | [`ebc7693`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/ebc7693db5bb3fc34a59a726015df8f14cd2ea44) |
| **14:58** | **资源修复** | 修复 Watch 与 iPhone Companion 的图标资源构建问题，使用可编译占位图标（非原始图标）。 | [`e2bb4d4`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/e2bb4d4323dead5d241ba45f2f3a60da504a9097) |
| **14:55** | **V14.2 合并** | 合并上游 HermesEnabler 2 工程、Watch App 和 iPhone Companion；加入 V13/V14.1/MG 只读诊断与 23U95 界面保护。 | [`bfa6f12`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/bfa6f1240ee3241cacd364749d98fb05e4c2bfb1) |

</details>

<details>
<summary><strong>展开：V0–V14.1 早期研究（Issue #17 报告时间，新 → 旧）</strong></summary>

这里的具体分钟是 **Issue #17 发帖/评论的发布时间**，不是每次实机测试的实际分钟，也不是当时的 Git 提交时间。V14 / V14.1 的精确执行时刻没有足够证据。

| 北京时间／来源 | 版本或事项 | 实际工作与结果 | 原始提交／证据 |
|---|---|---|---|
| **14:55 前／时间未核实** | **V14.1 · Brand 返回类型修复** | 原始 Zeus 只读诊断把 ObjC 对象指针误当 int，曾报出 `399803152` 等假值；改为读取 `__NSCFNumber`，真实 `deviceBrand=0`，不是改品牌成功。 | [研究摘要](research/RO23-STATUS.zh-CN.md) |
| **14:55 前／时间未核实** | **V14 · Zeus 专属表盘判断** | 研究 Zeus Analog、Spectrum、Hades/Secretariat 相关门槛；实机 `isZeusBlack=false`、`NTKShowHardwareSpecificFaces=false`，检查结果为受限，未启用任何原生表盘。 | [研究摘要](research/RO23-STATUS.zh-CN.md) |
| **13:46（Issue 发布）** | **V13 · Hermes2025 分类** | 从 23U95 Hermes2025/ClockKit 反汇编得到类别白名单 `{2,3,5}`；Ultra 1 实测 `sizeClass=6`、`category=4`、`collectionType=9`、`brand=0`、`isUltra=true`，类别不合格。 | [Issue #17](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6788186063) |
| **05:27（Issue 汇总）** | **V12 · ClockKit 对照** | 提取真实 23U95 `ClockKit`（1,425,840 B）并核查 `CLKDevice` 的 Brand/Category/Collection/Ultra getter 和 NanoRegistry 能力路径；只是静态检查，未修改手表。 | [Issue #17](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6779723360) |
| **05:27（Issue 汇总）** | **V11 · NanoTimeKit 门槛** | 提取匹配 `NanoTimeKit`（11,395,800 B），分析 FaceBundle Manager、`_NTKFaceStyleIsAvailable`、Hermes2025 `isRestrictedForDevice:`，证明存在多重准入检查。 | [Issue #17](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6779723360) |
| **05:27（Issue 汇总）** | **V10 · 固件含原生表盘** | 从 23U95 OTA 清单及文件中找到 `NTKHermes2025FaceBundle`、Carousel、ClockFace、nanotimekitd；证明代码存在，**不等于设备可使用**。 | [Issue #17](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6779723360) |
| **04:25（Issue 发布）** | **V9 · MG Helper 错误9逆向** | 从目标 dyld 缓存取得 991,764 B 的 `libMobileGestalt`，定位 `_MGServerCopyAnswerWithError` 和描述符检查；解释 V7 `error=9` 的静态原因，并二次核实 Brand index103。 | [Issue #17](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6778385658) |
| **04:05（Issue 发布）** | **V8 · 23U95 OTA + Helper** | 取得匹配 Watch6,18 的 3.76 GB AEA OTA，核查 BOM，提取 76,112 B `MobileGestaltHelper`，用 LLVM 解决 arm64_32 反汇编障碍，确认其调用 Server API；无系统写入。 | [Issue #17](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6777949079) |
| **03:28（Issue 发布）** | **V7 · XPC 四问** | 本地 `MGCopyAnswer` 可读 Brand 明文/哈希、BuildVersion、ProductType；Helper XPC **四项全返回 `error=9` 且没有 answer**，与 `EPERM` 不同。 | [Issue #17](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6777128180) |
| **03:28（Issue 发布）** | **V6 · 首次 Helper XPC** | 连接 `com.apple.mobilegestalt.xpc`，向 `getServerAnswerForQuestion:reply:` 只读询问 DeviceBrand；收到 `error=9`、无 answer，没有重建缓存。 | [Issue #17](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6777128180) |
| **03:28（Issue 发布）** | **V5 · Mach Service 查找** | 通过 bootstrap API 找到 `com.apple.mobilegestalt.xpc`，`kr=0` 且有有效 send right；只能证明服务可访问到，非系统写权限。 | [Issue #17](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6777128180) |
| **11/10 23:20（Issue 发布）** | **V4 · Class 13 权限差异** | 普通 App Group 存在、Apple 私有 SystemGroup entitlement 缺失；Class13 **token取得并激活 (`handle=2`)**，但 MG 写入/创建前后仍 DENY；此轮没有系统写入。 | [Issue #17](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6771229913) |
| **11/10 23:20（Issue 发布）** | **V3 · 更正 DeviceBrand** | 发现前版误读相邻记录：真正 `flags=12`、`index=103`、`type=5`、值 `0x338`、presence `0x164F`；**废弃错误206/0x670**。 | [Issue #17](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6771229913) |
| **11/10 23:20（Issue 发布）** | **V2 · MGCopyAnswer 类型** | 修正两参数 API 调用，直接查 DeviceBrand 明文与哈希，均得 **CFNumber(0)**；验证不是把 CF 类型当 MG 内部类型。 | [Issue #17](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6771229913) |
| **11/10 23:20（Issue 发布）** | **V1 · 实机 Mach-O 只读扫描** | 搜索 `libMobileGestalt` 中 DeviceBrand 哈希与引用，找到真实键；最初描述符边界分析有误，后来 V3 修复。 | [Issue #17](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6771229913) |
| **11/10 19:57（Issue 创建）** | **最初本地实验 · V0** | 改版 HermesEnabler2 安装到 Ultra 1、配置 App Group、MG 只读读取 **13,328 B**、按 23U95 重新备份；强制写入 `open(O_RDWR)` **EPERM**；Geod-MCM 无容器，Class7 三种 flags **NO TOKEN**。 | [Issue #17](https://github.com/pookjw/HermesEnabler/issues/17) |

</details>

## 研究归属与授权

HermesEnabler 原项目由 **[Jinwoo Kim（@pookjw）](https://github.com/pookjw/HermesEnabler)** 开发。本仓库的 Apple Watch Ultra 1 / watchOS 26.6.1 实机研究及 [Issue #17](https://github.com/pookjw/HermesEnabler/issues/17) 记录由 **[@ZhuoXuan-MY](https://github.com/ZhuoXuan-MY)** 维护，部分代码与文档含 AI 辅助。保留上游许可及第三方声明：[LICENSE](LICENSE) · [NOTICE](NOTICE.md)。

本研究与 Apple 或 Hermès 无官方关联，**不保证解锁、安全性或兼容性**。

## English summary

**HermesEnabler — watchOS 26.x Compatibility Research**

This repository documents my attempt to enable **native Hermès watch faces** on a first-generation Apple Watch Ultra (`Watch6,18 / n199ap`) running **watchOS 26.6.1 (`23U95`)**.

**Status: BLOCKED, NOT UNLOCKED.** The protected MobileGestalt cache was readable, but opening it for write returned **`EPERM`**. Matching-firmware static analysis also identified independent Hermès 2025 and Circulaire/Poodle eligibility restrictions. No persistent native Hermès activation has been demonstrated. The current route is paused, not declared impossible for all future discoveries.

I have preserved the complete development history above, source code, authentic device observations, and upstream provenance. Earlier research files may carry the legacy `RO23` internal prefix; it does not indicate a device or OS version. See [the full archived bilingual README](research/ARCHIVE-Full-README-2026-11-11.md) for the unabridged technical narrative.

**Original project:** [Jinwoo Kim / pookjw](https://github.com/pookjw/HermesEnabler). **Ultra 1 research:** [ZhuoXuan-MY](https://github.com/ZhuoXuan-MY), with AI-assisted documentation. This is an unofficial research archive and **not a working unlock**.
