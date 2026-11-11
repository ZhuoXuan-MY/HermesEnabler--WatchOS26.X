# HermesEnabler RO23 — watchOS 26.x 原生 Hermès 表盘兼容性研究

**Apple Watch Ultra 第一代独立研究项目｜watchOS 26.6.1（23U95）｜MobileGestalt · ClockKit · NanoTimeKit · Hermès 2025 · Zeus 经典表盘**

[**简体中文**](README.zh-CN.md) · [**English**](README.md) · [原始 HermesEnabler 项目](https://github.com/pookjw/HermesEnabler) · [上游研究讨论 Issue #17](https://github.com/pookjw/HermesEnabler/issues/17) · [编译说明](BUILDING.md) · [版权与来源说明](NOTICE.md)

> [!IMPORTANT]
> **本项目目前是研究版，不是已经完成的 Hermès 原生表盘解锁工具。**
>
> 截至 **2026 年 11 月 11 日**，在已测试的 **Apple Watch Ultra 第一代 / watchOS 26.6.1 / 23U95** 上，**没有成功解锁、安装或正常使用受限制的 Apple 原生 Hermès 表盘**。历史实机测试中的系统 MobileGestalt 写入被 <code>EPERM</code> 拒绝。发现表盘程序、反汇编出限制条件、计算某个判断分支，**均不代表已经解锁**。
>
> **请区分公开源码和研究报告：**当前仓库中实际公开的 Xcode 源码是经过清理的研究快照，界面主要包含 **RO23 V1–V7** 诊断功能。这里新增的 **V13、V14** 来自另外两份研究材料及后续实机日志，**不表示当前公开仓库已经集成 V13/V14 按钮或可用的表盘资源**。没有经过验证的 23U95 解锁 IPA。

## 目录

1. [项目背景与研究目标](#1-项目背景与研究目标)
2. [目前最重要的结论](#2-目前最重要的结论)
3. [测试设备、固件和证据等级](#3-测试设备固件和证据等级)
4. [Apple 原生表盘为什么不只由 DeviceBrand 决定](#4-apple-原生表盘为什么不只由-devicebrand-决定)
5. [RO23 V1–V12：完整技术进展梳理](#5-ro23-v1v12完整技术进展梳理)
6. [RO23 V13：Hermès 2025 的类别白名单](#6-ro23-v13hermès-2025-的类别白名单)
7. [RO23 V14：Zeus / Hermès 经典表盘的六组限制](#7-ro23-v14zeus--hermès-经典表盘的六组限制)
8. [V13 / V14 实机数据与差异解释](#8-v13--v14-实机数据与差异解释)
9. [当前 GitHub 仓库实际包含什么](#9-当前-github-仓库实际包含什么)
10. [Xcode 编译、运行与日志收集](#10-xcode-编译运行与日志收集)
11. [研究材料、地址和校验值](#11-研究材料地址和校验值)
12. [常见问题与容易误解的地方](#12-常见问题与容易误解的地方)
13. [完成进度、未解决问题与下一步](#13-完成进度未解决问题与下一步)
14. [原作者、衍生研究、许可和免责声明](#14-原作者衍生研究许可和免责声明)

## 1. 项目背景与研究目标

### 1.1 项目从哪里来

这个项目基于 **[Jinwoo Kim（@pookjw）](https://github.com/pookjw)** 开发并开源的 **[HermesEnabler / HermesEnabler 2](https://github.com/pookjw/HermesEnabler)**。原项目的程序设计、原有界面、MobileGestalt 处理框架、备份与恢复基础，以及相应上游贡献，均属于原作者和其代码贡献者。本仓库不是从零原创的 HermesEnabler，也不代表原作者认可或支持这里的 watchOS 26.x 实验。

我是 **[@ZhuoXuan-MY](https://github.com/ZhuoXuan-MY)**。**RO23** 是我为研究 Apple Watch Ultra 第一代、watchOS 26.6.1（23U95）兼容性所使用的实验版本编号。我使用 Apple Watch 进行实机测试，收集运行日志，配合 Xcode 和同版本 watchOS 固件文件，分析系统限制。部分实验脚本、代码整理和技术报告使用了 AI 辅助；**实机观测、固件静态分析及尚未验证的推论会在文档中分别标注**。

上游项目当前 README 所声明的支持范围为 **watchOS 27.0 至 27.3 beta 1**。这是**上游软件自己的支持范围**，不能据此推导出本研究项目已经支持 watchOS 26.6.1，更不能据此宣称 23U95 已经解锁。

### 1.2 我究竟要解决什么

我的目标不是制作一张看起来像 Hermès 的图片，也不是下载第三方模拟表盘，而是研究：

- **原生表盘是否存在**：watchOS 26.6.1 固件中有没有苹果自己的 Hermès 2025 / Zeus 表盘程序和资源？
- **设备为什么被拒绝**：NanoTimeKit、ClockKit 与不同 FaceBundle 各自检查哪些条件？
- **DeviceBrand 是否足够**：更改一个 MobileGestalt 缓存值，理论上能否越过所有限制？
- **普通应用拥有哪些权限**：沙盒扩展、App Group、MobileGestaltHelper 是否允许修改系统保护的缓存？
- **什么才算成功**：在 Apple Watch 上实际显示、添加、使用并稳定保留真正的 Apple 原生表盘，而不只是读取到一个类名或让一个诊断分支返回允许。

经过 V1–V14，已经能够更清楚地解释**为什么部分 Hermès 表盘在 Ultra 上被排除**，但仍然**没有获得完整、可操作、已验证的解锁方法**。

## 2. 目前最重要的结论

| 研究问题 | 已得到的结果 | 证据性质 |
| --- | --- | --- |
| watchOS 23U95 是否可以读取 MobileGestalt？ | **可以**，旧版实机程序还创建了对应版本的本地备份 | 实机 |
| 能否直接以可写方式打开系统 MobileGestalt 缓存？ | **不可以**，返回 <code>EPERM=1</code> | 实机 |
| 成功获取/消费沙盒扩展后能否写入？ | 测试的 Class 13 扩展**没有**授予目标写权限 | 实机 |
| MobileGestaltHelper XPC 能否连接？ | 可以连接，但测试的查询均返回 **error 9** | 实机 |
| 23U95 固件中有没有苹果原生 Hermès 2025 表盘？ | **有对应的 FaceBundle** | 固件静态分析 |
| Hermès 2025 是否检查 deviceCategory？ | **是**，V13 识别出白名单 **{2, 3, 5}** | 固件静态分析 |
| ClockKit 如何将 Ultra 分类？ | 此版本实现中类别 **4、6** 会得到 <code>isUltra=true</code> | 固件静态分析 |
| Ultra 类别是否包含在 Hermès 2025 白名单内？ | **不包含** | 由静态分析直接推得 |
| 经典 Zeus 表盘是否可以绕过该限制？ | **不能这样认定**；V14 找到另一套独立限制 | 固件静态分析 |
| V14 诊断实机计算 Zeus 限制时得到什么？ | **Zeus Analog、Spectrum Zeus、Hades/Secretariat 等显示 RESTRICTED** | 用户提供的实机日志 |
| 当前是否已经成功解锁真正的 Hermès 表盘？ | **没有** | 项目状态 |

这张表的核心意思是：**“我们越来越清楚限制的位置”不等于“我们已经突破了限制”。**

## 3. 测试设备、固件和证据等级

### 3.1 精确的测试环境

| 项目 | 详情 |
| --- | --- |
| 设备 | Apple Watch Ultra（第一代） |
| 设备标识 | <code>Watch6,18</code> |
| 主板标识 | <code>n199ap</code> |
| 系统版本 | watchOS **26.6.1** |
| Build | **23U95** |
| 二进制架构 | Mach-O <code>arm64_32</code>，ILP32 |
| 应用 | 本地修改版 HermesEnabler2，另有独立 V13/V14 实验快照 |
| 开发环境 | Mac / Xcode / 开发签名 / 自行配置的 App Group |
| 核心研究对象 | MobileGestalt、MobileGestaltHelper、Hermès 2025、Zeus、NanoTimeKit、ClockKit |
| 真实原生表盘解锁结果 | **未成功** |

本仓库的结论针对**这一设备与这一系统构建号**。其他 Apple Watch 型号、其他 watchOS 26.x/27.x、小版本不同的私有框架，不能直接套用全部地址、类别映射或权限结果。

### 3.2 三种证据必须严格区分

**【实机观察 / DEVICE】**：Apple Watch 真正执行程序后出现的结果，例如读取成功、返回 <code>EPERM</code>、查询返回 <code>error=9</code>、V14 的 RESTRICTED 日志。

**【静态分析 / STATIC】**：从匹配的系统二进制、Mach-O、Objective-C 方法表、反汇编指令中读出的事实。例如某个函数的位置、常量集合、条件分支、类名和 plist 信息。**不代表该调用链一定已经在当前表上执行。**

**【推论 / OPEN】**：根据上述材料推断出的门槛、可能原因或下一步研究方向。只要没有完整验证，就不能写成已经实现的功能。

### 3.3 历史 MobileGestalt 缓存记录

在早期实际测试中读取到：

~~~text
系统 plist 总大小：      13,328 bytes
CacheUUID：              3BE19A76-F253-4CE4-AAC1-DF6D801CAAB1
CacheData：              6,309 bytes（0x18A5）
缓存结构：                701 个记录，每个 9 字节
CacheExtra：             72 项
MGCopyAnswer(DeviceBrand)：CFNumber(0)
~~~

原先保存的 watchOS 26.5 备份与 23U95 的 UUID、文件大小不同，所以**没有把旧备份恢复到新系统**。之后创建并验证了独立的 <code>OriginalGestalt-23U95.plist</code>，用于记录和保护研究状态。

**能备份 ≠ 能写入系统；能读取 ≠ 有权修改系统文件。**

## 4. Apple 原生表盘为什么不只由 DeviceBrand 决定

### 4.1 一个有助于理解的分层模型

下面是根据目前分析建立的**概念模型**，不是完整实机追踪图：

~~~text
watchOS 固件含有 Apple 原生 FaceBundle
                      │
                      ▼
表盘样式发现、注册、资源加载
                      │
                      ▼
NanoTimeKit / FaceDescriptor 可用性判断
                      │
                      ▼
表盘子类 +isRestrictedForDevice: 检查
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
 deviceCategory  collectionType   DeviceBrand
        │             │             │
        └─────────────┼─────────────┘
                      ▼
  isUltra / isZeusBlack / Capability /
  NTKShowHardwareSpecificFaces 等门槛
                      │
                      ▼
  系统是否真正展示、允许添加、运行表盘
              （尚未达成）
~~~

### 4.2 必须区分五个不同的“成功”

1. **固件存在表盘**：只证明系统安装包里有二进制与资源。
2. **表盘类成功加载**：只证明程序可以找到相应 Objective-C 类/方法。
3. **资格判断通过**：需要相关设备、集合、硬件特性与表盘自身检查允许。
4. **表盘能够添加**：必须实际出现在系统选择界面并可被添加。
5. **表盘能够稳定工作**：真正渲染、正常交互，并经过系统切换后依然可用。

RO23 V13、V14 的重点在于第三层的**局部门槛**，没有完成第四层和第五层。

### 4.3 为什么 DeviceBrand 不可能被简单等同于表盘解锁

在被分析的 ClockKit 中：

- <code>deviceBrand</code> 有独立数据字段；
- <code>deviceCategory</code> 是另一字段；
- <code>collectionType</code> 也是另一字段；
- <code>isUltra</code> 是单独的分类状态；
- Zeus 还会涉及 <code>isZeusBlack</code> 和硬件专属表盘显示门槛。

因此，即使某个 DeviceBrand 条件看似满足，也**不意味着**其他条件同步满足。V13 证明 Hermès 2025 存在前置类别排除；V14 证明经典 Zeus 家族使用不同的子类限制，不能把两套逻辑混为一谈。

## 5. RO23 V1–V12：完整技术进展梳理

早期较长的英文研究记录保留在 [README2.md](README2.md)。这里将其按实际发现重新组织，同时保留失败案例、错误修正及其重要性。

### V1：定位 DeviceBrand 与缓存描述符

通过检查设备中映射的 <code>libMobileGestalt.dylib</code>，定位相关哈希名称：

~~~text
DeviceBrand → fuKL2rMywRgQF1wowOA/cg
~~~

最初扫描二进制时，误把上一个描述符的边界当成 DeviceBrand 的起始位置，导致后续出现错误的索引和偏移量。这个错误不是可用的修改方法，必须在历史记录中明确纠正。

### V2：用真实 MGCopyAnswer API 对比数值

通过 <code>MGCopyAnswer(CFStringRef, CFDictionaryRef)</code> 读取 <code>DeviceBrand</code> 和对应哈希，实机结果都表示为 <code>CFNumber(0)</code>。

特别注意：**Core Foundation 返回值的类型**，不等同于 MobileGestalt 内部描述符的 <code>type</code> 字段。二者混淆会影响反汇编解释。

### V3：纠正 DeviceBrand 真实索引

重新核对 <code>arm64_32</code> 描述符结构后，得到：

| 字段 | 最终分析结果 |
| --- | --- |
| 描述符步长 | **100 bytes / 0x64** |
| flags | **12 / 0x0C** |
| DeviceBrand 索引 | **103** |
| 内部 type | **5** |
| 值偏移 | **<code>0x338</code>**（103 × 8） |
| 有效位偏移 | **<code>0x164F</code>**（701 × 8 + 103） |
| 读取值 | 0 |
| 有效位 | 1 |

**错误旧值：**<code>index=206</code>、<code>0x670</code>、<code>0x16B6</code> **不是 DeviceBrand 的正确记录**。早期数据中两个候选位置碰巧都显示 0，增加了误判的可能。

即使正确找到数据结构，也**不代表获得系统缓存写权限**；更不代表改动这一值就能跨过后面的 FaceBundle 限制。

### 历史写入测试：在写入前被 EPERM 拦截

在旧版本地实验中，程序先确认匹配的 23U95 备份，再尝试以可写方式打开系统 MobileGestalt 缓存。实际日志：

~~~text
MG FORCE: entering 23U95 write path
MG FORCE: 23U95 backup verified
MG FORCE: WRITE DENIED errno=1 (Operation not permitted)
~~~

文件打开阶段即返回 **<code>EPERM=1</code>**，程序**没有进入实际 pwrite 写入操作**，没有成功修改任何 DeviceBrand 字节。

该旧实验路径使用过前述**错误偏移**，已经从公开的清理版代码中移除。不要将其当作方法复用。

### V4：Class 13 沙盒扩展不等于写权限

历史实验中，使用 Class 13 和 <code>0x0800000000</code> 查询参数取得了一个沙盒扩展，并成功消费。随后对真实文件权限进行对比：

| 测试内容 | 消费扩展前 | 消费扩展后 |
| --- | --- | --- |
| 读取系统 MobileGestalt 文件 | 允许 | 允许 |
| 以可写方式打开系统文件 | 拒绝 | 拒绝 |
| 在受保护目录内创建文件 | 拒绝 | 拒绝 |

**结论：沙盒令牌存在，不等于对目标系统组具有写权限。** 常规 App Group entitlement 不能替代苹果私有 SystemGroup 权限。

### V5：连接 MobileGestalt Mach 服务

通过 Mach/bootstrap 方法找到 <code>com.apple.mobilegestalt.xpc</code>。这说明服务可以被找到，并不说明所有 XPC 请求都会得到授权，更不说明可以写入系统缓存。

### V6：首次收到 Helper 的 error 9

与 MobileGestaltHelper 建立 NSXPC 连接后，执行只读的 <code>getServerAnswerForQuestion:reply:</code> 查询，返回：

~~~json
{"error":9}
~~~

这里**没有调用缓存重建操作**，也没有尝试使用 Helper 修改系统数据。

### V7：不同问题均返回 error 9

| 提问 | 本地 MGCopyAnswer | Helper XPC |
| --- | --- | --- |
| <code>DeviceBrand</code> | CFNumber(0) | error 9 |
| <code>fuKL2rMywRgQF1wowOA/cg</code> | CFNumber(0) | error 9 |
| <code>BuildVersion</code> | 返回字符串 | error 9 |
| <code>ProductType</code> | 返回字符串 | error 9 |

**error 9 是 MobileGestalt 服务器返回值**，不要与 POSIX 的 <code>EPERM=1</code>、Mach 错误或 NSXPC 连接失败混为一谈。

### V8：提取并分析匹配的 MobileGestaltHelper

从匹配 <code>Watch6,18 / n199ap / 23U95</code> 的固件中分析 <code>MobileGestaltHelper</code>。其 Mach-O <code>arm64_32</code> 可执行文件大小为 **76,112 bytes**。

| 位置 | 静态地址 |
| --- | --- |
| <code>getServerAnswerForQuestion:reply:</code> | <code>0x5110</code> |
| <code>rebuildCache:</code> | <code>0x55F0</code> |
| <code>setCacheSentinel:</code> | <code>0x5714</code> |
| 调用 <code>_MGServerCopyAnswerWithError</code> | <code>0x51C4</code> |

只发现 <code>rebuildCache:</code> 方法**不说明它能绕过权限**。本研究没有在实机调用该系统缓存重建路径。

### V9：分析匹配的 libMobileGestalt

匹配版本 <code>libMobileGestalt.dylib</code> 大小为 **991,764 bytes**。定位：

| 符号/逻辑 | 位置 |
| --- | --- |
| <code>_MGServerCopyAnswerWithError</code> | <code>0x215B42A8</code> |
| 服务端权限检查相关逻辑 | <code>0x215B4BF4</code> |

相关描述符：

| Key | Index | type | flags |
| --- | ---: | ---: | --- |
| DeviceBrand | 103 | 5 | 0x0C |
| BuildVersion | 62 | 9 | 0x0C |
| ProductType | 530 | 9 | 0x0C |

服务端确实存在通向 error 9 的代码路径。这为 V7 的现象提供了**合理的静态解释**：本地读取 API 可以读取某些问题，但服务器接口可能仍拒绝回答。**没有对 V7 每一个问题进行完整的动态调用链追踪**，因此不能宣称已经证实每个查询的精确拒绝分支。

### V10：在固件中发现真正的 Hermès 2025 FaceBundle

匹配固件中找到的原生 Apple 组件包括：

| 组件 | 研究记录中的大致大小 |
| --- | ---: |
| <code>NTKHermes2025FaceBundle</code> 可执行文件 | 约 1.2 MB |
| Hermès Bundle 的 <code>Assets.car</code> | 约 32 KB |
| <code>Carousel</code> | 约 185 KB |
| <code>ClockFace</code> | 约 406 KB |
| <code>nanotimekitd</code> | 约 734 KB |

<code>nanotimekitd</code> 内能够找到 <code>com.apple.Hermes2025Face</code>、<code>_NTKFaceStyleIsAvailable</code> 等相关引用。约 <code>0x8260</code> 一带存在一般性表盘可用性过滤的静态调用位置。

**关键点：表盘程序在固件中出现，并不说明苹果允许 Ultra 1 展示该表盘。**

### V11：发现 Hermès 2025 自身的限制函数

匹配的 NanoTimeKit 框架大小为 **11,395,800 bytes**。

| 符号/方法 | 对应位置 |
| --- | --- |
| <code>_NTKFaceStyleIsAvailable</code> | <code>0x544392B0</code> |
| <code>-[NTKFaceDescriptor isAvailableForDevice:]</code> | <code>0x543D998C</code> |
| <code>-[NTKFaceBundleManager faceBundleForBundleIdentifier:onDevice:forMigration:]</code> | <code>0x544B0DDC</code> |
| <code>+[Hermes2025Face isRestrictedForDevice:]</code> | <code>0x3B2C</code> |

这里第一次明确看到，Hermès 2025 自己的限制方法涉及 <code>deviceCategory</code>、<code>collectionType</code>、<code>supportsFall2025FacesCapability</code> 等条件，不能仅靠 DeviceBrand 推断结果。

### V12：将 ClockKit 设备信息与表盘逻辑对应

匹配版本 ClockKit 大小为 **1,425,840 bytes**，架构为 <code>arm64_32</code>。

| CLKDevice getter | 地址 | 访问的数据字段 |
| --- | --- | --- |
| <code>deviceCategory</code> | <code>0x49C30EB4</code> | <code>+0x2C</code> |
| <code>collectionType</code> | <code>0x49C354F0</code> | <code>+0x30</code> |
| <code>deviceBrand</code> | <code>0x49C6F144</code> | <code>+0x3C</code> |
| <code>isUltra</code> | <code>0x49C6F11C</code> | <code>+0x17</code> |

到 V12 为止，已经知道这些字段分开存储，但**仍没有完全确定 Hermès 2025 的类别白名单如何限制 Ultra**。这正是 V13 的突破点。

### 其他历史实验：没有获得系统写权限

- Class 7 三组参数：<code>0x0800000000</code>、<code>0x8000000000</code>、<code>0x8100000000</code>，没有得到可用的目标沙盒令牌。
- Geod-MCM Class 12 实验：未取得所需容器对象。
- Class 13：获得并消费扩展，但系统受保护目录的写/创建权限仍被拒绝。

这些失败只说明**被测试的方法在该设备及条件下没有奏效**，并不能证明其他所有方案在理论上都不可能。

## 6. RO23 V13：Hermès 2025 的类别白名单

**来源：**用户另外提供的《RO23 V13 — Hermès 2025 FaceBundle / ClockKit cross-binary eligibility analysis》，日期为 **2026-11-11**。依据匹配 23U95 的 Hermès 2025 FaceBundle、NanoTimeKit 和 ClockKit 静态检查。V13 附带/描述过一个用于后续实机验证的只读诊断源代码快照；**研究报告本身没有证明该快照已在当前公开仓库编译运行**。

### 6.1 最重要的新发现：白名单是 {2,3,5}

在 Hermès 2025 Bundle 内，确认：

- <code>+[Hermes2025Face isRestrictedForDevice:]</code>：**<code>0x3B2C</code>**
- 其调用的本地辅助逻辑：**<code>0x46B8</code>**
- 读取 <code>deviceCategory</code> 的位置：**<code>0x46EC</code>**
- 集合成员检查的位置：**<code>0x46F4</code>**
- Swift 静态集合构造数据：**<code>0xCCC4C</code>**
- 三个集合元素：**<code>0xCCC5C / 0xCCC60 / 0xCCC64</code>**
- 不在集合内时通向受限结果的分支：约 **<code>0x4770</code>**

该集合一共有 **3 个元素：2、3、5**。

因此，在此具体反汇编检查中，**Hermès 2025 对某个 <code>CLKDevice.deviceCategory</code> 条件只接受 {2,3,5}**。这不是通过 Apple Watch 商业型号名称进行文本比较，而是对 ClockKit 的**内部整数类别**进行检查。

### 6.2 ClockKit 的 sizeClass → deviceCategory 映射

匹配 ClockKit 的表地址为 **<code>0x49CA5E70</code>**，共有 10 个条目：

| sizeClass | deviceCategory |
| ---: | ---: |
| 0 | 1 |
| 1 | 1 |
| 2 | **2** |
| 3 | **2** |
| 4 | **3** |
| 5 | **3** |
| 6 | **4** |
| 7 | **5** |
| 8 | **5** |
| 9 | **6** |

ClockKit 在 **<code>0x49C6E26C–0x49C6E27C</code>** 附近还使用这一判断来设置 Ultra 状态：

~~~c
(deviceCategory & ~2) == 4
~~~

按照该版本实现，**category 4 和 category 6 会使 <code>isUltra=true</code>**。但 Hermès 2025 白名单是 **{2,3,5}**，**不包含 4，也不包含 6**。

这意味着：**对于按该逻辑被分类为 Ultra 的设备，该 Hermès 2025 类别判断已经会拒绝设备**，即使后面的 collectionType 或 capability 还没有被检查。

这是一项针对 **V13 特定 FaceBundle 和此版本 ClockKit** 的结论，不应泛化为“所有 Hermès 经典表盘都用同一白名单”。V14 恰恰发现不是这样。

### 6.3 supportsFall2025FacesCapability 为什么仍不等于解锁

V13 没有在被检查的 ClockKit 基础类中找到这个方法的实现，却在 **Hermès 2025 FaceBundle 给 <code>CLKDevice</code> 增加的 Objective-C Category** 中找到了对应方法。

实现位置为 **<code>0x37C4</code>**：

~~~asm
0x37C4: mov w0, #1
0x37C8: ret
~~~

这说明：**当该 Objective-C Category 已经被加载注册**，这个实现返回 <code>true</code>。

必须注意：

- 在别的进程中没有看到该 selector，可能只是没有加载相关 Category；
- 该方法返回 true，只代表**这一个 capability 方法**的行为；
- Hermès 2025 先前的 deviceCategory 白名单依然存在；
- **返回 true 不代表整个表盘可以安装、启用、渲染。**

### 6.4 DeviceBrand、collectionType 与类别限制各自独立

在 ClockKit 的 <code>_loadDeviceInfo</code> 逻辑 **<code>0x49C6DE20–0x49C6DE44</code>** 附近，某些分支将数值 <code>deviceBrand=1</code> 映射为 <code>collectionType=5</code>、将 <code>deviceBrand=2</code> 映射为 <code>collectionType=6</code>。但 <code>deviceCategory</code> 是从 sizeClass 映射表独立决定的。

Hermès 2025 的辅助限制函数约 **<code>0x4744</code>** 还会比较 <code>collectionType==5</code>，但**该分支必须先通过前面的类别门槛**。

**V13 的核心结论：即使能够改变 DeviceBrand，也没有证据表明仅凭这一项就可以让 Ultra 1 获得 Hermès 2025 原生表盘。**

## 7. RO23 V14：Zeus / Hermès 经典表盘的六组限制

**来源：**用户另外提供的《RO23 V14 — Zeus/Hermès legacy face eligibility (23U95)》，日期为 **2026-11-11**。研究对象是从匹配 watchOS 材料中取得的 **<code>NTKZeusFaceBundle</code>**，并与相同系统版本的 ClockKit / NanoTimeKit 对照。这里讨论的是**Zeus 相关的经典 Hermès 家族**，不是把 V13 的 <code>Hermes2025Face</code> 当成同一个类。

### 7.1 被检查的 Apple 原始二进制信息

| 项目 | 研究结果 |
| --- | --- |
| 名称 | <code>NTKZeusFaceBundle</code> |
| Mach-O 大小 | **663,040 bytes** |
| 架构 | <code>arm64_32</code> |
| SHA-256 | <code>2b34d3d411b77ee73f3892638f419eda83b7bedc4653ecf44adf7c975bbd72e4</code> |
| CFBundleIdentifier | <code>com.apple.NTKZeusFaceBundle</code> |
| MinimumOSVersion | **26.6** |
| LegacyStyles | <code>SpectrumZeus</code>、<code>ZeusAnalog</code> |
| 其他相关表盘族 | Hades、Poodle、Secretariat、Bellona 及其变体 |
| 仓库是否分发原始文件 | **否** |

研究不是只通过字符串搜索猜测函数属于哪个类，而是分析 Objective-C 的 **<code>__objc_methlist</code> 相对方法表、方法实现和 class-ro 类信息**，将不同 <code>isRestrictedForDevice:</code> 与实际所属表盘类对应起来。这让 V14 的六个入口比单纯的符号字符串匹配更有证据价值。

### 7.2 六个真实实现与相关条件

| 表盘实现类 | 静态 IMP VM 地址 | 发现的限制 |
| --- | --- | --- |
| <code>NTKZeusAnalogFace</code> | **<code>0x169C</code>** | <code>collectionType==5</code> 对此检查直接放行；否则进入硬件专属表盘门槛 |
| <code>NTKSpectrumZeusFace</code> | **<code>0x1648</code>** | 关联 <code>isZeusBlack</code>、<code>deviceCategory</code> 和硬件表盘门槛 |
| <code>NTKHadesFace</code> | **<code>0x12FC</code>** | 类别 **1、4、6** 会被拒绝，后续仍有其他门槛 |
| <code>NTKSecretariatFace</code> | **<code>0x5C08</code>** | 类别 **1、4、6** 会被拒绝，后续仍有其他门槛 |
| <code>NTKPoodleFace</code> | **<code>0x13B4</code>** | 类别 **1** 会被拒绝，另有 capability / collection / hardware 条件 |
| <code>NTKBellonaFace</code> | **<code>0x21E80</code>** | 存在类别 1 及其他具体判断，**尚未完整解读全部分支** |

这证明经典 Hermès 表盘的限制是**按不同表盘类分别实现**的，不能简单说成“修改一个全局变量后，所有 Hermès 表盘全部可用”。

### 7.3 Zeus Analog 核心反汇编分支

~~~asm
0x16A8  bl   0x43480    ; objc_msgSend$collectionType
0x16AC  cmp  w0, #5
0x16B0  b.ne 0x16BC
0x16B4  mov  w0, #0      ; 对这一检查不限制
0x16BC  bl   0x340AC    ; _NTKShowHardwareSpecificFaces
0x16C0  eor  w0, w0, #1 ; 结果取反 => restricted
~~~

这段分析说明：

1. 如果 <code>collectionType==5</code>，这一限制实现存在直接放行分支；
2. 如果不等于 5，则会检查 <code>_NTKShowHardwareSpecificFaces()</code>；
3. 在先前观测的 Ultra 第一代上，<code>collectionType=9</code>，**不满足直接放行条件**；
4. 因而不能因为经典 Zeus 没有 Hermès 2025 的 **{2,3,5}** 白名单，就断言 Zeus Analog 已经允许安装。

### 7.4 NTKShowHardwareSpecificFaces 和其他 ClockKit 函数

V14 在匹配的 NanoTimeKit 中定位：

- <code>_NTKShowHardwareSpecificFaces</code>：**<code>0x546014DC</code>**
- ClockKit <code>-[CLKDevice isZeusBlack]</code>：**<code>0x49C6F0EC</code>**
- ClockKit <code>-[CLKDevice supportsPDRCapability:]</code>：**<code>0x49C6E724</code>**

研究中的 <code>_NTKShowHardwareSpecificFaces</code> 会考察运行前提及内部表盘显示设置。其存在**不代表普通未越狱设备有稳定可靠的开启方式**。而所检查的 <code>supportsPDRCapability:</code> 即使返回 true，也不意味着其它限制同步消失。

V14 的关键价值在于**找到了对 Zeus Analog 真正决定该分支结果的额外条件**，不是已经掌握了修改该条件的解锁方法。

### 7.5 V13 和 V14 不能被错误合并

| 对比维度 | V13 Hermès 2025 | V14 经典 Zeus |
| --- | --- | --- |
| 主要研究对象 | <code>Hermes2025Face</code> | Zeus、Spectrum、Hades、Secretariat、Poodle、Bellona 等类 |
| 最重要的限制 | <code>deviceCategory</code> 白名单 **{2,3,5}** | 各个表盘类的不同条件 |
| 对类别 4 的意义 | Hermès 2025 前置白名单排除 | Hades/Secretariat 排除；Zeus Analog 看其它条件 |
| 对 <code>collectionType=9</code> 的意义 | 后续检查不必然可达 | Zeus Analog 进入硬件专属表盘门槛 |
| 是否已安装或解锁 | **没有** | **没有** |
| 证据性质 | 静态反汇编 + 后续类别观察 | 静态反汇编 + 独立实机诊断日志 |

## 8. V13 / V14 实机数据与差异解释

### 8.1 先前记录的 Ultra 内部属性

V13 研究材料引用了先前的设备只读数据：

~~~text
deviceCategory=4
collectionType=9
isUltra=true
deviceBrand 相关读取值=0（早期记录）
~~~

这些数值与 V13 所确定的 ClockKit sizeClass/category 机制具有一致性：**category 4** 是 Ultra 分类之一，却不在 Hermès 2025 的允许类别集合里。

### 8.2 随后提供的 V14 实机日志

研究者另外提供了一次 **RO23 V14** watchOS 23U95 日志，内容如下：

~~~text
[bqtool] RO23 V14 — Zeus native face eligibility (read-only)
Build=23U95
deviceCategory=4
collectionType=9
deviceBrand=399803152
isZeusBlack=false
NTKShowHardwareSpecificFaces=false
ZeusAnalog gate (0x169C): RESTRICTED
SpectrumZeus gate (0x1648): RESTRICTED
Hades/Secretariat category gate: RESTRICTED
No face bundle loaded. No face installed.
No protected writes, overrides, or restarts.
RO23 V14 END systemWrites=NO
~~~

**实机说明：**

- <code>deviceCategory=4</code>、<code>collectionType=9</code> 与此前研究记录一致；
- <code>isZeusBlack=false</code>；
- <code>NTKShowHardwareSpecificFaces=false</code>；
- Zeus Analog / Spectrum Zeus 的**诊断门槛计算**为 <code>RESTRICTED</code>；
- Hades/Secretariat 的类别限制也显示 <code>RESTRICTED</code>；
- 这次测试**没有加载 FaceBundle、没有安装表盘、没有写入系统文件，也没有重启系统服务**；
- 日志里所谓的 gate 结果是根据研究得出的条件进行只读评估，**并非整个系统表盘可用性链路的完整动态调用结果**。

### 8.3 DeviceBrand 数值为什么不同？

历史 <code>MGCopyAnswer(DeviceBrand)</code> 的读取值是 **0**，V13 报告还引用过一个 DeviceBrand 相关的 **0**。但之后 V14 记录的 <code>CLKDevice deviceBrand</code> 为 **399803152**。

**这两组结果不能被悄悄替换、混为一个数值。**它们出现在不同的诊断记录、API 或对象上下文中。当前材料没有对这些读取来源和完整运行环境进行逐项动态核对，因此**尚不能确定**数值不同的具体原因，可能涉及读取来源、表示方式或运行上下文等差别，但这些都只是待验证解释。

同样，V13/V14 两份研究报告中对二进制的**静态检查**，与后来用户提供的**Apple Watch 实机日志**也应该分别保留出处。不能把“分析文件时找到了函数”表述成“该函数在设备上已通过完整调用链验证”。

### 8.4 V14 只读诊断的安全边界

V14 实验快照描述的 **“RO23 V14: Check Zeus Faces”** 按钮，会读取 <code>CLKDevice</code> 的 <code>deviceCategory</code>、<code>collectionType</code>、<code>deviceBrand</code>、<code>isZeusBlack</code>，必要时只调用原始导出的 <code>_NTKShowHardwareSpecificFaces</code>，再根据静态分析判断门槛。

该 V14 设计**不加载 Zeus Bundle，不安装表盘，不覆盖 CLKDevice，不修改 MG，不更改受保护偏好，不重启 Carousel**；仅在应用自身 <code>Documents/bqtool.log</code> 保存日志。

**但是，请不要以为当前 GitHub 代码已经有这个按钮。**本仓库公开的 <code>ContentView.swift</code> 目前仍主要是 V1–V7 的只读诊断界面，V14 属于另外提供的研究快照与报告。

## 9. 当前 GitHub 仓库实际包含什么

### 9.1 项目文件结构

~~~text
HermesEnabler2.xcodeproj/
  project.pbxproj
HermesEnabler2/
  BQCore.h
  BQCore.m
  ContentView.swift
  HermesEnabler2App.swift
  HermesEnabler2.entitlements
  Gester-LICENSE.txt
  Assets.xcassets/
BUILDING.md
CHANGELOG.md
LICENSE
NOTICE.md
PUBLICATION_CHECKLIST.md
PUBLISH_ON_GITHUB.zh-CN.md
README.md
README.zh-CN.md
README2.md                 （原 V1–V12 英文研究记录）
~~~

仓库中还保留了先前单独命名的中文研究说明；这里新建的中英文标准 README 作为统一入口，旧历史材料无需删除。

### 9.2 公开源码已经做过的安全清理

依据 [CHANGELOG.md](CHANGELOG.md)、[BUILDING.md](BUILDING.md) 及当前 <code>ContentView.swift</code>：

- 移除了历史的、错误偏移版 <code>BQWriteHermes23U95</code> 强制写入路径；
- 移除了历史 Geod 可写文件实验；
- MobileGestalt 保存/恢复、Hermès 启用、相关 capability override 路径被设置为失败退出，不再将它们作为可用功能；
- 公开 UI 已去掉表盘启用、AOD 修改、缓存恢复、Respring 等按钮；
- 不在应用启动时自动执行 V1–V7 诊断，改为手动触发；
- 保留读取、兼容性检测、权限检查与可在应用沙盒中生成的备份和日志；
- 部分较老的 MCM 沙盒研究代码仍可能涉及**应用自己拥有的临时路径**，研究者必须阅读源码再执行。

**注意：**“不写入受保护的系统 MG 缓存”不代表“应用完全没有任何本地文件写入”。日志和备份可以保存在应用自己的 Documents，某些实验代码还可能接触应用自己的临时目录。

### 9.3 当前公开 UI 里真实存在的按钮

| 按钮名称 | 用途 | 是否代表解锁 |
| --- | --- | --- |
| **Check Compatibility** | 查看构建、版本和基本兼容性信息 | 否 |
| **Direct Read Probe** | 检查目录和文件只读访问 | 否 |
| **Test MG Access** | 尝试读取 MG 并验证应用本地备份 | 否 |
| **Create Local MG Backup** | 只读获取系统数据并建立/验证应用本地备份 | 否 |
| **Run RO23 V1–V7 Diagnostics** | 手动启动历史研究诊断，查看日志 | 否 |
| **RO23 V13: Check Face Eligibility** | 仅在另外描述的 V13 研究快照中出现 | **公开仓库未核实集成** |
| **RO23 V14: Check Zeus Faces** | 仅在另外描述的 V14 研究快照中出现 | **公开仓库未核实集成** |

**当前仓库的 Xcode 项目没有经过本次文档更新后的全新编译、签名和真机发布验证。**过去本地修改版能够执行某项实验，不代表这个公开源码快照一定可以直接重现所有旧实验。

## 10. Xcode 编译、运行与日志收集

### 10.1 准备条件

- Mac 和带有合适 **watchOS SDK** 的 Xcode；
- 可以作为 Xcode 运行目标使用的 Apple Watch；
- 自己能够使用的 Apple 开发签名配置；
- 对 Swift / Objective-C、私有 API 不稳定性及日志有基本了解；
- 清楚这个项目**不能保证开启受限制的 Hermès 表盘**。

### 10.2 获取源码

~~~bash
git clone https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X.git
cd HermesEnabler--WatchOS26.X
open HermesEnabler2.xcodeproj
~~~

### 10.3 在 Xcode 中设置

1. 打开 **Targets → HermesEnabler2 → Signing & Capabilities**。
2. 选择**你自己的开发团队**。公开工程不包含他人的私人开发团队或有效签名证书。
3. 将示例 Bundle Identifier <code>com.example.HermesEnablerRO23</code> 改为你自己的唯一 ID。
4. 将 <code>HermesEnabler2/HermesEnabler2.entitlements</code> 内示例 App Group <code>group.com.example.HermesEnablerRO23</code> 改为你实际配置并有权限使用的 App Group；与 Xcode Signing & Capabilities 保持一致。
5. 选择可用的 Apple Watch 运行目标；在 Xcode 与 SDK 支持的条件下编译、安装和运行。
6. 只使用**当前公开代码中真实存在**的诊断按钮，收集应用自己的 <code>Documents/bqtool.log</code>，不要把诊断输出理解为已经激活表盘。

工程文件设置的 **<code>WATCHOS_DEPLOYMENT_TARGET=26.0</code>** 只是最低部署目标信息，**不是宣称整个 watchOS 26.x 系列已经兼容或可解锁**。普通开发签名和 App Group 也**不会自动获得苹果私有 SystemGroup 写权限**。

具体构建提示请参阅 [BUILDING.md](BUILDING.md)。目前**不提供已验证可解锁 23U95 原生 Hermès 表盘的 IPA**。

### 10.4 如何提交有价值的测试反馈

建议在 [Issue #17](https://github.com/pookjw/HermesEnabler/issues/17) 或本仓库问题讨论中说明：

- Apple Watch 的**准确型号与标识**；
- **watchOS 版本和 Build**，例如 26.6.1（23U95）；
- 所用源码的 Git commit 和测试按钮；
- **未经过改写、但已经脱敏**的实际日志；
- FaceBundle 是否真的加载、系统表盘列表是否出现变化；
- 是否真的在手表上添加、显示并正常运行了原生表盘。

不要上传序列号、个人 App Group 标识、容器 UUID、完整 MobileGestalt 缓存、签名配置文件、个人目录路径或 Apple 原始固件二进制。

## 11. 研究材料、地址和校验值

这次研究强调“**必须匹配实际固件版本**”，不能把不同 iOS/watchOS 的私有框架地址当成可通用的偏移量。

### 11.1 研究中记录的 SHA-256

| 研究输入文件 | SHA-256 |
| --- | --- |
| 历史下载的完整 watchOS OTA | <code>8c04028c94a26eafc96e2dc50cf5c5296834ca30e0401b90fcf16d24d976c18b</code> |
| V8 MobileGestaltHelper | <code>0e0c05244a3d35753e948783372f18e615ae2032cf7b750dd7a9cc57cfb3626e</code> |
| V9 libMobileGestalt.dylib | <code>383dfd64b790ba505760bb4af7a08ed2df185cbf6fffca64a13608f9bdcc2baf</code> |
| V11 NanoTimeKit | <code>bf3f7e360fe06ab7e513807bcb3b6ac695f38c6ea8cd8428b7aed579c2b58e1c</code> |
| V12 ClockKit | <code>5fc1784de78830eb83808a5663c87bf2be39bca08453b5d11ddef4dcad56cce0</code> |
| V14 NTKZeusFaceBundle | <code>2b34d3d411b77ee73f3892638f419eda83b7bedc4653ecf44adf7c975bbd72e4</code> |

这里列出的哈希是**研究者记录的具体文件摘要**，不等同于苹果官方发布的校验承诺。研究曾涉及 V10 FaceBundle、V11 NanoTimeKit、V12 ClockKit、V13 联合分析、V14 Zeus Bundle，以及 Xcode、LLVM、Mach-O 检查和固件提取工具。

**本仓库不包含，也不授权分享**苹果的原始 watchOS OTA、提取的私有动态库、原生 FaceBundle、<code>Assets.car</code> 或 Hermès 商标/表盘美术资源。开源 HermesEnabler 的 MIT 许可证**不等于**对 Apple 和 Hermès 专有资源的再分发许可。

### 11.2 如何判断证据是否可复现

复现时，应记录**文件名、Build、架构、大小、哈希、地址基准、读取方式和实验环境**。尤其需要避免：

- 将 Mach-O **文件偏移**与 **VM 地址**混淆；
- 将方法表附近的字符串碰巧匹配当成方法归属证明；
- 将本地 API 的结果当作某个 XPC 服务器 API 必然返回的结果；
- 将静态二进制中的代码路径当成实际已经运行；
- 将某个单独的“允许”条件当成完整系统资格判断；
- 将不同 build、不同设备的参数直接复制到当前 Apple Watch。

## 12. 常见问题与容易误解的地方

### Q1：固件里面有 Hermès 表盘，为什么我的 Ultra 1 还是看不到？

**因为固件存在和设备获准使用是两回事。** 苹果可能在通用固件里包含多个型号或产品线共用的 FaceBundle，再由 NanoTimeKit、ClockKit 和表盘类自身的检查决定哪些设备可见。V13 找到 Hermès 2025 的类别白名单；V14 找到 Zeus 系列的各自限制。

### Q2：把 DeviceBrand 改成 Hermès 的值不就行了吗？

**当前没有证据支持这句话。** 一方面历史实机测试无法获得系统 MG 写权限；另一方面 V13 已经显示 <code>deviceCategory</code> 具有独立的前置排除作用。单一 DeviceBrand 变更没有被证明能通过所有检查。

### Q3：supportsFall2025FacesCapability 都返回 1 了，为什么还不行？

因为这只是**某个在 Hermès 2025 Bundle 加载后注册的 category 方法**返回 true。即使该方法为 true，也不能取消之前的类别白名单，更不能让表盘自动出现和安装。

### Q4：Zeus Analog 不检查 {2,3,5}，是不是经典表盘可以成功？

**不是。**V14 显示 Zeus Analog 对 <code>collectionType=9</code> 的设备将走到 <code>NTKShowHardwareSpecificFaces()</code> 相关判断，而 V14 真实只读日志报告该值为 false、结果为 <code>RESTRICTED</code>。

### Q5：Class 13 都拿到沙盒 token 了，为什么还写不了？

因为**令牌的取得和消费并不等于对受保护目标有完整写权限**。历史实机前后对比均为 read allowed / write denied / create denied。

### Q6：MobileGestaltHelper 的 error 9 是不是 EPERM？

**不是。**Helper 返回的是 MobileGestalt 服务端的错误码；历史写入打开文件失败则是 POSIX <code>EPERM=1</code>。它们属于两个不同的失败层级。

### Q7：为什么 V13 和 V14 的 DeviceBrand 数值不一致？

因为记录显示的读取 API、对象及场景可能不相同，现有材料**还没有完整校准每次读取的来源**。旧值为 0，新日志中 <code>CLKDevice deviceBrand=399803152</code>。不应在没有验证的情况下认定其一为错误，也不应直接使用一个数值覆盖另一个。

### Q8：我在 GitHub 源码里找不到 V14 按钮？

因为**V14 是另外提供的研究/诊断快照**，不是已经合并到这里公开的 <code>ContentView.swift</code> 的功能。README 包含 V14 的研究结果，不代表源代码自动更新为 V14。

### Q9：目前有没有已经解锁 Hermès 的 IPA？

**没有经过验证的 watchOS 26.6.1 / 23U95 原生 Hermès 解锁 IPA。**本项目不应被当成一键解锁发布版本。

### Q10：如果以后某个门槛显示 ALLOWED，就能宣布成功了吗？

**还不能。**它至多说明这个**单独门槛**的计算结果。真正成功还要证明系统识别并展示、允许添加、实际渲染并持续稳定使用苹果原生表盘。

### Q11：能不能直接使用上游 HermesEnabler 最新安装方法？

上游项目的 README 和当前支持范围应以[原始仓库](https://github.com/pookjw/HermesEnabler)为准。**上游 watchOS 27 支持声明不等于本研究 watchOS 26.6.1 可用**。本仓库应以源码研究和安全诊断为主，而不是借用上游的安装教程来宣传本项目已经解锁。

## 13. 完成进度、未解决问题与下一步

### 13.1 当前研究状态表

| 阶段 | 状态 |
| --- | --- |
| 读取 23U95 的 MobileGestalt 缓存 | **实机成功** |
| 建立并核验对应构建版本的本地备份 | **实机成功** |
| 纠正 DeviceBrand 的真实描述符和偏移 | **已静态核对并纠正旧错误** |
| 获得系统缓存写权限 | **失败，EPERM** |
| Class 7、Class 13、Geod-MCM 实验 | **未取得所需写权限** |
| MobileGestaltHelper XPC 连接 | **连接成功，问题返回 error 9** |
| 找到 Hermès 2025、NanoTimeKit、ClockKit 代码 | **完成静态定位** |
| V13 Hermès 2025 白名单 {2,3,5} | **完成静态分析** |
| 解释 Ultra 类别 4/6 与白名单冲突 | **有明确的静态依据** |
| V14 确定六个 Zeus 家族限制实现 | **完成方法归属和部分分支分析** |
| 实机运行 V14 只读资格诊断 | **已有用户提供日志，显示 RESTRICTED** |
| 将 V13/V14 研究按钮正式集成、编译、测试到当前公开仓库 | **尚未证明完成** |
| 找到普通设备上受支持且稳定的完整表盘发现/安装路径 | **未解决** |
| 真正解锁 Apple Watch Ultra 1 原生 Hermès 表盘 | **未成功** |

### 13.2 更有价值的后续研究方向

1. **可复现性验证**：将 V13/V14 的二进制发现、设备日志与准确构建版本逐项对应，避免跨版本推断。
2. **DeviceBrand 来源校准**：在相同设备和运行环境下，比对本地 MobileGestalt 与 <code>CLKDevice</code> 读取上下文，解释 0 与 399803152 之间的差异。
3. **只读诊断整合**：如将 V13/V14 功能合并到公开源码，需要先做代码审计、Xcode 实际编译和手表测试，并另行注明每个按钮的作用。
4. **逐层理解资格链路**：区分类别判断、FaceBundle 注册、目录可见性、添加能力和实际正常渲染。
5. **继续研究未完整理解的分支**：包括 Bellona 的其他条件以及 Spectrum Zeus 等类的完整逻辑，但不把未完成分析宣传成解锁。
6. **及时更新失败结果**：每次新的测试都说明设备、Build、具体观察和限制，而不是只记录“看起来有希望”的现象。

当前仍**没有**已经验证的私有系统组写入授权方式、可持续的原生表盘安装方法或可靠的 stock-device 解锁流程。是否能够实现，需要新的可复现证据，而不是从一个条件分支推导出最终成功。

## 14. 原作者、衍生研究、许可和免责声明

### 14.1 致谢和版权归属

**原项目作者：**[Jinwoo Kim (@pookjw)](https://github.com/pookjw)，[HermesEnabler / HermesEnabler 2](https://github.com/pookjw/HermesEnabler)。原代码采用 **MIT License，Copyright (c) 2026 Jinwoo Kim**。请完整保留本仓库的 [LICENSE](LICENSE)。

**第三方代码：**[Gester](https://github.com/sasobhabha/Gester) 及相应贡献者。保留 [HermesEnabler2/Gester-LICENSE.txt](HermesEnabler2/Gester-LICENSE.txt)。

**RO23 衍生研究：**[@ZhuoXuan-MY](https://github.com/ZhuoXuan-MY)，涉及 Apple Watch Ultra 第一代、23U95 实机实验、系统缓存与权限研究、匹配固件反汇编、V13/V14 研究记录和中英文说明。AI 工具参与了部分代码与技术文档整理，但这不会改变原项目作者的版权归属。

**相关参考：**[原项目 Issue #17](https://github.com/pookjw/HermesEnabler/issues/17)、[Issue #7](https://github.com/pookjw/HermesEnabler/issues/7)、[worse_query](https://github.com/forcequitOS/worse_query)、[bad_query](https://github.com/forcequitOS/bad_query)、[Geod-MCM-PoC](https://github.com/0xjohnnydev/Geod-MCM-PoC)。其他研究者在其他设备上得到的结果属于**背景材料**，不能说成是本人的 Ultra 第一代实机结果。

具体来源、衍生说明和使用边界参阅 [NOTICE.md](NOTICE.md) 与 [PUBLICATION_CHECKLIST.md](PUBLICATION_CHECKLIST.md)。

### 14.2 Apple、Hermès 与原生资源

HermesEnabler 的开源许可证**不覆盖**苹果专有 watchOS 固件、提取的系统动态库、原生表盘文件、FaceBundle 资源，也不授予 Hermès 商标或美术素材的再分发权。本仓库不分发这些专有二进制及表盘图像。

### 14.3 风险与非官方声明

本仓库**不是苹果或 Hermès 官方项目，不是越狱工具，不是已经验证的权限绕过，也不是上游维护者支持的 watchOS 26.x 解锁版本**。请仅在自己有权控制的设备上审查并测试源码，保护日志、备份和签名隐私，不要将错误偏移、未经验证的写入操作或系统级修改用于日常设备。

---

**研究总结（2026-11-11）：RO23 已推进至 V14；Hermès 2025 和经典 Zeus 表盘的限制机制更加清楚，但 Apple Watch Ultra 第一代 / watchOS 26.6.1（23U95）的真正原生 Hermès 表盘解锁仍未实现。**
