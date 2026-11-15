# HermesEnabler watchOS 26 experimental support and Ultra 1 field report / HermesEnabler watchOS 26 实验性支持与 Ultra 1 实机记录

**2026-11-16 · Beijing / Kuala Lumpur (UTC+08:00)**

[简体中文](#简体中文) · [English](#english)

## 简体中文

### 1. 我核查的上游新增内容

我在 2026-11-16 核对了 [pookjw/HermesEnabler](https://github.com/pookjw/HermesEnabler) 的真实提交，而不是把网页写着“支持”视为实机解锁成功。

- **2026-11-16 01:41:38 UTC+8**：[提交 `7d84d97`](https://github.com/pookjw/HermesEnabler/commit/7d84d97d96ee6e1690e5c3dcd76cbe2910a1508e)，`feat: add experimental watchOS 26.6.1 support`。在 `MGOffsets.plist` 与 `MGDefaults.plist` 加入 **23U95** 布局/默认值；在 `BQCore.m` 为 major version 26 引入不同的 Class 7 查询 flags 和 Class 13 bad_query 尝试。代码中的注释也注明实际成功依赖运行环境。
- **2026-11-16 06:32:35 UTC+8**：[提交 `cd9de45`](https://github.com/pookjw/HermesEnabler/commit/cd9de454fe8d099ee28f0998080641fbe56c7a6d)，`feat: support watchOS 26 releases`。扩充更多 26 系列构建的缓存布局与说明，不等同于所有版本/机型已验证。
- **2026-11-16 06:46:14 UTC+8**：[提交 `a4feb90`](https://github.com/pookjw/HermesEnabler/commit/a4feb9071c2475cb25b54953ec60b368c054cd26)，`docs: clarify experimental watchOS 26 support`。上游 README 顶部的正式声明恢复为 **watchOS 27.0–27.3 beta 1**，并在 Cautions 中明确 **“Support for watchOS 26 is experimental.”**。因此必须把 26 记作实验性支持，而不是稳定支持/成功解锁。

上游 23U95 静态布局：`CacheUUID=3BE19A76-F253-4CE4-AAC1-DF6D801CAAB1`、`CacheDataLength=6309 (0x18A5)`、`DeviceBrandOffset=824 (0x338)`、`DeviceBrandPresentOffset=5711 (0x164F)`、`ScreenClassOffset=3640 (0xE38)`、`ScreenClassPresentOffset=6063 (0x17AF)`、`PresenceBase=5608 (0x15E8)`；`RecoveryVerified=false`。这些是**源码提供的静态表**，不是从我的 Ultra 1 完成的成功恢复验证。

### 2. 我在 Watch6,18 / 23U95 的真实 Xcode 测试

我使用 Xcode 将作者的更新版 `HermesEnabler2` 启动在 **Apple Watch Ultra 第一代（Watch6,18 / n199ap）**、**watchOS 26.6.1（23U95）** 上。先前遇到的 iPhone/Watch Bundle Identifier 前缀不一致问题已经排查，Watch App 可以运行。本次以我提供的 Xcode Console 日志和手表屏幕照片为依据，**不是模拟器，也不是我仓库旧版本代码的成功运行声明**。

以下摘录仅保留用于诊断的字段，没有上传完整 2,187 行原始日志或私有容器 UUID：

```text
[WC] ... "hardwareIdentifier": "Watch6,18", "build": "23U95", "systemVersion": "26.6.1"
[bqtool] MCM loaded=1 ...
[bqtool] app group entitlement: group.com.cd.zhuoxuan.uk
[bqtool] app group: id=group.com.cd.zhuoxuan.uk root=.../Containers/Shared/AppGroup/...
[bqtool] core init ok=1
[bqtool] strategy class13-bad-query: ... token=NO consume=-5
[bqtool] strategy class7-symlink-default/group.com.cd.zhuoxuan.uk: ... token=NO consume=-5
[bqtool] strategy class13-direct: .../SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches token=NO consume=-5
[bqtool] strategy class12-geod-traversal: ... token=NO consume=-5
[bqtool] escape: all strategies failed (last=-5) target=.../systemgroup.com.apple.mobilegestaltcache/Library/Caches
```

Class 2 的部分 staged/symlink 查询还反复记录 `PART_SUBDIR_CREATION_FAILED`、`errno (2) No such file or directory`，涉及重叠的 `Library/Caches/Library/Caches`、`Library/Caches/Caches` 子路径。这属于**可供上游审查的路径构造/查询诊断**，不能从修复路径字符串推断沙箱一定能被突破。

**分阶段结论：**

| 验证门槛 | 我本次实机证据 |
|---|---|
| 实机、系统 build、App 启动与 WatchConnectivity | 已确认 |
| App Group entitlement 文本和容器根路径 | 日志已显示，不能据此推断系统文件授权 |
| MCM 接口初始化 | `loaded=1`，`core init ok=1` |
| 找到目标 SystemGroup 路径 | 部分查询可返回路径 |
| 获取可消费的有效 sandbox token | **没有**；被记录的策略均 `token=NO`、`consume=-5` |
| `open(O_RDWR)` 成功/可写 fd | **本轮没有成功证据；当前日志也没有该调用的成功/EPERM 实测记录** |
| 受保护 MobileGestalt 写入、读回、备份/回滚 | **未达成/未验证** |
| 原生 Hermès 资格、正常添加、显示、重启后保留 | **未验证成功** |

我更早在这台 Watch6,18 / 23U95 上的 **`open(O_RDWR) → EPERM`** 测试是**独立的历史基线**；本次新日志在更早的 token 阶段失败，不能混为同一个测试结果。手表显示 **“MobileGestalt Access Failed”**，并且控制台没有可用的原始备份转移结果。我没有在本轮成功写入受保护文件，也没有原生 Hermès 表盘成功显示的证据。

### 3. 对我的仓库与下一步的意义

本仓库是**独立 watchOS 26 兼容性研究**，不把上游“添加版本布局”误写成“解决权限”或“解锁成功”。我保留此前 V0–V30、Class 13 token 不等于文件可写、历史 `EPERM`、ClockKit/NanoTimeKit 原生资格限制的研究记录。

- 可以确切记录：上游已针对 23U95 增加静态布局和版本相关访问尝试；我已在目标设备成功编译/启动应用并收集到新失败证据。
- 尚不能记录：获得 token、可写 fd、写入读回、重启持久性、真正的 Hermès 表盘加入和持续显示。
- 目前**不应该反复改 Bundle ID、删除 App Group 或宣称免费签名必然造成此次错误**：实际日志已识别 `group.com.cd.zhuoxuan.uk`。
- 本文是**文档同步及诊断报告**；**没有把上游 1.6 源码自动合并进本研究仓库，也没有执行越狱、系统写入或真实设备改动**。需要单独代码审查后才能安全决定是否合并而不覆盖本仓库既有研究。

**状态：EXPERIMENTAL UPSTREAM SUPPORT / REAL-WATCH ACCESS FAILED / NATIVE HERMÈS NOT UNLOCKED。**

## English

### 1. What I verified upstream

On November 16, 2026 (UTC+8), I checked the actual [upstream HermesEnabler](https://github.com/pookjw/HermesEnabler) commits, rather than interpreting the word “supported” as a verified native-face unlock.

- **01:41:38 UTC+8**, [`7d84d97`](https://github.com/pookjw/HermesEnabler/commit/7d84d97d96ee6e1690e5c3dcd76cbe2910a1508e): experimental **watchOS 26.6.1 / 23U95** offsets, defaults and major-version-26 Class 7 / Class 13 query variants.
- **06:32:35 UTC+8**, [`cd9de45`](https://github.com/pookjw/HermesEnabler/commit/cd9de454fe8d099ee28f0998080641fbe56c7a6d): additional watchOS 26 build-layout entries; this is not proof of runtime access on every model.
- **06:46:14 UTC+8**, [`a4feb90`](https://github.com/pookjw/HermesEnabler/commit/a4feb9071c2475cb25b54953ec60b368c054cd26): restored the formal README headline to **watchOS 27.0–27.3 beta 1**, while adding **“Support for watchOS 26 is experimental.”**

The 23U95 source table includes UUID `3BE19A76-F253-4CE4-AAC1-DF6D801CAAB1`, cache length **6309 (0x18A5)**, DeviceBrand offset **0x338** / presence **0x164F**, ScreenClass offset **0xE38** / presence **0x17AF**, and presence base **0x15E8**. `RecoveryVerified=false`; these are **static source entries, not an independently verified Ultra 1 recovery**.

### 2. My physical Watch6,18 / 23U95 result

I installed and launched the updated upstream HermesEnabler2 Watch app on my **first-generation Apple Watch Ultra**, running **watchOS 26.6.1 (23U95)**, after resolving a Watch/iPhone Bundle Identifier prefix mismatch. The actual Xcode logs identify `Watch6,18` and show a resolved App Group entitlement and root path, `MCM loaded=1`, and `core init ok=1`.

The Class 13 bad-query/direct and Class 7 / Class 2 strategies returned **no usable token** (`token=NO`, `consume=-5`), while some Class 2 staged queries failed with **`PART_SUBDIR_CREATION_FAILED` / `ENOENT`** for duplicated `Library/Caches` subpaths. The final result was **`escape: all strategies failed (last=-5)`** and the Watch displayed **“MobileGestalt Access Failed.”**

Knowing the protected SystemGroup path is **not** obtaining an effective sandbox token; an effective token is **not** a writable file descriptor; a writable descriptor would still **not** prove safe modification/readback, reboot persistence, face eligibility, addition, or stable native Hermès display.

My **earlier** physical-Watch `open(O_RDWR) → EPERM` result remains a separate historical baseline. **The new log did not demonstrate a successful or denied `open(O_RDWR)` call**; it failed earlier in token acquisition. I have no successful protected-cache edit, backup/restore proof, or native Hermès face activation from this session.

### 3. Repository scope and next criteria

I preserved the full V0–V30 history and earlier eligibility analyses. This update **documents the upstream changes and my physical-device negative result only**; it does **not** merge upstream exploit code, install an IPA from this fork, change my watch's protected files, or claim a working unlock.

**Status: EXPERIMENTAL UPSTREAM SUPPORT / REAL-WATCH ACCESS FAILED / NATIVE HERMÈS NOT UNLOCKED.**
