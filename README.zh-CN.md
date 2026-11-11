# RO23 开发日志｜Apple Watch Ultra 1 · 23U95

**研究进度截至：2026-11-11 18:07（马来西亚时间，UTC+08:00）**  
**研究设备：** Apple Watch Ultra 第一代（Watch6,18 / n199ap）· watchOS 26.6.1（23U95）  
**当前结果：原生 Hermès 表盘尚未解锁。**

这里按**实际 GitHub 提交时间**记录我们对 RO23 衍生项目的每次修改、验证资料的入库和技术判断。以下“几点几分”来自 GitHub commit 的 UTC 时间换算为马来西亚时间；**不是声称在该分钟直接操作、刷写或测试了你的手表**。实际手表诊断由设备所有者运行，源码与报告修改有 AI 辅助。

## 2026 年 11 月 11 日｜逐分钟开发记录（新 → 旧）

| 时间 (MYT) | 版本 | 具体做了什么 | GitHub 提交 |
|---|---|---|---|
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

## 当天已确认的实机数据

| 项目 | 已确认结果 | 意义 |
|---|---|---|
| **设备 / 系统** | Watch6,18 / watchOS 26.6.1 / `23U95` | RO23 研究对象，不等于上游正式支持的系统范围 |
| **V13/V14.1** | `deviceCategory=4`, `collectionType=9`, `deviceBrand=0`, `isUltra=true` | 真实 ClockKit/MobileGestalt 属性 |
| **V16** | `NTKInternalBuild=false`, `NTKShowHardwareSpecificFaces=false`, `NTKShowInternalFaces=false` | 已验证内部构建版本前置条件未通过 |
| **Hermès 2025** | 类别白名单 `{2,3,5}` 不包含类别 `4` | 2025 表盘已知类别限制失败 |
| **Hermès Circulaire** | `com.apple.NTKPoodleFaceBundle`，原始 ZIP/CRC 校验成功 | 文件真实有效，但这不代表手表能够安装 |
| **Poodle 的已识别后续分支** | `collectionType=9` 且硬件表盘开关为 `false` | **若执行到该分支**，计算结果为受限制；前置分支尚未完全复核 |
| **系统写入与解锁** | 未发现可验证的受保护写入方法；**未解锁** | 不能把只读诊断或离线分析描述为破解成功 |

## 研究文件与源码

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
