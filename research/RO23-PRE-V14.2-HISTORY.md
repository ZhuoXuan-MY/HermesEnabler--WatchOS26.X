# RO23｜V14.2 之前的完整操作史：Issue #17 原始实测与研究复盘

> **研究目标：** Apple Watch Ultra 第一代 `Watch6,18 / n199ap`，watchOS 26.6.1（`23U95`），尝试让系统真正启用原生 Hermès 表盘。**V14.2 以前并未成功修改受保护 MobileGestalt 缓存，也未成功启动原生 Hermès 表盘。**
>
> **证据来源：** 我（@ZhuoXuan-MY） 在原作者 [pookjw/HermesEnabler Issue #17](https://github.com/pookjw/HermesEnabler/issues/17) 的原帖/评论；本仓库 [RO23-STATUS.zh-CN.md](RO23-STATUS.zh-CN.md) / [RO23-STATUS.md](RO23-STATUS.md) 的 V13–V14.1 结果；现有 `HermesEnabler2/RO23Diagnostics.m` 源码。部分分析及源代码为 AI 辅助，实际 Mac/Xcode/Watch 操作由我完成。
>
> **时间规则：** 下面精确到分钟的时刻是 GitHub **Issue 发帖/评论时间（转换为北京时间 UTC+08:00）**，不能当作实机操作时间或历史 Git 提交时间。V14、V14.1 的实际执行分钟未见完整独立记录，仅证实在 V14.2 合并前。本文是后来进行的**历史补录**，不是声称 V1–V14.1 已在这些时间分别存在于本仓库的 Git commit 中。

## 0．最早的 HermesEnabler2 实机操作（RO23 编号之前）

**Issue 原帖创建时间：2026-11-10 19:57（北京时间）**；更完整的原始实机测试回顾发表于 **2026-11-10 23:20**：[原帖](https://github.com/pookjw/HermesEnabler/issues/17) · [V1–V4 补充报告](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6771229913)。

1. 由原作者 HermesEnabler2 建立本地改版，通过 Xcode 开发签名安装到 Ultra 1，确认 Watch App 能启动、`MobileContainerManager` 初始化、普通 App Group 可识别。**App Group 存在并不代表拥有 Apple 私有 SystemGroup 权限。**
2. 常规 MCM/备份访问路径遇阻后，增加**直接只读**打开 MG plist 的诊断：`MG DIRECT READ V3: SUCCESS, 13328 bytes`。匹配 `23U95` 的缓存：`CacheUUID=3BE19A76-F253-4CE4-AAC1-DF6D801CAAB1`；`CacheData=6309 (0x18A5)` 字节、`CacheExtra=72`、701 个槽位。旧 watchOS 26.5 备份 `CacheUUID=886404CC-479F-4F4B-B58C-870A08D6D22B`、13,329 字节，**未恢复到新系统**；另建并核对 `OriginalGestalt-23U95.plist`。
3. 初版 MG 描述符定位误认为 `DeviceBrand=index206 / value 0x670 / validity 0x16B6`。**此结论后来被 V3 纠错，不得用于系统写入。**
4. 开发临时 **23U95 专用强制写入测试入口**，实际走到备份验证之后，`open(..., O_RDWR|O_CLOEXEC|O_NOFOLLOW)` 返回 `errno=1 EPERM`，**未执行到 `pwrite`，从未修改 DeviceBrand 数据**。不能把“按钮触发 / 绕过版本检查”解释为系统写入成功。
5. 测试 Geod-MCM Class 12：`MG GEOD: container object unavailable`，随后直接写入同样 `EPERM`。
6. 测试受 `worse_query` 启发的 Class 7 三组 flags：`0x0800000000`、`0x8000000000`、`0x8100000000`，均为 `token=NO / consume=-5`；临时 App Group Caches 结构日志显示已恢复。**这里的 Class 7 失败不应被误写为后来的 Class 13 也没有令牌。**

## 1．RO23 V1–V4：在真实 Ultra 上确定 MG 描述符和写入失败性质

**对应 Issue #17 评论：2026-11-10 23:20（北京时间）**，[详情与原始日志](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6771229913)。代码由对话协作添加到本地 `HermesEnabler2/BQCore.m`，我在 Mac 上备份、修改、Xcode 编译并安装到手表，得到真实输出。测试工程中的定时器约为启动后 3 秒（V1）、5 秒（V2）、7 秒（V4）；**它们不是墙上时钟的测试日期**。

| 阶段 | 实际添加/运行的操作 | 观察结果、纠错或局限 |
|---|---|---|
| **V1** | 只读检查进程加载的 ARM64_32 `libMobileGestalt` Mach-O 的 cstring、`__DATA_CONST`，搜索 `fuKL2rMywRgQF1wowOA/cg` 哈希及引用 | 找到键及指针引用；最初误读取**上一条描述符的尾部**，于是出现错误 index 206 |
| **V2** | 修正 `MGCopyAnswer(CFStringRef, CFDictionaryRef)` 两参数调用，分别读取明文 `DeviceBrand` 和哈希，检查 Core Foundation 数字类型 | 两者都是 **CFNumber 0**，返回类型/长度得到核对；CFNumber 类型编码不能混作 MG 内部描述符类型 |
| **V3** | 在 V1 的只读扫描位置补充记录步长、描述符尾部/下一记录 key 指针分析；比较 100 字节记录布局 | 真实 **`flags=12 (0x0C), index=103, internal type=5`**；值偏移 **`0x338`**、presence **`0x164F`**、缓存值 0、presence 1；原来 `206/0x670/0x16B6` 错误 |
| **V4** | 读沙盒 entitlement、`sandbox_check`，直接发 Class 13 SystemGroup 查询（flags `0x0800000000`），获取并消耗 sandbox extension，对比消耗前后权限（不写文件） | **`token=YES`、`handle=2`**；普通 `application-groups` 存在，两项 Apple 私有 `system-groups` / `system-group-containers` 缺失。MG `file-read-data=ALLOW`，`file-write-data/create=DENY`，消耗 token 前后均一样；`file-write-metadata rc=-1` 是**检查错误，不是可靠 DENY 结果** |

由此证实：**“取得并激活 Class 13 token”不等于取得受保护文件写入权**；V4 是只读权限诊断，并没有再次写入系统缓存。

## 2．RO23 V5–V7：MobileGestaltHelper XPC 路径与 `error=9`

**对应 Issue 评论：2026-11-11 03:28（北京时间）**，[原始实机结果](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6777128180)；另有 [03:29 的公开实现交叉验证](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6777139375)。

| 阶段 | 实际操作 | 真实结果 |
|---|---|---|
| **V5** | 解析 `task_get_special_port` / `bootstrap_look_up`，查询 `com.apple.mobilegestalt.xpc` | `bootstrap kr=0`，有效 Mach send right；只能证明**服务可发现** |
| **V6** | 使用 `NSXPCConnection` 调 `getServerAnswerForQuestion:reply:`，只问 `DeviceBrand` | 收到回复，只有 **`error=9`**，没有 `answer`；没有调用重建缓存的接口 |
| **V7** | 对比本地 `MGCopyAnswer` 和 Helper XPC 的四问：`DeviceBrand` 明文/哈希、`BuildVersion`、`ProductType`；再检查回复字典键 | **本地四项成功**（品牌数字0、版本/型号字符串）；**XPC 四项均只有 `error=9`**，没有答案或 `logString` |

注意：XPC 业务层的 `error=9` 不是 `EPERM=1`、Mach 的 `kr` 或 MCM consume 状态；单凭 V7 不能将 9 直接定性为 entitlement 不足。

## 3．RO23 V8–V9：下载匹配 OTA，定位 `error=9` 的实际代码分支

- **V8 发布记录：2026-11-11 04:05（北京时间）**，[原始报告](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6777949079)；同一 V8 有 [重复补充版](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6778376901)，不是另一个独立新版本。我在 Mac 获取与 `Watch6,18_N199AP_23U95` 匹配的 **3,758,096,384 字节加密 AEA OTA**，`ipsw ota info/ls` 核对 Build/设备及 post.bom，针对性提取 **`usr/libexec/MobileGestaltHelper`**（76,112 字节，ARM64_32，SHA256 `0e0c05244a3d35753e948783372f18e615ae2032cf7b750dd7a9cc57cfb3626e`）。`ipsw macho disass` 曾不支持 ARM64_32，后来用 LLVM 17 完成静态反汇编；定位 `getServerAnswerForQuestion:reply:` at `0x5110`，实际调用 `_MGServerCopyAnswerWithError` at `0x51C4`；还找到 `rebuildCache:`、`setCacheSentinel:` 等**系统内部方法**，但**未调用重建缓存**。
- **V9 发布记录：2026-11-11 04:25（北京时间）**，[原始报告](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6778385658)；另附 [反汇编摘录一](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6778394165)、[摘录二](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6778403169)。进一步分析匹配固件的 **991,764 字节 `libMobileGestalt.dylib`**（ARM64_32，SHA256 `383dfd64b790ba505760bb4af7a08ed2df185cbf6fffca64a13608f9bdcc2baf`）。确认 `_MGServerCopyAnswerWithError` 在 `0x215B42A8`，访问检查从 `0x215B4BF4`；有关服务问题描述符的标志/回调能走到业务层 `error=9`。V7 四问对应的普通本地查询**不因此获得 Server API 访问资格**；静态代码解释不能冒充四次动态单步追踪。
- 还在匹配库里独立确认 `DeviceBrand=index103 / type5 / flags0x0C`。其 provider 读取 `IODeviceTree:/chosen` 的 `marketing-software-behavior`，**与 MG 缓存值属于不同数据层次**。

## 4．RO23 V10–V12：查找真实原生 Hermès 表盘和资格链

**Issue 汇总发布：2026-11-11 05:27（北京时间）**，[V1–V12 全量中英史料](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6779723360)。V10–V12 是基于本地提取固件的资料和研究结果整理，**不是三篇具有独立时间戳的 Issue 评论**。

| 阶段 | 实际做了什么 | 收获与边界 |
|---|---|---|
| **V10** | 查找 OTA BOM 并从匹配 `23U95` 固件提取 `NTKHermes2025FaceBundle`、`Carousel`、`ClockFace`、`nanotimekitd` | 证明 **原生 Hermès 2025 FaceBundle 的实现资源确实在这个固件里**；`nanotimekitd` 也有可用性筛选相关调用。*文件存在 ≠ 手表有权启动该表盘* |
| **V11** | 分析 **11,395,800 字节** `NanoTimeKit` 和 Hermes2025FaceBundle 反汇编 | 定位 FaceBundle Manager、`_NTKFaceStyleIsAvailable`、`NTKFaceDescriptor isAvailableForDevice:` 等检查，以及 `Hermes2025Face.isRestrictedForDevice:` 内的 `deviceCategory`、`supportsFall2025FacesCapability`、`collectionType` 门槛；不能证明改 DeviceBrand 就能全部通过 |
| **V12** | 分析 **1,425,840 字节**匹配 `ClockKit`（`RO23-V12-ClockKit.zip`），验证 `CLKDevice` 属性访问器及 NanoRegistry/PDR 能力查询相关代码 | `deviceBrand`、`deviceCategory`、`collectionType`、`isUltra` 属于**不同的设备对象字段**；静态函数存在不等于测到了真机资格或绕过限制 |

## 5．RO23 V13、V14、V14.1：表盘硬件分类与本地诊断修正

- **V13：Issue 评论发表于 2026-11-11 13:46（北京时间）**：[Hermès 2025 实际代码分析](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6788186063)。对照 Hermès2025FaceBundle 与 ClockKit 证实 `+[Hermes2025Face isRestrictedForDevice:]` 的类别白名单为 **`{2,3,5}`**；Ultra 1 的**真实手表日志**记录 `sizeClass=6`、`deviceCategory=4`、`collectionType=9`、`deviceBrand=0`、`isUltra=true`。**类别4不属于白名单**。对 Hermès 2025 路线，单改 `DeviceBrand` 未被证明能改变由尺寸等级映射来的 `deviceCategory`，因此不是完整解锁。静态分析和手表诊断结果需区分。
- **V14：完成于 V14.2 合并前，但未见准确的 GitHub 公开执行分钟**。分析对应 `NTKZeusFaceBundle` 的 Zeus Analog、Spectrum 以及 Hades/Secretariat 的硬件专属/型号资格。手表只读诊断发现 **`isZeusBlack=false`、`NTKShowHardwareSpecificFaces=false`**；所研究的正常判断路线报告为受限。此阶段不是把 Zeus 全部表盘成功启用。[本仓库早期摘要](RO23-STATUS.zh-CN.md)。
- **V14.1：完成于 V14.2 合并前，准确分钟未证实**。修复对 `CLKDevice.deviceBrand` 的错误 Objective-C 返回值强制转换；之前出现 **399803152** 这类对象指针误读数字，实际类型为 **`__NSCFNumber`、数值0**。本仓库 `RO23Diagnostics.m` 已使用对象返回并打印类名；**这不是修改成功，而是读取正确**。[本仓库早期摘要](RO23-STATUS.zh-CN.md)。

## 6．V14.2 合并是历史和 GitHub 新工程的分界

**2026-11-11 14:55（北京时间）**，本仓库 GitHub [V14.2 合并提交](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/bfa6f1240ee3241cacd364749d98fb05e4c2bfb1)把最新上游 HermesEnabler 2 的 Watch App、iPhone Companion、Xcode 工程，与 V13/V14.1 的只读探针/缓存快照结合。**旧 V1–V7 实验是 V14.2 之前在我的 Mac 的本地工程中运行，不等于当时已逐项提交到本仓库 main 的独立 Git commit。** 仓库快照做了防误用清理：移除错误的 206/0x670 强行写入实现，隐藏 23U95 上的危险写入及重启控制，保留研究记录/只读入口。**V14.2 是项目整理和代码合并，不是 Hermès 解锁成功。**

## 7．纠错记录：这些结论绝不能混淆

| 容易造成的错误结论 | 已证实的正确结论 |
|---|---|
| `DeviceBrand index=206 / value=0x670` | 那是前一描述符尾部，真正键是 **index103 / value0x338 / presence0x164F** |
| “Class 7 没有 token，所以 Class 13 也没有” | Class 7 三组为 NO TOKEN；**Class 13 后来取得并消耗 token，却仍无法写** |
| `sandbox_check file-write-metadata rc=-1` = DENY | **-1 是检查错误**；明确的 DENY 来自 `file-write-data/create rc=1` 和真实 `open(O_RDWR)` 的 `EPERM` |
| `MobileGestaltHelper error=9` = `EPERM` 或纯粹 entitlement 故障 | 这是 **XPC 回答中的业务层错误码**；匹配固件代码确认有 Server API 描述符门槛，不能互换错误类别 |
| 把 `CLKDevice.deviceBrand` 返回对象指针当数字 | 修正为 `__NSCFNumber(0)`，曾显示的 399803152 是误读 |
| `NTKHermes2025FaceBundle` 存在 = 可以打开 | 固件包含表盘代码**不意味着**系统资格、添加、持久化与实际显示均通过 |
| 读、备份成功 = 可以写系统文件 | **不成立**。实机写入在 `open(O_RDWR)` 被 EPERM 拒绝，没有实际更改任何 MG 字节 |

## 8．项目成果与没完成的事

**做到了：** 能跑的本地 Watch 诊断版本；真实设备的 MG 读取/匹配备份；更正后的 DeviceBrand 描述符；量化沙盒和 XPC 访问边界；拿到与目标设备/构建对应的加密 OTA 并静态分析 Helper、libMobileGestalt、NanoTimeKit、ClockKit、Hermès 2025 原生表盘；确认真实 Ultra 1 的表盘资格部分条件；后来在 V14.2 把有用的只读功能整理进 GitHub。

**没做到：** 受保护系统缓存写入、重建/强制写入成功、修改 DeviceBrand 生效、通过所有 Hermès 表盘资格检查、将原生 Hermès 表盘安装/添加并持续显示。**最终状态：NOT UNLOCKED。**

文档范围截止 V14.2 合并之前；V14.2 后的 V15–V29 见 [README](../README.md) 后续按 GitHub commit 时间编排的开发日志。 **Issue #17 是研究者主动公开的完整报告，不等于原项目维护者确认解锁路径或发布兼容版本。**
