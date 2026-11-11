# RO23 开发日志｜Apple Watch Ultra 1 · 23U95

**研究进度截至：2026-11-11 22:05（北京时间，UTC+08:00）**  
**研究设备：** Apple Watch Ultra 第一代（Watch6,18 / n199ap）· watchOS 26.6.1（23U95）  
**当前结果：原生 Hermès 表盘尚未解锁。**

这里按**实际 GitHub 提交时间**记录我们对 RO23 衍生项目的每次修改、验证资料的入库和技术判断。以下“几点几分”来自 GitHub commit 的 UTC 时间换算为北京时间；**不是声称在该分钟直接操作、刷写或测试了你的手表**。实际手表诊断由设备所有者运行，源码与报告修改有 AI 辅助。

## 2026 年 11 月 11 日｜逐分钟开发记录（新 → 旧）

| 时间（北京时间） | 版本 | 具体做了什么 | GitHub 提交 |
|---|---|---|---|
| **22:05** | **V27.2 真实函数入口追踪脚本** | 根据你实际提供的 23U95 Stub Island 反汇编，新加离线只读脚本，直接检查 `0x49C76990`、`0x49C2ED64` 的所属映像、函数、偏移与前 48 条指令；脚本已提交，**尚未在你的 Mac 上运行**。原生表盘未解锁。 | [`178dfc2`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/178dfc222a70a2fd1eb75a0297dd6e68665449cf) |
| **22:05** | **V27.1 真实固件日志回收** | 你已在 Mac 上执行 V27.1，确认两个地址属于 dsc.18 的 `__TEXT_STUBS` 跳板；`ADRP+ADD+BR` 分别跳往 **`0x49C76990`**（受限表盘例外）及 **`0x49C2ED64`**（内部构建相关）。4 次失败均为 Stub Island 的 `a2f/a2o` 归属查询失败，4 组反汇编成功；未运行 `--extended`，未证明功能解锁。 | [`a19d7c0`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/a19d7c06f1c2c534ebd5ae6796b631d21f30f2ae) |
| **21:57** | **V27.1 离线 Stub 审计工具** | 在独立研究分支增加 `a2s/a2f/a2o/disass` 的只读脚本，同时核对两处 NanoTimeKit 调用位置；准备时只有模拟命令验证，随后才得到你的真实 Mac 结果。代码未合入 `main`，见 [PR #1](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/pull/1)。 | [`5ae5706`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/5ae5706b7b9993852dd21ab6ce533fc997fe672e) |
| **19:28** | **V27 受限表盘特殊跳板追踪** | 保留 V26 的 watchOS 沙箱适配研究；新增只读离线工具检查 NanoTimeKit 的 `0x55CE73DC`（受限表盘例外）与 `0x55CE731C`（内部构建相关）两个不同跳板，使用 `a2f/a2o/disass` 且限制终端输出。尚待 Mac 实测，未修改手表或解锁。 | [`7217f81`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/7217f8131b70be0b2fadc7a3ec347c5dda9bd1ff) |
| **19:21** | **V26 watchOS 沙箱逃逸评估** | 核查 `worse_query` 与 `WatchRegion` 真正源码；发现后者面向 watchOS 27，并声称在 Ultra 4 / 27.3 beta 修改过 MG 地区缓存，但目前 Ultra 1 / 23U95 未验证、RO23 签名无 App Group。未运行漏洞或写系统，仅继续非普通资格路径研究。 | [`a00a01b`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/a00a01b8792bc827e99373b40258ebdec179f524) |
| **18:54** | **V25 Poodle 能力方法解析** | 直接读取已上传的真实 23U95 Zeus 与 ClockKit 二进制：解析 `0x469C0` 为 `supportsPDRCapability:`，核实 ClockKit `0x49C6E724` 始终返回 true；交叉验证 `deviceCategory`、`collectionType` 跳板并新增可复现的只读 Python 工具。Poodle 仍受限，未解锁。 | [`440fc7c`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/440fc7c2e2ff91b608b4fe3a004e464ae12a1ece) |
| **18:41** | **V24 Poodle 完整函数验证** | 成功分析 23U95 原始 Zeus 反汇编，从 51,891 行输出中定位 Poodle 的 29 条指令；证实对 Ultra 1 已测属性，不论额外能力函数返回什么，完整 `isRestrictedForDevice:` 静态逻辑都返回受限制。修复 LLVM/otool 脚本，仅输出目标指令，未解锁。 | [`056cfc7`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/056cfc7b883a9e9fc87f0821c6bffd29df240680) |
| **18:33** | **V23 反汇编工具修复** | 用户 Mac 已成功验证 23U95 Zeus 二进制 SHA-256，但缺少 `llvm-objdump`；修改原 V21 脚本，在 LLVM 不可用时自动使用 Xcode `otool` 并仅打印 Poodle 目标指令。无需重装工具或修改手表。 | [`bf32ec8`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/bf32ec8452e31539f5e3855f9ba760174530c776) |
| **18:24** | **V22.2 实机验证** | 记录 Ultra 1 真正运行 V22：`deviceCategory=4`、`collectionType=9`、`NTKInternalBuild=false`、`NTKShowHardwareSpecificFaces=false`。Poodle 的已知后续分支若执行会受限，但 `NTKPoodleFace` 在诊断进程未注册，完整资格结果尚未知；没有系统写入或解锁。 | [`5314247`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/531424766cc2f3d9462b6d191668869f10c2b224) |
| **18:15** | **V22.1 首页修复** | 修复 V22 按钮找不到的问题：把 **V22 · Poodle eligibility** 移到手表首页第一个操作，放到 V16 长日志之前；增加 `RO23 V22.1 installed` 标记，未改动签名或系统写入。 | [`066dfd1`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/066dfd1a079b6bbc7c05cd7c46700e8cef8d1e22) |
| **18:07** | **V22** | 开发手表首页 `V22 · Poodle eligibility` 按钮：读取真实 ClockKit/NanoTimeKit 属性，计算 Poodle 已知条件分支；仅在类已注册时读取原始资格判断，不加载或安装表盘。尚待 Xcode 实机编译验证。 | [`d9453c1`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/d9453c1fadff007ac933a69f0f3eb2387653964e) |
| **17:55** | **V21** | 对照真实 Circulaire 表盘和 23U95 Zeus 固件，梳理 Poodle 设备限制分支；新增只读反汇编脚本，前置分支仍待验证。 | [`2a87325`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/2a87325d31162c17da1d8d6e25b331a4fb77ec2c) |
| **17:49** | **V20.1** | 解析你上传的 249,760 字节 Hermès Circulaire 文件，全部 ZIP CRC 通过；确认 Bundle ID 为 `com.apple.NTKPoodleFaceBundle`。 | [`8c182a7`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/8c182a7f9e4d71211017cd0082b3ca3d64bb4230) |
| **17:35** | **V20** | 新增本地只读 `.watchface` 分析脚本，读取 ZIP、`face.json`、Bundle ID、SHA-256，并研究导入错误分类。 | [`315db1c`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/315db1cd08939e4bffe7fb51d1f0fde0a16979c0) |
| **17:28** | **V19.4** | 记录 `CreateWatchFace` 组件的 `UltraFaceWasAddedToLibrary=YES` 及两个缓存构建号，未修改配置文件。 | [`3f4b98c`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/3f4b98c940cea5a8839ee3b876bd38d3ead25c24) |
| **17:24** | **V19.3** | 读取 iPhone Watch 容器中的 `com.apple.ClockKit.plist`，确认唯一键 `HandFactoryCachedBuild=24B5089g`。 | [`f4c60a8`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/f4c60a84e282d5ae30d6fcf843c0f347e90a1188) |
| **17:21** | **V19.2** | 整理 Filza 实机目录：Bridge 的 `Library/Preferences`、`SyncedPreferences`、`Application Support`，识别敏感同步令牌路径。 | [`557565d`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/557565d264553b17f1ba83dbaa61723d7ab7e0a2) |
| **17:13** | **V19.1** | 审计已上传的 Filza 27.2.2 源码，并核实 iPhone 可列出 `com.apple.Bridge` 数据容器；提示 WebDAV/SSH 风险。 | [`d22a7de`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/d22a7dee6215de180eb925c1d4f25ed09d1c439b) |
| **16:55** | **V19** | 比较 iOS 26 `worse_query` 容器访问范围与 iPhone–Watch 配对、表盘同步路径，未证明手表系统写入权限。 | [`c97e1da`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/c97e1daa80d10faf850e7455e67096b6c7c69e2f) |
| **16:44** | **V18** | 定位受限制表盘查找中的额外判断 `0x55CE73DC`，确认其身份尚未解析，添加离线符号追踪说明。 | [`8fee633`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/8fee633be877108bdad637780f54f41e71ddaa30) |
| **16:37** | **V17** | 梳理 NanoTimeKit 表盘注册、按 Bundle ID/旧 Style 查找及 `_NTKCanAddWatchFace` 的独立准入检查。 | [`7440080`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/74400800cb412b48ec1bfba5b680374f6518fc5c) |
| **15:56** | **V16 实机记录** | 记录你在 Ultra 1 上测得的 `NTKInternalBuild=false`、`NTKShowHardwareSpecificFaces=false`、`NTKShowInternalFaces=false`。 | [`fe5d177`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/fe5d17798c3c4a07995fb90094d3d09197f59749) |
| **15:42** | **V16.1** | 修正 V16 检测入口：将按钮和版本标记直接放到手表 App 首页，避免只能在二级页面找到。 | [`11e835f`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/11e835f23bbc807d57a6484c3f70514e116341f3) |
| **15:37** | **V16** | 新增 `_NTKInternalBuild` 只读检测，并补充 Poodle、Bellona 与硬件专属表盘判断的静态分析。 | [`51fe35e`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/51fe35e1db3880789c022f1552331e5b2ff28e18) |
| **15:27** | **V15** | 将 V13、V14.1、MobileGestalt 缓存的实机日志写入研究记录，分析 NanoTimeKit 的内部前置条件。 | [`b7d33b6`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/b7d33b6b88a46e5bf97f562869ddea148bf21a09) |
| **15:07** | **V14.2.1** | 修复 `Boolean` 与系统类型命名冲突（改为 `RO23ReadBool`），移除无法使用的占位 App Group entitlement。 | [`ebc7693`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/ebc7693db5bb3fc34a59a726015df8f14cd2ea44) |
| **14:58** | **资源修复** | 修复 Watch 与 iPhone Companion 的图标资源构建问题，使用可编译占位图标（非原始图标）。 | [`e2bb4d4`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/e2bb4d4323dead5d241ba45f2f3a60da504a9097) |
| **14:55** | **V14.2 合并** | 合并上游 HermesEnabler 2 工程、Watch App 和 iPhone Companion；加入 V13/V14.1/MG 只读诊断与 23U95 界面保护。 | [`bfa6f12`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/bfa6f1240ee3241cacd364749d98fb05e4c2bfb1) |

## V27.1 最新的真实固件结果（Mac 离线运行，不是手表端动态执行）

| 项目 | 验证结果 | 结论 |
|---|---|---|
| 固件与机器 | `Watch6,18` / `23U95` 完整 arm64_32 dyld shared cache | 设备所有者提供的真实 Mac 终端输出 |
| 表盘限制例外调用 | `0x55CE73DC → 0x49C76990` | 由 `ADRP x16,0x49C76000; ADD #0x990; BR x16` 直接算出 |
| 内部构建相关调用 | `0x55CE731C → 0x49C2ED64` | 由 `ADRP x16,0x49C2E000; ADD #0xD64; BR x16` 直接算出 |
| 4 个查询失败 | 2 个 Stub Island × `a2f` / `a2o --image-rel` | 目标为 `__TEXT_STUBS`，不能按普通 dylib 映像直接归属；**并非反汇编失败** |
| 2 个调用现场 | `0x544B0F94` 和 `0x544B1164` | 均确认在普通受限判断后走向相同的例外跳板 |
| 下一检查 | `0x49C76990` / `0x49C2ED64` 的真实函数身份及返回条件 | 尚未证明为可用的授权绕过，`_NTKCanAddWatchFace` 仍独立检查 |

**记录规则：** 后续每次提供测试指令、收到真实输出、取得结果或发现失败，都在 README 时间线新增一行（中英同步），标注真实 GitHub 提交时间及离线/手表实测边界；不能将“工具完成”标记成“表盘已启动”。完整原始指令摘要见 [V27.1 研究记录（PR 分支）](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/blob/research/ro23-v27-1-stub-binding-audit/research/RO23-V27.1-Stub-Binding-Audit.md)，下一脚本见 [V27.2（PR 分支）](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/blob/research/ro23-v27-1-stub-binding-audit/scripts/ro23-v27-2-branch-targets.sh)。

## 当天已确认的实机数据

| 项目 | 已确认结果 | 意义 |
|---|---|---|
| **设备 / 系统** | Watch6,18 / watchOS 26.6.1 / `23U95` | RO23 研究对象，不等于上游正式支持的系统范围 |
| **V13/V14.1** | `deviceCategory=4`, `collectionType=9`, `deviceBrand=0`, `isUltra=true` | 真实 ClockKit/MobileGestalt 属性 |
| **V16** | `NTKInternalBuild=false`, `NTKShowHardwareSpecificFaces=false`, `NTKShowInternalFaces=false` | 已验证内部构建版本前置条件未通过 |
| **Hermès 2025** | 类别白名单 `{2,3,5}` 不包含类别 `4` | 2025 表盘已知类别限制失败 |
| **Hermès Circulaire** | `com.apple.NTKPoodleFaceBundle`，原始 ZIP/CRC 校验成功 | 文件真实有效，但这不代表手表能够安装 |
| **Poodle 完整静态资格检查（V25）** | `category=4`, `collectionType=9`、`NTKShowHardwareSpecificFaces=false`，且匹配 ClockKit 能力调用返回 true | 完整 `isRestrictedForDevice:` 静态路径返回 restricted=true；并非 Watch 进程的动态调用 |
| **系统写入与解锁** | 未发现可验证的受保护写入方法；**未解锁** | 不能把只读诊断或离线分析描述为破解成功 |

## 研究文件与源码

- [V27｜NanoTimeKit 受限表盘特殊跳板追踪](research/RO23-V27-Exception-Stub-Trace.md)
- [V26｜watchOS 沙箱逃逸与 Ultra 1 适配评估](research/RO23-V26-WatchOS-Sandbox-Feasibility.md)
- [V25｜Poodle 能力选择器与 ClockKit 返回值验证](research/RO23-V25-Poodle-Selector-ClockKit.md)
- [V24｜Poodle 完整静态资格函数分析](research/RO23-V24-Poodle-Full-Gate.md)
- [V22｜Poodle 手表端实测入口与限制分支](research/RO23-V22-Poodle-Runtime-Gate.md)
- [V21｜Poodle 设备资格条件与未解析分支](research/RO23-V21-Poodle-Gate-Mapping.md)
- [V20 / V20.1｜真实 Hermès Circulaire 文件分析](research/RO23-V20-Watchface-Archive-Import.md)
- [V17｜FaceBundle 注册、查找与添加表盘检查](research/RO23-V17-FaceBundle-Loading-Chain.md)
- [V16｜内部构建版本判断与实机日志](research/RO23-V16-InternalBuild-Gate.md)
- [V19.1–V19.4｜Filza 源码与 iPhone Watch 数据目录](research/RO23-V19.1-Filza-Source-And-Bridge-Verification.md)
- [完整研究进度（中文）](research/RO23-STATUS.zh-CN.md) · [全部变更记录](CHANGELOG.md) · [Xcode 工程说明](BUILDING.md)

**使用现有工程：** 本仓库的 `HermesEnabler2.xcodeproj`；不要创建另一套 Xcode 工程。最新研究报告更新不一定对应手表 App 的新版本或新按钮。**RO23 是非官方研究分支，不能被宣传为已支持 watchOS 26 的 Hermès 解锁工具。**

## 原作者、授权和研究归属

- **HermesEnabler 2 原作者：** [Jinwoo Kim (@pookjw)](https://github.com/pookjw/HermesEnabler)。
- **本仓库 RO23 实机与资料：** [@ZhuoXuan-MY](https://github.com/ZhuoXuan-MY)；部分代码、分析报告及提交由 AI 辅助完成。
- **相关项目：** [Gester](https://github.com/sasobhabha/Gester)。保留原项目 MIT 版权声明及第三方许可，详见 [LICENSE](LICENSE)、[NOTICE.md](NOTICE.md)。
- **研究讨论：** [HermesEnabler Issue #17](https://github.com/pookjw/HermesEnabler/issues/17)。Apple、Hermès 与原项目作者均未对本研究分支提供背书。
