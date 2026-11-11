# RO23 开发日志｜Apple Watch Ultra 1 · 23U95

**研究进度截至：2026-11-11 23:28（北京时间，UTC+08:00）**  
**研究设备：** Apple Watch Ultra 第一代（Watch6,18 / n199ap）· watchOS 26.6.1（23U95）  
**当前结果：原生 Hermès 表盘尚未解锁。**

这里按**可核实的时间及来源**记录 RO23 项目：**V14.2（2026-11-11 14:55）及后续**使用本仓库实际 GitHub commit 时间换算的北京时间；**V14.2 之前补录的 V0–V14.1** 使用上游 [Issue #17](https://github.com/pookjw/HermesEnabler/issues/17) 评论的**发布时间**，不是实机实验的准确分钟，也不是当时本仓库的 commit。V14、V14.1 的精确操作时间尚未证实。实机诊断由设备所有者执行，源码与研究资料有 AI 辅助；记录代码或文档**不代表手表已成功解锁**。

## 2026 年 11 月 11 日｜逐分钟开发记录（新 → 旧）

| 时间（北京时间） | 版本 | 具体做了什么 | GitHub 提交 |
|---|---|---|---|
| **23:28** | **V30：EscapeOS v0.3.2 验证** | 按用户提出的新候选方案检查发布版、`Info.plist`、`AppGroupListing.swift`、`SandboxEscape.swift`、`worse_query.m` 与签名 entitlement。确认它是 **iPhone / iOS 26 App 数据与普通 App Groups 工具**；没有 watchOS 目标，普通 `group.` 容器 ≠ Watch `systemgroup.com.apple.mobilegestaltcache`；未获取 23U95 系统写权限。**无设备试写、无 Hermès 解锁**。[完整核验](research/RO23-V30-EscapeOS-v0.3.2-Compatibility.md)。 | [`db4d4d5`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/db4d4d5e7799c551804ee60fc0938a931e74060b) |
| **23:23** | **V14.2 以前历史重建／文档补录** | 核对 [Issue #17](https://github.com/pookjw/HermesEnabler/issues/17) 原帖及10条评论、早期本仓库诊断记录，补齐 V0、V1–V14.1 各阶段的真实动作与结果；将 Issue 评论的**发布时间**和真实操作时间分开，保留错误 index206→正确 index103 的更正，新增 [前史完整报告](research/RO23-PRE-V14.2-HISTORY.md)。**本次只是补写文档，不是重新运行旧实验。** | [`dddba1a`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/dddba1a65df9000018eed3263598b2636a7b4e1d) |
| **23:15** | **V29.1 Filza / MG 编辑器替代路径核查** | 确认 iPhone 上的 Filza 只能访问其实际获授权的设备文件，不能直接改写独立的 Apple Watch 受保护 `plist`；WorstGestalt 的 iOS 26 成功声明不代表 watchOS 26 成功；配对手表备份包含表盘设置却不能证明可替换 MG 缓存。Apple 官方 watchOS 27 兼容列表**不含 Ultra 1**。因此 23U95 手表端 `EPERM` 写入阻塞仍未解决；本轮没有执行设备写入或解锁。 | [`c5ae0a4`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/c5ae0a47aafd3529a4f68a94e9b0d9c5e9ee80f8) |
| **22:39** | **V29 系统写入权限专项核查：尚未解决** | 对照 `BQCore.m` 既有读写路径与 `worse_query`、Erosion、WatchRegion 的实际源码；确定 Ultra 4 / watchOS 27.3 beta 的系统缓存写入不能直接视为 Ultra 1 / 23U95 可用；`worse_query` 在 iOS 26 无 MobileGestalt 写入能力，公开 watchOS 26.6.1 越狱表无可用工具。**本轮无手表连接、无权限提升、无系统写入、无解锁**；目标仍需真实写入与重启持久化验证。 | [`abfb7d0`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/abfb7d0280a29844cda3cd32f105f0a85a86760d) |
| **22:25** | **V28 强制修改可行性（源码实审）** | 按“强行修改”的要求直接审查 `BQCore.m`，确认 `BQSetHermesEnabled` 的固件白名单**不含 23U95**，而此前真实 `BQSaveGestalt` 受保护写入因 `EPERM` 被系统拒绝。删除 App 版本检查不能获得写权限；决定停用 V27.3 的无效离线任务，未向手表写入，未创建假解锁开关。验收只看真实系统写入、普通原生表盘添加和手表显示。 | [`ddcdd1e`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/ddcdd1e1b51b4cfc0a10454b41a2d4f325933eca) |
| **22:13** | **V27.2 真实 ClockKit 函数解析成功** | 你在 Mac 对真实 Watch6,18 / 23U95 dyld 缓存运行 V27.2，8 项查询均成功。确认 `0x55CE73DC → 0x49C76990 = _CLKIsFaceSnapshotService`，以及 `0x55CE731C → 0x49C2ED64 = _CLKInternalBuild`；两者都在 ClockKit。前者是表盘快照服务谓词，**不能视为普通设备的 Hermès 解锁授权**。按真实函数边界纠正 48 条指令越界误读。未安装/启动表盘。 | [`819bd60`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/819bd6038171e54e870904a0e8b1d5d49efa6a6c) |
| **22:12** | **V27.3 快照服务及表盘添加检查脚本** | 在现有 [PR #1](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/pull/1) 分支新增只读分析：追踪 `_CLKIsFaceSnapshotService` 初始化调用 `0x49C99CFC`，并分别检查 `_NTKCanAddWatchFace` 的配置、可用性、受限表盘判断。**脚本尚未在你的 Mac 上运行**，无任何设备写入。 | [`e30ff95`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/e30ff957822f5a1fd6bbef351533d4ac1cf622cd) |
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

**V14.2 以前的历史补录说明：** V0／V1–V14.1 的表格时间来自 [原作者 Issue #17](https://github.com/pookjw/HermesEnabler/issues/17) 的创建/报告发布时间（并非本仓库 commit 或确切实测分钟）；V14／V14.1 的准确分钟暂未核实。全部技术细节、日志与**错误更正**见 [V14.2 前完整操作史](research/RO23-PRE-V14.2-HISTORY.md)。原有 14:55 V14.2 合并及之后 GitHub commit 时间维持不变。

## V30｜EscapeOS v0.3.2 能否修改 Apple Watch 受保护 plist？

**答：不能作为 Ultra 1 / `23U95` 的系统写入解决方案。** 用户提交 [EscapeOS v0.3.2](https://github.com/pwnapplehat/EscapeOS/releases/tag/v0.3.2) 后，本轮对**准确 tag 源码**进行了核查：`Resources/Info.plist` 表明应用运行平台是 `iPhoneOS` 且最低 iOS 26.0；其新增的“App Groups”功能仅在 iPhone 安装记录列出普通 App Group 标识和对应路径时浏览应用共享容器，`AppGroupListing.swift` 只接受 `group.` 前缀，并不等同手表独立的受保护 Apple `systemgroup.com.apple.mobilegestaltcache`。源码 `worse_query.m` 仍使用 Class 7，`EscapeOS.entitlements` 没有 Apple SystemGroup 私有写入 entitlement。没有新的目标手表读写测试，也不建议安装该 iPhone IPA 去改配对文件来“解锁”表盘。**真实写入障碍仍为 `open(O_RDWR) → EPERM`。** [查看证据和源码逐项表](research/RO23-V30-EscapeOS-v0.3.2-Compatibility.md)。

## V29.1｜Filza、iPhone MobileGestalt 修改器、手表备份能否代替系统写权限？

**用户问题：** “filza MobileGestalt 那些工具都不能修改 Apple Watch 的 plist 文件吗？或者没有其他办法了吗？” 本次是**工具能力与权限边界核验**，并非在 Mac/iPhone/Watch 上运行了新的写入测试。

| 方案 | 已核查的事实 | 对 Ultra 1 / 23U95 的结论 |
|---|---|---|
| 原版 [Filza（TIGI 官方）](https://www.tigisoftware.com/default/?page_id=78) | 官方列明支持 iPhone、iPad、iPod touch，拥有 plist 编辑器；其读取对象取决于安装设备及实际文件权限 | **iPhone 上的 Filza 无法直接编辑另一台 Apple Watch 的受保护系统目录**。能打开本地导出的 `.plist` 不代表能写回手表 |
| [WorstGestalt](https://github.com/GoldenNugget-Team/worstgestalt) / iPhone MG 修改器 | WorstGestalt 自述 iOS 26 可用 `bad_query` 等途径改**iPhone** 上的 MobileGestalt，部分其他 iOS 项目可能适用范围不同 | **这是 iOS 工具的兼容性声明，不是 Watch6,18/watchOS 26.6.1 成功写入证明**。避免把之前对 Erosion 的结论误写为“任何 iOS 26 都不能改 MG” |
| iPhone Watch App 的容器及成对手表备份 | [Apple 官方备份说明](https://support.apple.com/en-my/108358) 列有表盘设置、外观、顺序等用户数据，但未列明受保护的 `systemgroup.com.apple.mobilegestaltcache` 可被备份编辑覆盖 | **可能影响受允许的表盘配置/同步，不是可证明的 `DeviceBrand` 写入渠道** |
| 用 `.watchface` 导入 Hermès | [Apple ClockKit addWatchFace 官方 API](https://developer.apple.com/documentation/clockkit/clkwatchfacelibrary/addwatchface%28at%3Acompletionhandler%3A%29) 明确说明 Nike/Hermès 原生表盘限对应硬件，失败会回调错误 | 先改 iPhone 端表盘文件或导入有效 Circulaire 文件，也**不能保证绕过手表自身资格判断** |
| 在手表中直接编辑受保护 plist | 已有 23U95 实机日志验证可读，但 `open(O_RDWR)` 被 `EPERM` 拒绝；Filza 的 plist 编辑功能、SFTP 客户端、Xcode 安装 App 均不能自动增加进程权限 | **只有具备真正有效的手表端写入权限/受信任系统服务才能操作**；目前没有验证到这种权限 |
| 官方升级 watchOS 27 以使用其它工具 | [Apple 官方兼容列表](https://www.apple.com/my/os/watchos/) 包括 Ultra 2/3/4，**不包括第一代 Ultra** | **Ultra 1 无法通过官方更新升级到 watchOS 27**，不能推荐以此解决 |
| 完整越狱/特权路径 | [公开 watchOS 26.x 兼容表](https://theapplewiki.com/wiki/Jailbreak/26.x) 对相关版本标注无可用工具 | 不能宣称物理上永远不可能，但截至本轮未核查到**匹配 Ultra 1/23U95 的可复现成功工具** |

**结论：** 没有发现 Filza 或 iPhone 侧 MobileGestalt 编辑器能跨越手表的独立文件系统/权限边界；修改手表备份或导入真实 `.watchface` 并不等于改写手表 `MobileGestalt`。现阶段需要真正的**手表端**系统写权限；它目前仍被 `EPERM` 阻止。**本轮没有请求用户运行测试、没有修改 `BQCore.m`、没有宣称原生 Hermès 解锁。**

## V29｜23U95 系统写入权限专项核查（问题未解决）

**唯一目标：** 在拥有者的 Apple Watch Ultra 第一代（`Watch6,18`，watchOS 26.6.1 `23U95`）取得**真实、可读回验证**的系统缓存写入能力，以便后续检验原生 Hermès 表盘能否被系统接纳。不是改变 App 里的按钮或伪造 `true` 返回值。

**本次实际完成：** 审核自身 `BQCore.m` 已有的 `BQEscape → BQSaveGestalt → bq_write_data` 写入链，核对 `worse_query` 开发者原始说明、`Erosion` 与 `WatchRegion` 源码、公开 watchOS 26.6.1 越狱兼容表，以及 Apple 2026-11-09 的 26.6.1 安全公告。**没有连接手表、执行漏洞、修改系统文件或生成所谓成功解锁包。**

| 候选路径 | 有实据的结果 | 对 `Watch6,18 / 23U95` 的判定 |
|---|---|---|
| 现有 HermesEnabler `BQEscape` / Class 13 | 已有真机日志：受保护缓存可读，`open(O_RDWR)` 返回 `EPERM`；单独沙箱令牌未授予写权限 | **真实写入失败** |
| [`forcequitOS/worse_query`](https://github.com/forcequitOS/worse_query) | 官方 PoC 说明 SystemGroup 通路属于 **iOS 27**；iOS 26 的适用路径范围不同，作者称其**不是越狱** | **没有证明支持 watchOS 26 的 MG 写入** |
| [`jailbreakdotparty/Erosion`](https://github.com/jailbreakdotparty/Erosion) | FAQ 直说 `worse_query` 在 **iOS 26** 无法写 MobileGestalt | iOS 负面结果不能直接当作 watchOS 实测，但**不能作为 23U95 可写的依据** |
| [`LogicSense1/WatchRegion`](https://github.com/LogicSense1/WatchRegion) | `RegionCache.swift` 经 `worse_query` 后仍调用 `open(O_RDWR)` 写受保护缓存；已公布成功设备是 Ultra 4、watchOS 27.3 beta `24S5284h` | **没有 Ultra 1 / 23U95 成功证据**；直接搬用仍可能 `EPERM` |
| [公开 watchOS 26.x 越狱列表](https://theapplewiki.com/wiki/Jailbreak/26.x) | `26.6.1` 列为 `No Tool Available` | **没有核实到可用的公开完整越狱** |
| [Apple watchOS 26.6.1 安全公告](https://support.apple.com/en-us/149723) | 官方发布日期 2026-11-09，所列修复集中在蓝牙/配对相关组件 | **不是可利用写入权限的公开方案** |

**技术结论：** 要越过这个关口，必须有**真正赋予当前进程写入权限**的系统级执行环境／可验证漏洞链／Apple 授权的相应服务；单改 `DeviceBrand` 数值、缓存偏移、Xcode 签名、App 本地函数返回值或把 iOS 27 实验移植过来均不等于已经获得这种权限。当前没有可验证的 23U95 写入原语；**这个请求尚未解决。** 没有实施危险的猜测性缓存写入，避免损坏无恢复保障的配对手表。

**验收标准（都必须真实通过）：** (1) 目标系统文件安全打开并有写权限，(2) 目标受保护状态修改后精确读回且重启后有效，(3) 系统接受并实际显示原生 Hermès 表盘。当前 **0/3**。不要把从另一个系统版本取得的 `write` 测试描述为 23U95 成功。

## V28｜强制修改的真实可行性结论（仅源码审核，没有操作手表）

用户明确要求**强制修改**以真正启动原生 Hermès 表盘，要求停止无关的静态函数跟踪。本轮直接审核现有 [`BQCore.m`](HermesEnabler2/BQCore.m)，没有执行或交付任何被描述为“成功解锁”的虚假开关。

- `BQEnableHermes` 实际只调用 `BQSetHermesEnabled(YES,...)`。后者查找 `kDeviceBrandLayouts` 里的**精确固件版本**，当前只有 `24S5284h`、`24R359`、`24R364`、`24R365`、`24S118`、`24S132`；**不包含 `23U95`**。所以强行解除 UI 屏蔽仍不会使此原有写入流程支持 watchOS 26.6.1。
- `BQSaveGestalt` 实际经 `BQEscape(kMGCaches,...)` 找到缓存，再使用 `bq_write_data` 的 `open(O_RDWR|O_CLOEXEC|O_NOFOLLOW)` / 临时文件 `rename` 写入。设备所有者此前针对受保护系统缓存的真实测试返回 **`EPERM`**。已有只读查询/沙箱令牌不能替代写入权。
- V27.2 在真实固件中确认的 `_CLKIsFaceSnapshotService` 是**快照服务**例外，不是普通手表安装 Hermès 表盘的授权途径。Poodle 的正常限制仍未通过。
- 公开的 [watchOS 26.x 越狱兼容列表](https://theapplewiki.com/wiki/Jailbreak/26.x) 在本次核查时没有列出支持 watchOS 26.6.1 / Ultra 1 的公开工具；**没有公开工具不等于数学意义上的不可能，但绝不能把未经验证的漏洞当作可用权限**。

**决定：** 不再生成重复的 V27.x 反汇编任务；**不向 `main` 提交只会导致拒绝写入或可能损坏设备的所谓强制解锁代码**。真正的验收是：系统状态可写且读回核验成功 → 系统正常识别原生表盘 → 真实 Ultra 1 表盘成功显示并持久化。当前**三项均未达成，NOT UNLOCKED**。如有可复现且与 `Watch6,18/23U95` 完全匹配的权限来源，才能重新评估实装；没有则应明确告知阻塞，而非以新脚本代替解决方案。

## V27.2 真实结果与 V27.3 下一步（2026-11-11）

**你已经执行的操作：** 从 GitHub 研究分支获取 `scripts/ro23-v27-2-branch-targets.sh`，在 Mac 上对原有 `Watch6,18/23U95` ARM64_32 共享缓存做静态检查；结果为 **`Completed: 0 command(s) failed`**。这是 **8 个离线 ipsw 查询成功**，不是手表上的 Hermès 表盘启动成功。

| 代码作用 | 真实 ClockKit 符号 | 函数地址及结束地址 | 证据 |
|---|---|---|---|
| 受限表盘查找后的例外调用 | **`_CLKIsFaceSnapshotService`** | `0x49C76990–0x49C769C0` | 原始 Stub `0x55CE73DC` 分支；`ipsw a2s/a2f` 已核实 |
| 内部版本判断 | **`_CLKInternalBuild`** | `0x49C2ED64–0x49C2ED94` | 原始 Stub `0x55CE731C` 分支；`ipsw a2s/a2f` 已核实 |

- 两个函数均在 `/System/Library/Frameworks/ClockKit.framework/ClockKit`。
- `_CLKIsFaceSnapshotService` 内部调用 `0x49C99CFC` 进行缓存相关初始化；其具体判断逻辑**尚未解析**。
- V27.2 的 `--count 48` 把紧邻的其他函数也输出了，**从 `0x49C769C0` 和 `0x49C2ED94` 起的代码不属于上述两个函数**。
- Snapshot Service 的例外不证明普通表盘添加流程已获授权；此前 Poodle 常规限制及 `_NTKCanAddWatchFace` 的其他验证仍有效。

**历史命令（V27.3，已按 V28 决定停止；不要再执行）：** 以下命令读取现有固件，不会安装 IPA、更改签名、运行越狱或修改 Watch/iPhone 系统文件。运行产生的日志保存在桌面。

```bash
set -o pipefail
REPO="$HOME/Downloads/HermesEnabler-RO23-Live"
git -C "$REPO" fetch origin research/ro23-v27-1-stub-binding-audit &&
git -C "$REPO" show FETCH_HEAD:scripts/ro23-v27-3-snapshot-service-and-add-gates.sh \
  | bash -s -- 2>&1 \
  | tee "$HOME/Desktop/RO23-V27.3.txt"
```

完整核验记录：[V27.2 ClockKit 函数边界与原始证据](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/blob/research/ro23-v27-1-stub-binding-audit/research/RO23-V27.2-ClockKit-Snapshot-Service.md)；脚本：[V27.3](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/blob/research/ro23-v27-1-stub-binding-audit/scripts/ro23-v27-3-snapshot-service-and-add-gates.sh)。

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

**本轮实际执行命令（V27.1，`--extended` 未运行）：**

```bash
set -o pipefail
REPO="$HOME/Downloads/HermesEnabler-RO23-Live"
git -C "$REPO" fetch origin research/ro23-v27-1-stub-binding-audit
git -C "$REPO" show FETCH_HEAD:scripts/ro23-v27-1-stub-binding-audit.sh \
  | bash -s -- \
  | tee "$HOME/Desktop/RO23-V27.1.txt"
```

**下一轮操作（V27.2，尚未执行）：**

```bash
set -o pipefail
REPO="$HOME/Downloads/HermesEnabler-RO23-Live"
git -C "$REPO" fetch origin research/ro23-v27-1-stub-binding-audit &&
git -C "$REPO" show FETCH_HEAD:scripts/ro23-v27-2-branch-targets.sh \
  | bash -s -- 2>&1 | tee "$HOME/Desktop/RO23-V27.2.txt"
```

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

- [V0–V14.1｜V14.2 前完整操作史与 Issue #17 原始证据](research/RO23-PRE-V14.2-HISTORY.md)
- [V27.2｜真实 ClockKit 快照服务与内部构建符号](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/blob/research/ro23-v27-1-stub-binding-audit/research/RO23-V27.2-ClockKit-Snapshot-Service.md)
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
