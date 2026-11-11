# RO23 开发日志｜Apple Watch Ultra 1 · 23U95

**研究进度截至：2026-11-11 23:15（北京时间，UTC+08:00）**  
**研究设备：** Apple Watch Ultra 第一代（Watch6,18 / n199ap）· watchOS 26.6.1（23U95）  
**当前结果：原生 Hermès 表盘尚未解锁。**

这里按**实际 GitHub 提交时间**记录我们对 RO23 衍生项目的每次修改、验证资料的入库和技术判断。以下“几点几分”来自 GitHub commit 的 UTC 时间换算为北京时间；**不是声称在该分钟直接操作、刷写或测试了你的手表**。实际手表诊断由设备所有者运行，源码与报告修改有 AI 辅助。

## 2026 年 11 月 11 日｜逐分钟开发记录（新 → 旧）

| 时间（北京时间） | 版本 | 具体做了什么 | GitHub 提交 |
|---|---|---|---|
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

---

## English — timestamped development history

**Recorded through November 11, 2026, 23:15 (Beijing Time, UTC+08:00).** Target device: first-generation Apple Watch Ultra (Watch6,18), watchOS 26.6.1 (23U95). **Native Hermès watchfaces are NOT unlocked.**

Every timestamp below is the **actual GitHub commit time converted to Beijing Time**, not a claim of on-device operation at that minute. Device measurements were run by the owner; some repository changes and analysis were AI-assisted.

### V29.1 — Filza / iPhone MobileGestalt tools / watch backup cannot substitute for watchOS write authority

The owner asked whether Filza, iPhone MobileGestalt editors or other methods could modify their Watch's system plist. This was **a source-based capability review, not a device experiment**.

- The [official Filza developer](https://www.tigisoftware.com/default/?page_id=78) describes an iPhone/iPad/iPod file manager with a plist editor. **Editing a local file on an iPhone does not expose the separate paired Watch's protected filesystem**.
- [WorstGestalt](https://github.com/GoldenNugget-Team/worstgestalt) claims successful iOS 26 MobileGestalt modification using a `bad_query` fallback. It is explicitly an **iPhone** application; this neither confirms nor disproves a Watch6,18/watchOS 26.6.1 capability. The broad statement “no iOS 26 MG tool works” would be incorrect.
- [Apple's Apple Watch backup guide](https://support.apple.com/en-my/108358) lists user-visible watch face configuration/settings in paired-iPhone backups, not a supported route for replacing the Watch's protected MobileGestalt system group.
- [Apple's `CLKWatchFaceLibrary.addWatchFace` documentation](https://developer.apple.com/documentation/clockkit/clkwatchfacelibrary/addwatchface%28at%3Acompletionhandler%3A%29) explicitly limits Hermès faces to corresponding Hermès watch hardware; importing a real watchface file or modifying companion app data cannot be presumed to bypass native device eligibility.
- [Apple watchOS 27 compatibility](https://www.apple.com/my/os/watchos/) **excludes the first-generation Ultra**. Updating this Watch to watchOS 27 to reuse the newer exploit projects is not an official option.
- The actual owner-device `23U95` test remains **read permitted / `O_RDWR` denied with `EPERM`**. Without a proven Watch-specific privileged write capability, installing a generic plist editor does not resolve it.

**No code or device changes, no new test command, no native Hermès activation.** Do not claim a cross-device iPhone-only exploit solves the watchOS protected-cache write gate.

### V29 — Actual 23U95 protected-write capability audit (UNSOLVED)

The user's objective is **verified native system modification**, not more symbol discovery or UI-level forced flags. Audited the existing `BQEscape → BQSaveGestalt → bq_write_data` path in the repository and checked primary-source `forcequitOS/worse_query`, `jailbreakdotparty/Erosion`, and `LogicSense1/WatchRegion` code and docs, the [watchOS 26.x jailbreak compatibility table](https://theapplewiki.com/wiki/Jailbreak/26.x), and the [Apple watchOS 26.6.1 security release](https://support.apple.com/en-us/149723) dated November 9, 2026.

- **Owner's original Watch6,18 / 23U95 device evidence:** protected cache reads work, but `open(O_RDWR)` fails with **`EPERM`**. A Class-13 sandbox token is not a write-capability grant.
- **worse_query:** upstream expressly presents iOS 27 systemgroup access, but not an iOS 26 systemgroup write primitive; it is not a full jailbreak.
- **Erosion:** explicitly says its iOS 26 worse_query backend cannot modify MobileGestalt. iOS results cannot be mislabeled as the watchOS result, but cannot validate this watch's writability either.
- **WatchRegion:** its `RegionCache.swift` still ultimately calls `open(O_RDWR)`, and the published success involves Ultra 4/watchOS 27.3 beta (`24S5284h`), not the target hardware/firmware.
- **Public compatibility:** no known verified public jailbreak tool is listed for watchOS 26.6.1. An undisclosed exploit is logically possible but is **not** an implementable or tested path.
- **No actual watch access or modifications were made in this turn**. No unsupported `23U95` offsets, guessed private entitlements, fabricated successful write, or misleading unlock release was added.

**Status: NOT WRITABLE / NOT UNLOCKED, based on the current device evidence, with no public alternate route confirmed.** Completion requires an actual checked write permission, write/readback/reboot persistence, and native Hermès face launch on Watch6,18/23U95; currently **0/3**. Stop unrelated V27.x tasks. Future implementation should be gated on a genuinely verified 23U95 permission source, not another speculative bypass.

### V28 — Requested forced system modification: direct code feasibility review

The user requested **actual protected-system modification for native Hermès activation**, not more speculative disassembly. The review of [`BQCore.m`](HermesEnabler2/BQCore.m) confirmed:

- `BQEnableHermes` delegates to `BQSetHermesEnabled`, which accepts only exact entries in `kDeviceBrandLayouts`: `24S5284h`, `24R359`, `24R364`, `24R365`, `24S118`, `24S132`. **`23U95` is absent**.
- The actual write function `BQSaveGestalt` requires protected cache file access. The owner's previous Watch6,18 / 23U95 write attempt returned **`EPERM`** despite read access/sandbox token. Removing an app-level version guard cannot grant write permission.
- V27.2 resolved `_CLKIsFaceSnapshotService`, a face snapshot service exception, not a normal authorization to add arbitrary restricted faces. Public jailbreak compatibility [lists](https://theapplewiki.com/wiki/Jailbreak/26.x) provide no confirmed Ultra 1 / watchOS 26.6.1 tool at the time of this review.

**No counterfeit unlock flag or dangerous speculative protected-cache writer was committed; no new on-device test was executed.** Success criteria remain: verified writable system state, ordinary native face availability, and **real persistent Hermès display on the target Watch**. No criteria are met. Research status: **NOT UNLOCKED**.

### V27.2 owner result and V27.3 action (2026-11-11)

The owner executed the V27.2 script on Mac against the existing **Watch6,18 / 23U95** ARM64_32 dyld cache; **all eight ipsw commands passed**. Both resolved symbols are in ClockKit: `_CLKIsFaceSnapshotService` at `0x49C76990–0x49C769C0`, and `_CLKInternalBuild` at `0x49C2ED64–0x49C2ED94`. The snapshot function calls an as-yet unanalyzed cache-initialization helper `0x49C99CFC`. V27.2's 48-instruction dumps included **neighboring functions beyond these verified ends**, so do not mix their instructions into the predicate bodies. A snapshot-service exception is **not** a normal Add-to-Library authorization or native unlock. See the [full V27.2 evidence](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/blob/research/ro23-v27-1-stub-binding-audit/research/RO23-V27.2-ClockKit-Snapshot-Service.md).

**V27.3 superseded historical Mac command — DO NOT RUN.** It statically inspects the snapshot service helper and independent `_NTKCanAddWatchFace` checks without touching the watch:

```bash
set -o pipefail
REPO="$HOME/Downloads/HermesEnabler-RO23-Live"
git -C "$REPO" fetch origin research/ro23-v27-1-stub-binding-audit &&
git -C "$REPO" show FETCH_HEAD:scripts/ro23-v27-3-snapshot-service-and-add-gates.sh \
  | bash -s -- 2>&1 \
  | tee "$HOME/Desktop/RO23-V27.3.txt"
```

### Latest owner-verified V27.1 firmware output (offline Mac analysis)

The genuine 23U95 shared-cache log resolves `0x55CE73DC → 0x49C76990` and `0x55CE731C → 0x49C2ED64` as direct branch targets in separate `dsc.18` stub-island entries. Four `a2f/a2o` lookups failed because the stubs are not ordinary dylib image addresses; disassembly of both stubs and both NanoTimeKit call sites **succeeded**. `--extended` was not used. Neither target function has been identified or shown to permit Hermès activation. Follow the [V27.1 owner-run evidence](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/blob/research/ro23-v27-1-stub-binding-audit/research/RO23-V27.1-Stub-Binding-Audit.md) and [V27.2 target tracer](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/blob/research/ro23-v27-1-stub-binding-audit/scripts/ro23-v27-2-branch-targets.sh). New test requests and their actual results will be recorded in this README's timestamped history before being described as complete.

**V27.1 owner command (completed, without `--extended`):**

```bash
set -o pipefail
REPO="$HOME/Downloads/HermesEnabler-RO23-Live"
git -C "$REPO" fetch origin research/ro23-v27-1-stub-binding-audit
git -C "$REPO" show FETCH_HEAD:scripts/ro23-v27-1-stub-binding-audit.sh \
  | bash -s -- \
  | tee "$HOME/Desktop/RO23-V27.1.txt"
```

**V27.2 command (prepared, NOT YET EXECUTED on the owner's Mac):**

```bash
set -o pipefail
REPO="$HOME/Downloads/HermesEnabler-RO23-Live"
git -C "$REPO" fetch origin research/ro23-v27-1-stub-binding-audit &&
git -C "$REPO" show FETCH_HEAD:scripts/ro23-v27-2-branch-targets.sh \
  | bash -s -- 2>&1 | tee "$HOME/Desktop/RO23-V27.2.txt"
```

| Time (Beijing Time) | Version | Verified repository change / evidence recorded | Commit |
|---|---|---|---|
| **23:15** | **V29.1 Filza / MobileGestalt workaround audit** | iPhone Filza cannot directly write the separate paired Apple Watch's protected plist; WorstGestalt's iOS 26 claim does not establish watchOS 26 support. Pairing backups include face settings but no demonstrated protected MG cache replacement. Apple does **not support watchOS 27 on Ultra 1**. The actual 23U95 `EPERM` gate remains; no device write or unlock performed. | [`c5ae0a4`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/c5ae0a47aafd3529a4f68a94e9b0d9c5e9ee80f8) |
| **22:39** | **V29 protected-cache write gate: unresolved** | Reviewed current `BQCore.m` and the actual upstream `worse_query`, Erosion, and WatchRegion implementations. The Ultra 4/watchOS 27.3 beta success cannot validate Ultra 1/23U95; iOS 26 worse_query cannot write MobileGestalt, and no public watchOS 26.6.1 jailbreak is listed. **No device connection, privilege escalation, protected write or unlock in this turn.** | [`abfb7d0`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/abfb7d0280a29844cda3cd32f105f0a85a86760d) |
| **22:25** | **V28 forced system modification audit** | Direct source review of `BQCore.m`: `BQSetHermesEnabled` has **no `23U95` layout**, and previously attempted protected cache writes returned **`EPERM`**. App-level bypass cannot grant watchOS write authority. Stopped redundant V27.3 work; did not submit a fake unlock or write the device. Success requires verified system write, ordinary face addition, and live native watchface display. | [`ddcdd1e`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/ddcdd1e1b51b4cfc0a10454b41a2d4f325933eca) |
| **22:13** | **V27.2 real ClockKit functions resolved** | The owner's **real Watch6,18/23U95 Mac** run succeeded (8/8 commands). The `0x55CE73DC` face exception stub resolves to **`_CLKIsFaceSnapshotService`** at `0x49C76990`, and separate `0x55CE731C` resolves to **`_CLKInternalBuild`** at `0x49C2ED64`; both belong to ClockKit. Snapshot-service scope does **not** establish an ordinary Hermès unlock. Corrected interpretation at real function boundaries; no native face launch. | [`819bd60`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/819bd6038171e54e870904a0e8b1d5d49efa6a6c) |
| **22:12** | **V27.3 snapshot/init + face-add gate tracer** | Added a read-only research script on [PR #1](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/pull/1) to inspect the `_CLKIsFaceSnapshotService` init helper `0x49C99CFC` and independent NanoTimeKit `_NTKCanAddWatchFace` stages. **Not yet executed on the owner's Mac**; no device writes. | [`e30ff95`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/e30ff957822f5a1fd6bbef351533d4ac1cf622cd) |
| **22:05** | **V27.2 actual branch destination tracer** | Added a new offline read-only script to inspect `0x49C76990` and `0x49C2ED64`: image, function, image offset, and first 48 instructions. **Not yet executed against the owner's real cache**; no native unlock. | [`178dfc2`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/178dfc222a70a2fd1eb75a0297dd6e68665449cf) |
| **22:05** | **V27.1 owner-provided genuine 23U95 cache output** | The owner ran V27.1 on Mac. Both original addresses are `dsc.18 __TEXT_STUBS` islands. Exact `ADRP/ADD/BR` jump targets are **`0x49C76990`** (restricted-face exception) and **`0x49C2ED64`** (distinct internal-build-related stub). Four `a2f/a2o` failures reflect stub-island image lookup limitations; four disassembly windows succeeded. `--extended` was not run. No unlock. | [`a19d7c0`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/a19d7c06f1c2c534ebd5ae6796b631d21f30f2ae) |
| **21:57** | **V27.1 offline stub audit tool** | Added the read-only `a2s/a2f/a2o/disass` audit on the separate [PR #1](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/pull/1) research branch; initially only mock-tested, subsequently used by the owner. No watch modifications. | [`5ae5706`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/5ae5706b7b9993852dd21ab6ce533fc997fe672e) |
| **19:28** | **V27 restricted-face exception tracer** | Preserved V26 watchOS sandbox feasibility research; added a bounded, offline-only dyld-cache checker for distinct NanoTimeKit stubs `0x55CE73DC` and `0x55CE731C` using `a2f/a2o/disass`. Mac execution and real imported symbols remain unverified; no watch writes/unlock. | [`7217f81`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/7217f8131b70be0b2fadc7a3ec347c5dda9bd1ff) |
| **19:21** | **V26 watchOS sandbox audit** | Audited actual worse_query and WatchRegion code. WatchRegion targets watchOS 27 and reports an Ultra 4 / 27.3 beta region-cache modification, but does not validate an Ultra 1 / 23U95 exploit; current RO23 signing lacks an App Group. No exploit ran or system files changed. | [`a00a01b`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/a00a01b8792bc827e99373b40258ebdec179f524) |
| **18:54** | **V25 capability selector resolved** | Inspected genuine uploaded 23U95 Zeus/ClockKit binaries: `0x469C0` resolves to `supportsPDRCapability:`, whose ClockKit implementation at `0x49C6E724` returns true. Independently confirmed category/collection stubs and added a tested read-only stdlib verifier. Poodle stays restricted; no unlock. | [`440fc7c`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/440fc7c2e2ff91b608b4fe3a004e464ae12a1ece) |
| **18:41** | **V24 full Poodle gate** | Analyzed the actual 23U95 Zeus disassembly (29 relevant Poodle instructions among 51,891 log lines); full static method evaluates restricted for measured Ultra 1 values irrespective of the unknown capability predicate. Fixed LLVM/otool output filtering. No face unlock. | [`056cfc7`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/056cfc7b883a9e9fc87f0821c6bffd29df240680) |
| **18:33** | **V23 disassembler fallback** | Owner confirmed the 23U95 Zeus SHA-256 matches, but `llvm-objdump` was absent. Updated existing V21 script to automatically fall back to Xcode `otool` for Poodle-range disassembly, with no extra install or device changes. | [`bf32ec8`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/bf32ec8452e31539f5e3855f9ba760174530c776) |
| **18:24** | **V22.2 real-device result** | Recorded the owner's V22 Ultra 1 log: category 4, collection 9, internal build/hardware face=false. The known Poodle fallback is conditionally restricted, while the native class is not registered in the diagnostic process, so its real full-function result remains unknown. No protected writes or unlock. | [`5314247`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/531424766cc2f3d9462b6d191668869f10c2b224) |
| **18:15** | **V22.1 home fix** | Moved **V22 · Poodle eligibility** to the first Watch-home action above long V16 output; added an unmistakable V22.1 marker. No signing or system-write changes. | [`066dfd1`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/066dfd1a079b6bbc7c05cd7c46700e8cef8d1e22) |
| **18:07** | **V22** | Added the watch-home `V22 · Poodle eligibility` probe: live ClockKit/NanoTimeKit values, explicitly conditional Poodle model, and actual private class restriction only if already registered. Build and runtime not yet verified. | [`d9453c1`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/d9453c1fadff007ac933a69f0f3eb2387653964e) |
| **17:55** | **V21** | Mapped the real Circulaire file to Poodle's 23U95 Zeus restriction branch and added a read-only disassembly script; earlier branches remain unresolved. | [`2a87325`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/2a87325d31162c17da1d8d6e25b331a4fb77ec2c) |
| **17:49** | **V20.1** | Validated the 249,760-byte uploaded Circulaire ZIP and all CRCs; identified `com.apple.NTKPoodleFaceBundle`. | [`8c182a7`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/8c182a7f9e4d71211017cd0082b3ca3d64bb4230) |
| **17:35** | **V20** | Added a read-only `.watchface` ZIP/JSON/identifier/SHA-256 inspector and documented import-error distinctions. | [`315db1c`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/315db1cd08939e4bffe7fb51d1f0fde0a16979c0) |
| **17:28** | **V19.4** | Recorded the CreateWatchFace `UltraFaceWasAddedToLibrary=YES` preference and cache-build values without edits. | [`3f4b98c`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/3f4b98c940cea5a8839ee3b876bd38d3ead25c24) |
| **17:24** | **V19.3** | Verified the single `HandFactoryCachedBuild=24B5089g` key in the iPhone Watch ClockKit plist. | [`f4c60a8`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/f4c60a84e282d5ae30d6fcf843c0f347e90a1188) |
| **17:21** | **V19.2** | Recorded Filza Bridge Library, Preferences and SyncedPreferences listings and flagged sensitive sync-token paths. | [`557565d`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/557565d264553b17f1ba83dbaa61723d7ab7e0a2) |
| **17:13** | **V19.1** | Audited the uploaded Filza 27.2.2 source, verified Bridge app-container listing, and identified WebDAV/SSH risks. | [`d22a7de`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/d22a7dee6215de180eb925c1d4f25ed09d1c439b) |
| **16:55** | **V19** | Compared iOS 26 worse_query container access with iPhone–Watch pairing/face sync, finding no demonstrated watchOS write path. | [`c97e1da`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/c97e1daa80d10faf850e7455e67096b6c7c69e2f) |
| **16:44** | **V18** | Located the restricted-face lookup predicate stub `0x55CE73DC`; documented offline symbol tracing without assigning an unverified identity. | [`8fee633`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/8fee633be877108bdad637780f54f41e71ddaa30) |
| **16:37** | **V17** | Mapped NanoTimeKit registration, Bundle ID/legacy-style lookups and independent `_NTKCanAddWatchFace` eligibility checks. | [`7440080`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/74400800cb412b48ec1bfba5b680374f6518fc5c) |
| **15:56** | **V16 实机记录** | Recorded the owner's Ultra 1 results: `NTKInternalBuild=false`, `NTKShowHardwareSpecificFaces=false`, `NTKShowInternalFaces=false`. | [`fe5d177`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/fe5d17798c3c4a07995fb90094d3d09197f59749) |
| **15:42** | **V16.1** | Moved the V16 diagnostic and visible version marker onto the watch app home screen. | [`11e835f`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/11e835f23bbc807d57a6484c3f70514e116341f3) |
| **15:37** | **V16** | Added the read-only `_NTKInternalBuild` diagnostic and Poodle/Bellona hardware-face gate analysis. | [`51fe35e`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/51fe35e1db3880789c022f1552331e5b2ff28e18) |
| **15:27** | **V15** | Documented real-watch V13, V14.1 and MobileGestalt cache logs and analyzed NanoTimeKit's internal precondition. | [`b7d33b6`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/b7d33b6b88a46e5bf97f562869ddea148bf21a09) |
| **15:07** | **V14.2.1** | Renamed the colliding `Boolean` helper to `RO23ReadBool` and removed the placeholder App Group entitlement. | [`ebc7693`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/ebc7693db5bb3fc34a59a726015df8f14cd2ea44) |
| **14:58** | **资源修复** | Repaired Watch/Companion icon build assets using placeholder icons (not the original artwork). | [`e2bb4d4`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/e2bb4d4323dead5d241ba45f2f3a60da504a9097) |
| **14:55** | **V14.2 合并** | Merged upstream HermesEnabler 2, Watch App and iPhone Companion; added V13/V14.1/MG read-only probes and 23U95 UI guards. | [`bfa6f12`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/bfa6f1240ee3241cacd364749d98fb05e4c2bfb1) |

### Current evidence and limitations

The real watch reported `deviceCategory=4`, `collectionType=9`, `deviceBrand=0` and `NTKInternalBuild=false`. The verified Circulaire ZIP references `com.apple.NTKPoodleFaceBundle`; a known Poodle fallback computes “restricted” with the measured collection/hardware-face values **if that path is reached**. The complete Poodle static restriction path has been decoded in V25; the formerly unknown FaceBundleManager exception now resolves to ClockKit `_CLKIsFaceSnapshotService` in the owner's real V27.2 cache trace. That is a **snapshot-service check, not evidence of a normal watchface unlock**. Neither the snapshot-service initializer nor all ordinary add-to-library gates have been validated, and no protected system write or native Hermès activation has been demonstrated.

**Research:** [V27.2](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/blob/research/ro23-v27-1-stub-binding-audit/research/RO23-V27.2-ClockKit-Snapshot-Service.md) · [V27](research/RO23-V27-Exception-Stub-Trace.md) · [V26](research/RO23-V26-WatchOS-Sandbox-Feasibility.md) · [V25](research/RO23-V25-Poodle-Selector-ClockKit.md) · [V24](research/RO23-V24-Poodle-Full-Gate.md) · [V22](research/RO23-V22-Poodle-Runtime-Gate.md) · [V21](research/RO23-V21-Poodle-Gate-Mapping.md) · [V20.1](research/RO23-V20-Watchface-Archive-Import.md) · [V17](research/RO23-V17-FaceBundle-Loading-Chain.md) · [V16](research/RO23-V16-InternalBuild-Gate.md) · [Full changelog](CHANGELOG.md)

**Attribution:** Original HermesEnabler 2 by [Jinwoo Kim (@pookjw)](https://github.com/pookjw/HermesEnabler). RO23 watch research by [@ZhuoXuan-MY](https://github.com/ZhuoXuan-MY), with AI-assisted documentation and code changes. Preserve upstream MIT and third-party notices in [LICENSE](LICENSE) and [NOTICE.md](NOTICE.md). This fork is unofficial and is not an established watchOS 26 unlock.
