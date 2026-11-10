# HermesEnabler RO23 — Apple Watch Ultra 1 / watchOS 26.6.1 研究分支

[English](README.md) · **简体中文** · [上游 HermesEnabler 2](https://github.com/pookjw/HermesEnabler) · [原始研究 Issue #17](https://github.com/pookjw/HermesEnabler/issues/17)

> [!IMPORTANT]
> **研究状态：未解锁 / 未验证可用。** 本仓库是基于 **Jinwoo Kim（[@pookjw](https://github.com/pookjw)）原作 [HermesEnabler](https://github.com/pookjw/HermesEnabler)** 以及 **[@ZhuoXuan-MY](https://github.com/ZhuoXuan-MY)** 实机研究创建的非官方衍生研究分支。它**不是**已适配 watchOS 26.6.1 的稳定解锁工具；在本文档记录的实机上，**没有成功修改受保护的 MobileGestalt 缓存，也没有启用原生 Hermès 表盘**。
>
> **特别安全警告（2026-11-11 源码审计）：上传的本地研究版 `HermesEnabler2/BQCore.m` 的 `BQWriteHermes23U95()` 仍硬编码了已被研究推翻的 `0x670` / `0x16B6` 偏移！这些偏移属于错误识别的索引 206，**不是 DeviceBrand**。不要把这个分支当作可用功能执行，不要点击 23U95 的 Enable Hermès，不要发布为即装即用 IPA。必须先去除或禁用这条写入路径，才能考虑公开分发研究版源码。下面保留该历史事实仅用于审计与追踪。

## 目录

1. [项目介绍与开发者署名](#1-项目介绍与开发者署名)
2. [与原版 HermesEnabler 的关系](#2-与原版-hermesenabler-的关系)
3. [适用设备、支持状态和能力边界](#3-适用设备支持状态和能力边界)
4. [实际代码：本地研究版包含哪些修改](#4-实际代码本地研究版包含哪些修改)
5. [RO23 V1–V12 完整研究时间线](#5-ro23-v1v12-完整研究时间线)
6. [DeviceBrand：纠正后的关键事实](#6-devicebrand纠正后的关键事实)
7. [为什么 XPC 返回 error=9](#7-为什么-xpc-返回-error9)
8. [真正的 Hermès 表盘在固件中的位置](#8-真正的-hermès-表盘在固件中的位置)
9. [V11–V12：设备能力和表盘限制](#9-v11v12设备能力和表盘限制)
10. [已确认、尚未确认与失败的尝试](#10-已确认尚未确认与失败的尝试)
11. [源码结构与本地构建](#11-源码结构与本地构建)
12. [公开发布前必须完成的清理](#12-公开发布前必须完成的清理)
13. [研究方法、复现与数据证据](#13-研究方法复现与数据证据)
14. [后续研究计划](#14-后续研究计划)
15. [原作者、许可、致谢](#15-原作者许可致谢)
16. [免责与相关链接](#16-免责与相关链接)

## 1. 项目介绍与开发者署名

**HermesEnabler RO23** 是 Apple Watch Ultra 第一代（`Watch6,18` / `n199ap`）在 **watchOS 26.6.1（`23U95`）** 下的原生 Hermès 表盘兼容性、MobileGestalt 机制、系统沙盒以及 NanoTimeKit 表盘准入的研究项目。

项目包含两个不同来源，必须明确区分：

- **原创软件及主体实现**：**Jinwoo Kim / @pookjw** 的 [HermesEnabler / HermesEnabler 2](https://github.com/pookjw/HermesEnabler)。项目的系统组件访问思路、已有应用结构、通用表盘能力开关、备份与恢复流程等上游工作归属原作者及相关上游贡献者。
- **RO23 衍生研究、现场测试与实验版修改**：**[@ZhuoXuan-MY](https://github.com/ZhuoXuan-MY)**。设备所有者在自己的 Mac、Xcode 与 Apple Watch 上编译并运行魔改版，提供设备日志和固件提取文件；研究中使用 AI 辅助生成诊断代码、整理输出和开展静态逆向。**AI 辅助不等于独立完成实机验证**，也不改变上游作者归属。

**为什么建立独立仓库？** 上游应用的主要受支持范围和本项目研究的 watchOS 26.6.1 不同。独立分支用于公开失败路径、可复核二进制证据、错误更正和仍未解决的技术问题，避免把实验诊断误当成官方兼容功能。

**本项目不是 Apple、Hermès 或 @pookjw 的官方发行版，也不声称获得他们的认可。** 名称中的 Hermès 是用于标识所研究的表盘技术；商标属于各自权利人。

## 2. 与原版 HermesEnabler 的关系

上游项目：[pookjw/HermesEnabler](https://github.com/pookjw/HermesEnabler)。其 README 在本报告编写时表示支持 **watchOS 27.0 至 27.3 beta 1**；该范围属于**上游声明**，**不等于这个 RO23 分支已支持同样范围**。原版提供 `HermesEnabler2.xcodeproj`、Swift 应用界面、`BQCore.m` 等核心功能，部分实现亦借鉴 [Gester](https://github.com/sasobhabha/Gester)。

上传的 `HermesEnabler(1).zip` 是一个**本地修改快照**，保留了 `HermesEnabler/`（旧项目）、`HermesEnabler2/`、两个 Xcode project 文件以及多份 `.before-*` 源码备份。它**并不是经过整理、审计或签名发布的最终发行版本**。它的 README 原先基本只有标题，不能替代本文件。

> 原版和本版需分别看待：**原作者负责最初的 HermesEnabler 产品和上游支持；RO23 贡献者负责自己的 23U95 研究与诊断性修改**。不能将本分支的错误或实验结论归咎于原作者。

## 3. 适用设备、支持状态和能力边界

| 项目 | 当前情况 |
|---|---|
| 研究设备 | Apple Watch Ultra（第一代） |
| 产品标识 | `Watch6,18`；board `n199ap` |
| 实测系统 | watchOS `26.6.1`；build `23U95` |
| 二进制 ABI | `arm64_32`（ILP32） |
| 运行环境 | 原配对设备及 Mac / Xcode；本地开发者签名的 Watch App |
| MobileGestalt 读取 | **已成功** |
| 同版本缓存备份和解析 | **已成功** |
| SystemGroup 写权限 | **未取得**；实际写入打开失败 `EPERM` |
| `com.apple.mobilegestalt.xpc` 连接 | **已成功**；询问返回 `error=9` |
| 原生 Hermès 2025 FaceBundle 文件 | **已在对应 OTA 中发现并提取** |
| Hermès 2025 特定限制代码 | **静态已定位**；运行时结果未验证 |
| 原生 Hermès 表盘启用 | **尚未成功** |
| 可公开发布的安装 IPA | **尚无经验证的 RO23 发行版** |

这些数据**仅证明一台 Ultra 1 上的结果**。同属 `23U95` 的其他机型、不同构建及 watchOS 27 可能具有不同缓存布局、限制和授权策略。**切勿把 index、offset 和对象地址直接当成通用补丁。**

## 4. 实际代码：本地研究版包含哪些修改

以下内容来自用户提交的 `HermesEnabler(1).zip` 的 **`HermesEnabler2/BQCore.m`、`BQCore.h`、`ContentView.swift`、entitlements 与 Xcode 工程**，而不是仅凭 Issue 推断。

| 模块 / 部分 | 本地研究版中的具体内容 | 状态与注意 |
|---|---|---|
| `BQCoreInit` / MCM 动态加载 | 加载 MobileContainerManager 符号、容器查询、sandbox extension consume/release | 继承和实验性扩展混合；不代表成功取得目标写权限 |
| MG 读取、备份、结构校验 | 读取 `com.apple.MobileGestalt.plist`，核对 `CacheUUID`、`CacheData`、`CacheExtra`，保存版本对应备份 | 在 23U95 有实际成功日志 |
| `BQProbeClass7Flags23U95` | 对 3 组 Class 7 flags 比较结果并恢复应用自己的 Caches 路径 | 所有 3 组测试均无可用 token |
| `BQGeodOpen23U95` | 用 Geod-MCM 相关流程探查容器对象 | 未取得目标容器；写权限不变 |
| `BQWriteHermes23U95` | 23U95 专用校验、备份、尝试 `O_RDWR` 和 `pwrite` 的实验路径 | **危险的历史试验代码；包含已过时的错误偏移，必须禁用/移除** |
| `RO23_AUTORUN_DIAGNOSTIC_V1` | 自动分析本机 MobileGestalt Mach-O、缓存候选槽和 key 引用 | 只读；首次启动后延迟执行 |
| `RO23_TYPE_CHECK_V2` | 用 `MGCopyAnswer` 读取 DeviceBrand 的明文及哈希 key，判断 CFNumber 类型 | 只读 |
| `RO23_RECORD_V3` | 观察描述符边界、100 字节 stride、邻接描述符与缓存 index | 确认旧 index=206 解读错误 |
| `RO23_SANDBOX_V4` | Class 13 token、私有 entitlement 是否存在、调用 `sandbox_check` 比较系统与应用文件 | 权限诊断；不执行系统写入 |
| `RO23_HELPER_V5` | `bootstrap_look_up` 查找 `com.apple.mobilegestalt.xpc` | 服务存在且可取得 send right |
| `RO23_V6_XPC_QUERY` | 一次 DeviceBrand 只读 XPC 请求 | 收到 `error=9` |
| `RO23_V7_XPC_COMPARE` | 4 个查询对比本地 `MGCopyAnswer` 与 Helper XPC 回复 | 本地有值，Helper 无值、返回 9 |
| `ContentView.swift` | 添加兼容性、MG 访问、Class 7 诊断、Hermès 尝试的可见输出与日志 | **不能把按钮显示当作解锁成功** |

**特别注意自动执行行为：** 你上传的 `BQCore.m` 使用多个 `__attribute__((constructor))` 加 `dispatch_after`，会在应用启动后约 **3、5、7、10、13、26 秒**分别执行只读诊断。上游仓库不一定包含这些修改。公开发布前，应让使用者可以主动选择何时运行诊断，而不是未阅读说明就自动运行所有实验。

**最重要的代码安全债务：** `BQWriteHermes23U95()` 目前仍用 `valueOffset=0x670` 和 `presentOffset=0x16B6`。研究已证明它们不属于 DeviceBrand！虽然这台手表上 `open(O_RDWR)` 实际被沙盒拒绝，**不能以“目前写不进去”为理由容许错误偏移代码继续存在**；若未来某个版本突然获得权限，错误写入可能破坏无关缓存条目。

## 5. RO23 V1–V12 完整研究时间线

### 5.1 最初阶段：备份、MG 读取、错误布局与写入失败

实验初期，开发者对上游 HermesEnabler2 做了本地适配，设置自己的 App Group，在 Watch6,18 / 23U95 安装并打开应用。MCM 常规路径受限，但通过直接文件读取成功取得实机 MG plist，**13,328 字节**，并获得以下结构：

```text
CacheUUID:     3BE19A76-F253-4CE4-AAC1-DF6D801CAAB1
CacheData:     6309 bytes (0x18A5) = 701 × 9 bytes
CacheExtra:    72 entries
Live MG API:   DeviceBrand = 0
```

旧的 watchOS 26.5 备份大小为 13,329 字节、CacheUUID 不同；研究版拒绝用它覆盖当前系统，并建立单独的 `OriginalGestalt-23U95.plist` 备份。最初误将 DeviceBrand 识别为 **index 206 / type 11 / `0x670`**，这项结论已被后续研究**正式废止**。

点击 Enable Hermès 后，本地新增的 23U95 试验路径被执行，备份验证成功，但试图以 `O_RDWR | O_CLOEXEC | O_NOFOLLOW` 打开系统缓存时得到：

```text
MG FORCE: entering 23U95 write path
MG FORCE: 23U95 backup verified
MG FORCE: WRITE DENIED errno=1 (Operation not permitted)
```

因此这次尝试**没有执行目标 `pwrite`，没有修改 DeviceBrand**。之后 Geod-MCM 的 Class 12 路线未得到容器对象；Class 7 的三组 flags `0x0800000000`、`0x8000000000`、`0x8100000000` 均无可用 sandbox token，临时 App Group Caches 操作显示恢复成功。

### 5.2 RO23 V1 — 只读关键字和 Mach-O 描述符扫描

在实机进程内解析 `arm64_32` Mach-O 的 `__TEXT,__cstring` 和 `__DATA_CONST` 等区域，精确查找 DeviceBrand 的哈希 key `fuKL2rMywRgQF1wowOA/cg`，并追踪引用关系。发现一个 key 字符串和多个引用，包括描述符表和 Core Foundation 字符串引用。此时**不应从 key 指针之前的任意 8 字节猜出对应描述符索引**。

### 5.3 RO23 V2 — 本地 API 类型复核

使用正确的双参数 ABI `MGCopyAnswer(CFStringRef, CFDictionaryRef)` 对普通和哈希的 DeviceBrand 提问，均返回 `CFNumber(0)`；将 `cfNumberType=3`（四字节 CF 数值类型）与 MobileGestalt **内部**类型编号分开记录。没有写入。

### 5.4 RO23 V3 — 纠正 DeviceBrand 描述符

确认 `arm64_32` 目标描述符的 100 字节（`0x64`）布局，DeviceBrand 自身的尾部元数据为：

```text
flags = 12 (0x0C)
index = 103 (0x0067)
type  = 5
value offset    = 103 × 8 = 0x338
validity offset = 701 × 8 + 103 = 0x164F
value = 0, validity = 1
```

先前 `0D 00 CE 00 0B 00 00 00` 对应的是**前一个记录** `flags=13, index=206, type=11` 的尾部，不能用来修改 DeviceBrand。`206 / 2 = 103` 是巧合，不是算法规则。

### 5.5 RO23 V4 — Class 13 token 与沙盒权限隔离

使用 `Class 13 + flags=0x0800000000` 查询受保护 `systemgroup.com.apple.mobilegestaltcache`，拿到 token 并成功消费（本次测试 `handle=2`）。但 `sandbox_check` 仍然返回：

```text
MG BEFORE file-read-data    rc=0 ALLOW
MG BEFORE file-write-data   rc=1 DENY
MG BEFORE file-write-create rc=1 DENY
MG AFTER  file-read-data    rc=0 ALLOW
MG AFTER  file-write-data   rc=1 DENY
MG AFTER  file-write-create rc=1 DENY
```

普通 `com.apple.security.application-groups` entitlement 存在；`com.apple.security.system-groups` 和 `com.apple.security.system-group-containers` 在被测进程中不存在。测试中的 `file-write-metadata rc=-1` 代表**错误，不是拒绝结论**。结果表明：**获得并消费 token，并不等于拥有写权限**。此 V4 诊断没有实际写入系统文件。

### 5.6 RO23 V5 — Mach Service 服务发现

利用 `task_get_special_port` 和 `bootstrap_look_up` 查找 `com.apple.mobilegestalt.xpc`，得到 `kr=0` 和有效 send right。这只证明服务可找到，不是权限提升。

### 5.7 RO23 V6 — 首次只读 XPC 查询

创建指向 Helper 的 `NSXPCConnection`，调用 `getServerAnswerForQuestion:reply:` 查询 `DeviceBrand`；服务**确实回复**，但仅有 `error=9`，无 `answer`。本次没有调用 `rebuildCache:` 或 `setCacheSentinel:`。

### 5.8 RO23 V7 — 本地与 Helper 的四问比较

| 问题 | 本地 `MGCopyAnswer` | Helper XPC |
|---|---|---|
| `DeviceBrand` | `NSNumber(0)` | `error=9`、无答案 |
| `fuKL2rMywRgQF1wowOA/cg` | `NSNumber(0)` | 同上 |
| `BuildVersion` | 返回字符串 | 同上 |
| `ProductType` | 返回字符串 | 同上 |

回复字典**只有 `error` 字段**，没有 `answer` 或 `logString`。这不是 MCM `-5`、Mach `kr` 或 POSIX `errno=1`；不能把它们混为一谈。

### 5.9 RO23 V8 — 取得精确版本固件与 Helper 反汇编

从目标 `Watch6,18`、`23U95` 的加密 **AEA OTA** 中提取资源列表、post.bom 和 `usr/libexec/MobileGestaltHelper`（`payload.054`）。固件信息确认 watchOS `26.6.1`、构建 `23U95`、架构 `arm64_32`。原始 Helper 文件 76,112 字节，`SHA-256` 见下文。

`ipsw macho info` 成功识别二进制，但对 ObjC 元数据报 `__objc_protolist unexpected EOF`，原版 `ipsw macho disass` 错误拒绝 `arm64_32`。改用 LLVM 直接解析后恢复方法：

| 方法 | Helper 内地址 |
|---|---:|
| `getServerAnswerForQuestion:reply:` | `0x5110` |
| `rebuildCache:` | `0x55F0` |
| `setCacheSentinel:` | `0x5714` |

在 `0x51C4` 找到了对 `_MGServerCopyAnswerWithError` 的真实 `bl` 调用，Helper 再将底层输出整理成 `error`、可选 `answer`、可选 `logString`，传给回复回调。它自己并非任意 DeviceBrand setter；`rebuildCache:` 也不是安全的修改接口。

### 5.10 RO23 V9 — 逆向匹配版本的 libMobileGestalt

从与固件一致的 `dyld_shared_cache_arm64_32` 导出 `/usr/lib/libMobileGestalt.dylib`（991,764 字节）。直接追踪 `_MGServerCopyAnswerWithError`（`0x215B42A8`）与服务器访问判定（研究标记 `0x215B4BF4`），发现 `error=9` 在该库内部有明确分支。

针对三个明文问题的描述符：

| 问题 | 缓存索引 | 内部类型 | flags |
|---|---:|---:|---:|
| `DeviceBrand` | `103` | `5` | `12` (`0x0C`) |
| `BuildVersion` | `62` | `9` | `12` (`0x0C`) |
| `ProductType` | `530` | `9` | `12` (`0x0C`) |

该服务器查询路径的限制位/访问逻辑提供了 V7 中 `error=9` 的代码级解释，**但当时四次设备请求并未进行动态逐指令跟踪**，因此不宜把静态路径解释成唯一已动态验证的原因。DeviceBrand 的底层 provider 读取 `IODeviceTree:/chosen` 下的 `marketing-software-behavior` 数据，和缓存中的值属于不同层次。

### 5.11 RO23 V10 — 系统中发现原生 Hermès FaceBundle

扫描同一目标固件的 OTA BOM 后，发现并提取：

| 文件 / 模块 | 大小（约） | 角色 |
|---|---:|---|
| `NTKHermes2025FaceBundle.bundle/NTKHermes2025FaceBundle` | 1.2 MB | 原生 Hermès 2025 表盘代码 |
| `NTKHermes2025FaceBundle.bundle/Assets.car` | 32 KB | 随附资源 |
| `System/Library/CoreServices/Carousel.app/Carousel` | 185 KB | 表盘界面相关程序 |
| `Applications/ClockFace.app/ClockFace` | 406 KB | 表盘相关应用 |
| `NanoTimeKit.framework/nanotimekitd` | 734 KB | 表盘管理服务 |

在 `nanotimekitd` 中确认 `com.apple.Hermes2025Face`，以及对 `_NTKFaceStyleIsAvailable` 的调用（示例位置 `0x8260`）；系统具有记录 `Removing unavailable faces`、`Removing face of style %@` 的过滤逻辑。**存在于 OTA ≠ 一定对普通 Ultra 开放；完整运行资源及所有限制仍需验证。**

### 5.12 RO23 V11 — NanoTimeKit 与 Hermès 自身限制

从同版本 dyld 缓存中单独提取 **11,395,800 字节的 `NanoTimeKit`**。其 `_NTKFaceStyleIsAvailable`（`0x544392B0`）、`-[NTKFaceDescriptor isAvailableForDevice:]`（`0x543D998C`）和 Bundle Manager 方法（`0x544B0DDC`）显示表盘通常受通用可用性及 Bundle 检查双重约束。

进一步在 Hermes 2025 FaceBundle 中定位了 `+[Hermes2025Face isRestrictedForDevice:]`（`0x3B2C`），后者通过内部逻辑检查 **`deviceCategory`、`supportsFall2025FacesCapability`、`collectionType`**，其中 `collectionType` 与 `0x5` 比较。管理器在枚举或添加表盘时可能使用 `isRestrictedForDevice:`。**目前没有 Ultra 1 对这些函数实际返回值的现场日志；不能断言仅更改 DeviceBrand 足以通过验证。**

### 5.13 RO23 V12 — ClockKit 设备对象补充验证（本版最新）

用户提供 `RO23-V12-ClockKit.zip`，解压得到 **1,425,840 字节**的原生 `arm64_32` **`ClockKit`** 动态库。经本次检查，存在 `CLKDevice` 设备对象、`_loadDeviceInfo`、`_queryAndCacheNanoRegistryDeviceCapabilities`、`_supportsCapabilityUncached:` 及多个设备属性访问器。

从文件内的实际指令可以复核：

```asm
-[CLKDevice deviceBrand]      0x49C6F144: ldr  w0, [x0, #0x3c]
-[CLKDevice deviceCategory]   0x49C30EB4: ldr  w0, [x0, #0x2c]
-[CLKDevice collectionType]   0x49C354F0: ldr  w0, [x0, #0x30]
-[CLKDevice isUltra]          0x49C6F11C: ldrb w0, [x0, #0x17]
```

这些是**对 `CLKDevice` 实例字段的 getter**，不等于它们在这一行计算了 DeviceBrand 或判断 Hermès。`CLKDevice _loadDeviceInfo` 会装载设备相关资料，`_queryAndCacheNanoRegistryDeviceCapabilities` 关联 NanoRegistry/PDR 能力查询。**在这份 ClockKit 二进制的字串中未找到 `supportsFall2025FacesCapability` 的直接定义；能力选择器可能属于其他 Framework、分类或外部调用，尚待继续解析。**

**V12 状态是“提取并完成部分静态核查”，不是完成了 Ultra 1 的设备能力实测或解锁。**

## 6. DeviceBrand：纠正后的关键事实

DeviceBrand 是 MobileGestalt 的设备品牌数值，哈希 key 为：

```text
DeviceBrand -> fuKL2rMywRgQF1wowOA/cg
```

在此 `23U95` 实机上的缓存槽计算为：

```text
CacheData length       = 0x18A5 = 6309 bytes
Slots                  = 701
Descriptor stride      = 100 bytes on observed arm64_32 layout
DeviceBrand flags      = 12
DeviceBrand cacheIndex = 103
DeviceBrand type       = 5
Value                  = CacheData[0x338 ... 0x33B] = 0
Validity               = CacheData[0x164F] = 1
```

**严禁将旧的 206 / 0x670 / 0x16B6 当作 DeviceBrand。** 旧值与正确值恰好都为零，因此只看结果值相等无法证实索引正确，必须依赖描述符自身边界与元数据。即使正确知道内存偏移，也**不会自动获得文件写入授权或系统表盘可用性权限**。

## 7. 为什么 XPC 返回 error=9

Helper 连接和本地查询表现不同：

```text
Local MGCopyAnswer(DeviceBrand)         -> CFNumber(0)
Helper.getServerAnswerForQuestion(...)   -> { "error": 9 }
```

V8 在 Helper 的 `0x51C4` 确认调用 `_MGServerCopyAnswerWithError`；V9 对本机型匹配版本的 libMobileGestalt 逆向确认错误码 9 的分支以及服务器查询标志处理。`DeviceBrand`、`BuildVersion`、`ProductType` 均具有 flags `0x0C`；它们能用本地 API 读取，**不表示适合用服务器专用 XPC API 读取**。

这个发现**不授予**任意缓存写入能力。不要重复使用 `rebuildCache:` 检测是否绕过错误；缓存重建可能删除或重写活动缓存，不是无害探针。

## 8. 真正的 Hermès 表盘在固件中的位置

以下是 `Watch6,18 / 23U95` Full OTA 的 **BOM 证据和实际提取目录**（对应 Apple 固件文件，不应当重新上传这些 Apple 二进制到自己的仓库）：

```text
System/Library/NanoTimeKit/FaceBundles/
  NTKHermes2025FaceBundle.bundle/
    NTKHermes2025FaceBundle
    Info.plist
    Assets.car
    hermes-*.plist (many resources in OTA)
System/Library/PrivateFrameworks/NanoTimeKit.framework/
  nanotimekitd
System/Library/CoreServices/Carousel.app/Carousel
Applications/ClockFace.app/ClockFace
```

原生资源的存在表明相关逻辑由 watchOS 自身携带；但系统可能因设备能力、注册规则、Bundle 检查和资源要求进行筛除。本项目目的不是制作第三方相似表盘，而是用静态研究解释原生组件的可用性边界。

## 9. V11–V12：设备能力和表盘限制

```text
User selects a face
  -> NanoTimeKit/face catalog
  -> NTKFaceStyleIsAvailable (general check)
  -> FaceBundle lookup and descriptor availability
  -> Hermes2025Face isRestrictedForDevice: (Hermès-specific check)
  -> deviceCategory / collectionType / supportsFall2025FacesCapability
  -> only if all relevant checks pass: potential visibility / addition
```

**这张图是从多个静态调用点整理的研究模型，不是经过完整端到端动态追踪的执行栈。** `CLKDevice` 的属性访问器在 ClockKit 内得到独立验证，但**谁填充这些字段、Ultra 1 的运行时值、具体许可设备集合和每个分支的组合条件仍未完全证实**。

因此“更改 DeviceBrand=1 就能直接解锁所有 Hermès 2025 表盘”不是本研究能支持的结论。

## 10. 已确认、尚未确认与失败的尝试

| 事项 | 证据级别 | 当前结论 |
|---|---|---|
| 实机读取 MobileGestalt | 设备日志 | 成功，13,328 B |
| 创建匹配 23U95 的备份 | 设备日志 | 成功；未覆盖旧 26.5 备份 |
| 更正 DeviceBrand index=103 | 实机描述符 + 后续库静态分析 | 强证据支持 |
| 直接目标写入（`O_RDWR`） | 设备日志 | `EPERM`，无写入 |
| Geod-MCM | 设备日志 | 未取得对应容器对象 |
| Class 7 三种 flag | 设备日志 | 均无可用 token |
| Class 13 token | 设备日志 | token 被成功消费，但写权限仍 DENY |
| Helper Mach service / XPC | 设备日志 | 服务可连接；有结构化回复 |
| Helper 的 `error=9` | 设备日志 + 原生库静态分析 | 服务器 API 限制提供合理代码级解释 |
| DeviceBrand 从 DeviceTree 来源读取 | 原生库静态分析 | `marketing-software-behavior` provider 相关 |
| Hermès 2025 Bundle 在 OTA 中 | 目录和实提文件 | 成功发现与导出 |
| `isRestrictedForDevice:` | FaceBundle + NanoTimeKit 静态分析 | 确有专属条件 |
| ClockKit `CLKDevice` 属性 | V12 原生二进制静态分析 | 已验证 getter 指令 |
| Ultra 1 的 Fall 2025 capability 返回值 | 未现场验证 | 未知 |
| 原生表盘成功显示或添加 | 未成功 | **未解锁** |

## 11. 源码结构与本地构建

用户提交的本地存档大致包含：

```text
HermesEnabler/
├── HermesEnabler2.xcodeproj/       # 主要实验 Watch App 工程
├── HermesEnabler2/
│   ├── BQCore.m                    # 上游机制 + RO23 自定义实验/诊断
│   ├── BQCore.h
│   ├── ContentView.swift           # 实验 UI / 日志入口
│   ├── HermesEnabler2App.swift
│   ├── HermesEnabler2.entitlements
│   ├── Gester-LICENSE.txt          # 原有第三方授权须保留
│   └── *.before-*.m                # 个人历史快照，不应进入公开主目录
├── HermesEnabler.xcodeproj/        # 旧工程，仅做历史参考
├── HermesEnabler/                  # 旧项目
├── README.md
└── [研究者本地的 .git、备份、用户设置等]
```

**仅用于研究开发，不是可执行的解锁安装教程：**在 Mac 上安装与 Watch SDK 相配的 Xcode，打开 `HermesEnabler2.xcodeproj`，选择自己的开发团队、Bundle Identifier 和 App Group，使用自己的配对 Apple Watch 编译测试。工程中使用私有系统接口、动态加载符号和旧 ABI，可能因 Apple 变更、签名及沙盒而失败。

从上游 README 来的 IPA 安装说明适用于**上游声明的受支持版本**，不构成本研究版的 `23U95` 成功安装/解锁证明。当前不建议公开一个会显示“Enable”却包含错误写入偏移的预构建 IPA。

## 12. 公开发布前必须完成的清理

> [!CAUTION]
> **上传的 `HermesEnabler(1).zip` 不能原样作为独立仓库公开。** 它包括个人 `.git` 历史、重复的历史备份、构建工程个人签名配置，以及仍使用错误索引的 23U95 写入函数。未经清理发布，会制造安全及归属风险。

- [ ] **首先禁用或移除 `BQWriteHermes23U95` 的危险历史写入路径**。不要仅用正确偏移替换错误偏移然后尝试写入；写权限问题和表盘准入问题仍未解决。首次公开建议将 `23U95` 的写入能力整体关闭，并明确标记 read-only research。
- [ ] 将本地项目里个人 `DEVELOPMENT_TEAM`、`PRODUCT_BUNDLE_IDENTIFIER`、App Group 标识等换成示例值或自己的新仓库约定；公开仓库不要包含个人 provisioning profiles 或证书。
- [ ] **不要上传历史 `.git/` 文件夹**。选择 GitHub Fork 以保留网络和作者关系，或者在**干净目录**中新建仓库并明确标注 `Based on pookjw/HermesEnabler`；不可把上游作者信息删掉。
- [ ] 不要上传 `_历史备份`、`.class7-flag-probe-source-backup`、`BQCore.m.before-*`、日志、`OriginalGestalt*.plist`、设备路径/UUID、签名文件、DerivedData、真实固件、`*.aea` 或 Apple 私有二进制提取物。
- [ ] 只保留公开发行必需的 Xcode project、源文件、资源、文档，并检查 `.gitignore` 是否足够。
- [ ] 将从上游获得的 **MIT `LICENSE` 原文（含 `Copyright (c) 2026 Jinwoo Kim`）** 随源代码保留；保留 `Gester-LICENSE.txt`，可增加 `NOTICE.md` 说明作者及衍生修改。
- [ ] 若收录研究报告，请仅发布必要的**去识别化**日志、流程与地址；Apple 官方固件/系统库文件不建议作为仓库附件二次分发。
- [ ] README、GitHub About、Releases 都应明确写 `Research-only / Not working on watchOS 26.6.1`。不要使用 “unlock all Hermès faces” 等无法证实的描述。
- [ ] 每次公开发行前审核完整 diff、Xcode 是否可编译、哪些构造函数会自动运行，以及是否存在影响系统缓存的操作。

## 13. 研究方法、复现与数据证据

研究的关键资料分为**实机观察**、**从对应 OTA 静态提取**、**公开上游源码**三类，不能互相替代。可复核的本机源文件校验摘要如下：

| 本次实验文件 | SHA-256 | 证据 |
|---|---|---|
| Full OTA `.aea` | `8c04028c94a26eafc96e2dc50cf5c5296834ca30e0401b90fcf16d24d976c18b` | 研究者下载文件的校验；不是 Apple 独立签名校验结论 |
| `MobileGestaltHelper` | `0e0c05244a3d35753e948783372f18e615ae2032cf7b750dd7a9cc57cfb3626e` | V8 静态样本 |
| `libMobileGestalt.dylib` | `383dfd64b790ba505760bb4af7a08ed2df185cbf6fffca64a13608f9bdcc2baf` | V9 静态样本 |
| `NanoTimeKit` | `bf3f7e360fe06ab7e513807bcb3b6ac695f38c6ea8cd8428b7aed579c2b58e1c` | V11 静态样本 |
| `ClockKit` | `5fc1784de78830eb83808a5663c87bf2be39bca08453b5d11ddef4dcad56cce0` | V12 静态样本 |

使用的研究工具：`ipsw`（AEA/OTA、BOM、dyld cache、Mach-O）、LLVM `llvm-objdump`、`file`、`shasum`、macOS/Xcode、实机只读日志。研究中**没有**执行 kernel exploit、越狱、远程控制、活动缓存重建或已成功的系统缓存写入。此前错误偏移、ABI 不兼容和不同 OS 的反编译代码都明确记录为局限与教训。

**公开复现原则：**优先离线分析与不修改系统的诊断；对设备的实际权限和准入做结论时必须有相应型号/版本实机日志。不要尝试删除或重建 live MobileGestalt 缓存。

## 14. 后续研究计划

- [x] 读取 23U95 MG 并创建正确备份。
- [x] 更正 DeviceBrand 描述符与缓存索引。
- [x] Class 13 令牌与写权限状态分离验证。
- [x] 对比本地 MobileGestalt 与 Helper XPC。
- [x] 提取并分析匹配版本 MobileGestaltHelper / libMobileGestalt。
- [x] 发现 Hermès 2025 原生 FaceBundle 与 NanoTimeKit 过滤调用。
- [x] V12 导出 ClockKit，并验证关键设备属性 getter。
- [ ] **公开源码安全整理：彻底禁用错误的 23U95 写入路径。**
- [ ] 完整确定 `supportsFall2025FacesCapability` 的实现所属模块及返回规则。
- [ ] 用安全、只读的方式采集目标设备 `deviceCategory`、`collectionType`、Fall2025 capability 等可观察值。
- [ ] 区分表盘目录/注册限制、FaceBundle 专属限制与底层设备能力检查。
- [ ] 研究非破坏性的兼容性验证，不宣称存在尚未验证的系统写入绕过。
- [ ] 完善 Xcode 清洁构建、故障回滚和公开日志匿名化流程。
- [ ] **只有在真正的设备上成功显示、添加并长期运行原生 Hermès 表盘后**，才更新项目状态为支持。

## 15. 原作者、许可、致谢

### 原作：Jinwoo Kim / @pookjw

衷心感谢 **[Jinwoo Kim（@pookjw）](https://github.com/pookjw)** 开发并开源 **[HermesEnabler / HermesEnabler 2](https://github.com/pookjw/HermesEnabler)**。如果没有其 Watch App 框架、MG 研究实践、上游功能与公开源码，RO23 这条技术研究线就没有可靠的基础。**本项目是基于其成果的非官方衍生版本，不是原版的替代品。**

### 本项目 RO23 研究：@ZhuoXuan-MY

感谢 **[@ZhuoXuan-MY](https://github.com/ZhuoXuan-MY)** 在自己的 Apple Watch Ultra 1 上提供设备、承担实机操作、调整和构建本地项目、保存真实日志、验证备份安全性、取得精确固件并参与 V1–V12 的持续研究与公开问题反馈。部分研究用代码、检查命令、报告结构与静态逆向分析得到 AI 工具辅助；所有实机结果来自设备所有者实际运行的实验，**不是模拟结果**。

### 感谢开源社区

- **[Gester](https://github.com/sasobhabha/Gester)**：上游已确认借用相关代码。仓库内现存 `Gester-LICENSE.txt` 请保留。
- **[forcequitOS / worse_query](https://github.com/forcequitOS/worse_query)** 与 [bad_query](https://github.com/forcequitOS/bad_query)：MCM 实验相关公开背景。并不代表其路线在本 Ultra 上成功。
- **[0xjohnnydev / Geod-MCM-PoC](https://github.com/0xjohnnydev/Geod-MCM-PoC)**：Geod-MCM 实验参考。
- **[PoomSmart / MGKeys](https://github.com/PoomSmart/MGKeys)**：MobileGestalt 哈希 key 与含义对应研究。
- **[blacktop / ipsw](https://github.com/blacktop/ipsw)**：Apple 固件解密、OTA 列表、dyld cache 解析与静态提取工具。
- **[EthanArbuckle 的 iOS 26.1 反编译研究](https://github.com/EthanArbuckle/iPhone18-3_26.1_23B85_Restore)**：早期 XPC 方法及错误码研究线索；最终结论需使用本机型匹配固件再核对。
- **[HermesEnabler Issue #7](https://github.com/pookjw/HermesEnabler/issues/7)** 的其他研究者：分享 Series 8 / 23U95 独立证据。本项目明确区分其他机型的报告与 Ultra 1 实测。
- 所有帮助分析 watchOS、MobileGestalt、NanoTimeKit 的开源贡献者。

**许可证：** 上游 `HermesEnabler` 采用 **MIT License**，版权声明为 `Copyright (c) 2026 Jinwoo Kim`。衍生项目必须完整保留原许可文本与版权声明，第三方代码须保留对应许可通知。关于本项目修改部分的贡献归属，在 `NOTICE.md` 中单独说明，**不得将上游全部代码写成 RO23 团队原创**。Apple 系统组件和 Hermès 商标不因 MIT 许可而成为本仓库可自由再分发的内容。

## 16. 免责与相关链接

本项目用于互操作性、静态逆向、研究与教育。它不保证适用任何设备；使用私有 API、改写系统缓存或错误配置签名可能造成数据丢失、应用无法安装、系统异常及保修/服务风险。请勿把此研究分支当作已完成的解锁产品。**截至 2026-11-11：没有原生 Hermès 表盘解锁成功报告。**

研究主线和原始日志在 [Issue #17：HermesEnabler on Ultra1 26.6.1 / 23U95](https://github.com/pookjw/HermesEnabler/issues/17)：

- [V1–V4 完整实机研究与更正](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6771229913)
- [V5–V7 Mach/XPC 对比日志](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6777128180)
- [iOS 26.1 的历史 error 9 研究背景](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6777139375)
- [V8：23U95 Helper 固件级逆向](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6777949079)
- [V9：匹配版本 libMobileGestalt 逆向](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6778385658)

**V10–V12 内容依据本项目的本地 OTA/FaceBundle/NanoTimeKit/ClockKit 二进制和研究记录整理，未将其误标成已经公开发布的 Issue #17 评论。** 提交新的研究问题时请包含机型、OS build、二进制 UUID/哈希和脱敏日志，并清晰区分“看到符号”“找到实际调用”与“完成动态验证”。

---

*Based on HermesEnabler by Jinwoo Kim (@pookjw). RO23 investigation and modified research snapshot by @ZhuoXuan-MY, with AI-assisted diagnostics and documentation. Not affiliated with or endorsed by Apple, Hermès, or the upstream maintainer.*
