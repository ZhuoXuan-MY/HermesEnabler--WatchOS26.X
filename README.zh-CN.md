# HermesEnabler RO23

*Apple Watch Ultra（第一代）· watchOS 26.6.1 · 23U95*

[English](README.md) · [HermesEnabler 原项目](https://github.com/pookjw/HermesEnabler) · [研究讨论：Issue #17](https://github.com/pookjw/HermesEnabler/issues/17)

> **项目仍在研究中，尚未解锁 watchOS 26.6.1 上的原生 Hermès 表盘。**
>
> 这是我基于 Jinwoo Kim 的 HermesEnabler 继续研究的独立分支。我把自己在 Apple Watch Ultra 上做过的测试、遇到的问题、检查过的系统文件以及目前得到的结果整理在这里。截至 RO23 V12，**还没有成功启用真正的原生 Hermès 表盘**，也没有经过验证、可以直接使用的 23U95 解锁 IPA。请不要把这个仓库当作已经完成的解锁工具。

## 目录

1. [我为什么开始 RO23](#1-我为什么开始-ro23)
2. [这个项目从哪里来](#2-这个项目从哪里来)
3. [测试设备和目前的结果](#3-测试设备和目前的结果)
4. [仓库里现在有什么](#4-仓库里现在有什么)
5. [RO23 V1–V12 调查记录](#5-ro23-v1v12-调查记录)
6. [DeviceBrand 偏移量的纠正](#6-devicebrand-偏移量的纠正)
7. [MobileGestaltHelper 为什么返回 error 9](#7-mobilegestalthelper-为什么返回-error-9)
8. [固件里有 Hermès 2025 表盘，为什么还是用不了](#8-固件里有-hermès-2025-表盘为什么还是用不了)
9. [V12 从 ClockKit 中找到了什么](#9-v12-从-clockkit-中找到了什么)
10. [哪些已经确认，哪些还没有](#10-哪些已经确认哪些还没有)
11. [如何用 Xcode 查看项目](#11-如何用-xcode-查看项目)
12. [研究文件和校验值](#12-研究文件和校验值)
13. [接下来准备做什么](#13-接下来准备做什么)
14. [原作者、致谢与许可](#14-原作者致谢与许可)
15. [相关链接与说明](#15-相关链接与说明)

## 1. 我为什么开始 RO23

最开始，我只是想弄清楚一件事：**第一代 Apple Watch Ultra 能不能在 watchOS 26.6.1 上使用 Apple 原生的 Hermès 表盘？** 如果不能，究竟是哪一层限制拦住了它？

最先想到的是 `MobileGestalt` 里的 `DeviceBrand`。但研究下去以后，我发现问题没有想象中那么简单。读到缓存、知道数据存在哪里，并不代表有权限修改；就算某个值真的能够改变，也不代表 NanoTimeKit 和 Hermès 表盘本身一定会接受这块手表。

于是我开始把问题拆开来查：先在手表上验证实际行为，再从对应版本的 watchOS 固件里寻找相关代码。RO23 就是这一系列实验的记录，目前整理到 **V12**。

我希望这个仓库能把走过的路、已经排除的猜测和真正有用的线索留住。**它现在不是一个点一下就能解锁表盘的项目。**

## 2. 这个项目从哪里来

这个项目的基础是 **[Jinwoo Kim（@pookjw）](https://github.com/pookjw)** 开发的 [HermesEnabler / HermesEnabler 2](https://github.com/pookjw/HermesEnabler)。原项目的应用架构、界面、已有的 MobileGestalt 相关实现、备份与恢复基础以及相关依赖，都来自原作者。这里必须把这一点说清楚。

**RO23** 是我给自己在 Ultra 1 和 23U95 上的实验起的名字。我使用自己的设备和 Mac/Xcode 环境反复测试，保存日志，提取对应固件，分析系统二进制文件，并在 [原项目的 Issue #17](https://github.com/pookjw/HermesEnabler/issues/17) 中记录过程。期间也使用了 AI 辅助编写实验代码、整理命令和分析资料；文中明确写出的手表测试结果，来自实际设备，不是模拟出来的结果。

我选择单独维护仓库，是因为这里研究的 **watchOS 26.6.1 / 23U95 并不是原项目当前公开承诺支持的版本**。独立存放这些实验，更容易让大家区分“原项目已经实现的功能”和“我还在验证的东西”。

这个分支不代表原作者的官方立场，也不隶属于 Apple 或 Hermès；它不是越狱项目，也没有被验证能够绕过系统私有权限。

## 3. 测试设备和目前的结果

以下实际设备测试，都是基于这套环境进行的：

| 项目 | 记录 |
|---|---|
| 测试手表 | Apple Watch Ultra（第一代） |
| 设备标识 | `Watch6,18` |
| 主板标识 | `n199ap` |
| 系统版本 | watchOS `26.6.1` |
| 系统构建号 | `23U95` |
| 架构 | `arm64_32` / ILP32 |
| 测试方式 | 修改后的 HermesEnabler2，Xcode 开发签名，自定义 App Group |
| 读取 MobileGestalt | **成功** |
| 备份及解析缓存 | **成功** |
| 写入受保护缓存 | **失败：`EPERM`** |
| Class 13 沙盒扩展 | 获得并使用 token，但仍不能写入 |
| MobileGestaltHelper XPC | 能连接、能收到回复，但测试问题均返回 `error=9` |
| Hermès 2025 原生表盘组件 | **已在匹配固件中找到** |
| 在这块 Ultra 上启用原生 Hermès 表盘 | **尚未成功** |

这些结果只适用于我测试的设备与系统版本。其他 Apple Watch 型号、其他 watchOS 构建版本，甚至不同的二进制文件布局，都不能直接照搬这里的结论。

## 4. 仓库里现在有什么

这里需要把**之前的本地实验版本**和**现在公开的研究代码**分开说明。

我最早用的本地修改版，包含 MCM 访问尝试、MobileGestalt 写入实验，以及启动后自动执行的诊断代码。其中 `BQWriteHermes23U95()` 曾使用错误的 DeviceBrand 偏移量。这段历史实验不应当被当作有效的解锁方法。

现在仓库里的公开版本已经做过清理：旧的强制写入路径已移除；MobileGestalt 保存、恢复以及表盘启用相关操作被禁用；RO23 诊断改为**手动点击按钮才会启动**。界面也明确标注了研究用途。

目前可以看到的内容主要包括：

- 在权限允许时读取 MobileGestalt，以及在**应用自己的目录**中生成本地备份。
- 检查设备兼容性和缓存访问情况。
- 对缓存记录、沙盒权限和 MobileGestaltHelper 做只读诊断。
- 将日志保存在 App 的 Documents 目录中。

需要说明的是：**公开仓库中的这一版还没有经过重新编译并在手表上完整验证。** 下面 V1–V12 的实验数据来自此前的本地测试版本，不能直接理解成当前 GitHub 代码已经复现了全部实验。

## 5. RO23 V1–V12 调查记录

这一部分按实际研究顺序整理。我没有删掉失败的尝试，因为很多后续判断，恰恰是靠这些失败结果一步步排查出来的。

### V1 之前：先读取缓存，再尝试写入

最早的本地版本已经能够读取 23U95 的 MobileGestalt plist，并创建匹配的备份。记录到的数据是：

```text
Plist 大小：          13,328 bytes
CacheUUID：           3BE19A76-F253-4CE4-AAC1-DF6D801CAAB1
CacheData：           6,309 bytes (0x18A5)
缓存布局：            701 个槽位，每个 9 bytes
CacheExtra：          72 项
本地 DeviceBrand：    0
```

我手上还留有 watchOS 26.5 的旧备份，但它的大小和 UUID 不同，**没有把那份旧缓存恢复到 23U95 上**。后续使用的是单独验证过的 `OriginalGestalt-23U95.plist`。

第一次查 DeviceBrand 时，我误以为它对应的是索引 `206`。基于这个判断写的实验代码尝试以写入方式打开缓存文件，但系统直接拒绝：

```text
MG FORCE: entering 23U95 write path
MG FORCE: 23U95 backup verified
MG FORCE: WRITE DENIED errno=1 (Operation not permitted)
```

也就是说，程序**连可写打开都没通过，更没有执行到 `pwrite`**。

我还尝试过三种 Class 7 标志位：`0x0800000000`、`0x8000000000` 和 `0x8100000000`，都没有取得可用的沙盒 token；Geod-MCM Class 12 路线也没能返回需要的容器对象。

### V1：在 MobileGestalt 中寻找 DeviceBrand

我开始检查手表进程中映射的 `libMobileGestalt.dylib`，寻找 DeviceBrand 对应的哈希键：

```text
DeviceBrand → fuKL2rMywRgQF1wowOA/cg
```

相关字符串和指针引用找到了，但我当时把**前一个描述符末尾的数据**错认成了 DeviceBrand 自己的记录。后面的 V3 才真正把这个问题纠正过来。

### V2：确认 API 实际返回什么

我使用正确的双参数形式 `MGCopyAnswer(CFStringRef, CFDictionaryRef)`，分别读取 `DeviceBrand` 和它的哈希键。两次返回的都是 **CFNumber，数值为 0**。

这里还有个容易混淆的地方：Core Foundation 的数值类型和 MobileGestalt 内部描述符的类型编号不是同一套东西，不能拿来互相对应。

### V3：把 DeviceBrand 的位置找对

重新检查 `arm64_32` 的描述符布局后，确认记录步长为 **100 字节（`0x64`）**。真正对应 DeviceBrand 的数据是：

```text
flags              12 (0x0C)
index              103
internal type      5
value offset       0x338
validity offset    0x164F
cached value       0
validity           1
```

此前的 `index=206`、`0x670`、`0x16B6` 实际属于另一条描述符，不是 DeviceBrand。这是整个 RO23 过程中非常重要的一次纠错。

### V4：拿到沙盒扩展，也不等于能写文件

使用 Class 13 MCM 查询和标志 `0x0800000000` 后，我成功获得并使用一个沙盒扩展；其中一次测试记录的 `handle=2`。

但对 MobileGestalt 缓存的权限检查，前后没有变化：

| 权限检查 | 使用 token 前 | 使用 token 后 |
|---|---|---|
| 读取文件 | 允许 | 允许 |
| 写入文件 | 拒绝 | 拒绝 |
| 创建文件 | 拒绝 | 拒绝 |

应用有普通的 application-groups entitlement，但没有相关的 Apple 私有 system-group entitlement。另一项元数据权限检查返回 `-1`，那代表**检查发生错误**，不能直接当作权限被拒绝的判断。

V4 没有修改系统缓存。

### V5：找到了 MobileGestalt 的 Mach 服务

通过 `task_get_special_port` 和 `bootstrap_look_up`，成功定位到 `com.apple.mobilegestalt.xpc`，返回 `kr=0`。

这至少确认服务可以被找到，但**找到服务不代表获得调用所有功能的权限**。

### V6：第一次收到 Helper 的回复

我通过 `NSXPCConnection` 连接 MobileGestaltHelper，并调用只读的 `getServerAnswerForQuestion:reply:` 查询 `DeviceBrand`。

连接和回复都正常，但返回内容只有：

```text
{ "error": 9 }
```

没有 `answer` 字段。我没有调用缓存重建，也没有进行系统缓存写入。

### V7：换几个问题继续验证

为了确认是不是只有 DeviceBrand 被拒绝，我把四个问题的本地 API 结果和 Helper XPC 回复进行了比较：

| 查询项 | 本地 `MGCopyAnswer` | Helper XPC |
|---|---|---|
| `DeviceBrand` | `CFNumber(0)` | `error=9` |
| `fuKL2rMywRgQF1wowOA/cg` | `CFNumber(0)` | `error=9` |
| `BuildVersion` | 能返回字符串 | `error=9` |
| `ProductType` | 能返回字符串 | `error=9` |

四次回复都只有 `error`，没有 `answer` 或 `logString`。

这里的 `error=9` 属于 MobileGestalt 的服务端结果，**不是 POSIX 的 `EPERM`，也不是 Mach/bootstrap 返回码**。这些错误不能混为一谈。

### V8：从对应固件提取 MobileGestaltHelper

后来我获取了与 `Watch6,18 / n199ap / 23U95` 匹配的 watchOS OTA，检查元数据和 `post.bom`，从 `payload.054` 中提取出 `MobileGestaltHelper`。

文件大小为 **76,112 字节**，属于 `arm64_32` Mach-O。部分工具在处理它的 ABI 或 Objective-C 元数据时遇到了问题，因此我换用 LLVM 和直接的 Mach-O 分析继续检查。

| 方法 | 分析文件中的地址 |
|---|---|
| `getServerAnswerForQuestion:reply:` | `0x5110` |
| `rebuildCache:` | `0x55F0` |
| `setCacheSentinel:` | `0x5714` |

在 `0x51C4` 处可以看到 Helper 调用了 `_MGServerCopyAnswerWithError`，这让 V7 的错误有了继续追查的方向。

**我没有调用 `rebuildCache:`。** 找到这个方法，并不代表它能够任意设置 DeviceBrand；贸然重建正在使用的系统缓存也有风险。

### V9：继续分析匹配的 libMobileGestalt

接下来从相同版本的 dyld shared cache 中提取出 `libMobileGestalt.dylib`，大小 **991,764 字节**。

分析中定位到：

```text
_MGServerCopyAnswerWithError    0x215B42A8
相关服务端权限检查             0x215B4BF4
```

三个查询键的描述符信息如下：

| 查询键 | Index | 内部类型 | Flags |
|---|---:|---:|---:|
| `DeviceBrand` | 103 | 5 | `0x0C` |
| `BuildVersion` | 62 | 9 | `0x0C` |
| `ProductType` | 530 | 9 | `0x0C` |

匹配的二进制里确实存在返回 error 9 的代码路径。结合这些描述符标志，能够解释为什么 **本地 `MGCopyAnswer` 可以拿到值，Helper 的服务端查询却可能拒绝同一个问题**。

不过这属于**静态代码分析得到的解释**，不是我对 V7 每一次请求都进行了完整的动态调用追踪。

另外，DeviceBrand 的提供者还涉及 `IODeviceTree:/chosen` 和 `marketing-software-behavior`。这说明不能把整个问题简单理解成“只要改一个缓存值就行”。

### V10：确认 Hermès 2025 原生组件就在 OTA 里

我继续检查对应固件，确认其中确实存在 Hermès 2025 表盘组件和相关系统文件：

| 组件 | 大约大小 |
|---|---:|
| `NTKHermes2025FaceBundle` 可执行文件 | 1.2 MB |
| Hermès `Assets.car` | 32 KB |
| `Carousel` | 185 KB |
| `ClockFace` | 406 KB |
| `nanotimekitd` | 734 KB |

`nanotimekitd` 中有 `com.apple.Hermes2025Face`、`_NTKFaceStyleIsAvailable`，以及删除不可用表盘的相关日志字符串。在约 `0x8260` 的静态调用位置，可以看到通用表盘可用性检查的线索。

V10 能确认的是：**Apple 的原生 Hermès 2025 组件确实存在于这份固件中。** 但“固件里有这个文件”和“这块 Ultra 允许使用它”完全是两回事。

### V11：找到 Hermès 表盘自己的设备限制

随后提取并分析了匹配的 NanoTimeKit framework 二进制，大小 **11,395,800 字节**。其中几个值得注意的位置是：

```text
_NTKFaceStyleIsAvailable                               0x544392B0
-[NTKFaceDescriptor isAvailableForDevice:]             0x543D998C
-[NTKFaceBundleManager faceBundleForBundleIdentifier:onDevice:forMigration:]
                                                        0x544B0DDC
```

Hermès 2025 bundle 中还能找到 `+[Hermes2025Face isRestrictedForDevice:]`，地址约为 `0x3B2C`，相关逻辑位于 `0x46B8` 附近。

这里出现了几个很关键的判断条件：

- `deviceCategory`
- `supportsFall2025FacesCapability`
- `collectionType`（其中有与 `0x5` 比较的代码）

这说明除了一般的表盘可用性检查，**Hermès 2025 还有自己的设备限制逻辑**。

截至 V11，我还没有在手表上测出这些属性的真实运行时值，因此不能说把 `DeviceBrand` 改成 1 就一定能通过检查。

### V12：用匹配的 ClockKit 继续核对

V12 使用了 `RO23-V12-ClockKit.zip` 中的文件。里面的 ClockKit 是一个有效的 **1,425,840 字节 `arm64_32` Mach-O**。

我核对了几个 `CLKDevice` getter 的实际指令：

```asm
-[CLKDevice deviceBrand]      0x49C6F144: ldr  w0, [x0, #0x3c]
-[CLKDevice deviceCategory]   0x49C30EB4: ldr  w0, [x0, #0x2c]
-[CLKDevice collectionType]   0x49C354F0: ldr  w0, [x0, #0x30]
-[CLKDevice isUltra]          0x49C6F11C: ldrb w0, [x0, #0x17]
```

ClockKit 里还存在设备信息加载，以及 NanoRegistry / PDR 能力查询的相关逻辑。但在这份 ClockKit 二进制中，**没有找到 `supportsFall2025FacesCapability` 的直接定义**。

V12 最大的收获，是进一步确认这些信息确实是**不同的设备字段**。然而它们在我的 Ultra 上究竟是什么值、由谁设置、Hermès bundle 如何组合判断，仍然需要继续验证。

**所以 V12 是一次成功的二进制提取与部分静态分析，不是表盘解锁成功。**

## 6. DeviceBrand 偏移量的纠正

前面提到过，这里再把最终确认的数据集中放一次，避免有人直接引用早期错误记录。

以下仅适用于这次分析的 **23U95 / arm64_32** 环境：

```text
键名：                  DeviceBrand
哈希键：                fuKL2rMywRgQF1wowOA/cg
CacheData：             6309 bytes = 701 × 9
描述符步长：            100 bytes
flags：                 12
index：                 103
内部类型：              5
Value offset：          103 × 8 = 0x338
Validity offset：       (701 × 8) + 103 = 0x164F
实际缓存值：            0
有效标志：              1
```

**不要再把 `index=206`、`0x670` 或 `0x16B6` 当作 DeviceBrand 的位置。** 它们来自早期错误的描述符边界判断。

当时两个候选位置恰好都读到了零，这也是错误没有马上暴露的原因。即使现在确认了正确位置，也不意味着获得了系统缓存的写入权限，更不意味着表盘限制已经消失。

## 7. MobileGestaltHelper 为什么返回 error 9

用最简单的方式概括这个现象：

```text
本地 MGCopyAnswer(DeviceBrand)        → CFNumber(0)
MobileGestaltHelper XPC 查询          → { "error": 9 }
```

V8 证明 Helper 调用了 `_MGServerCopyAnswerWithError`；V9 在**同版本 watchOS 的 libMobileGestalt** 中找到了 error-9 路径和服务端权限检查。

这让之前的结果变得合理：**某个问题可以通过本地 API 读取，不代表它也允许通过 Helper 的服务端 API 查询。**

这与 V7 四个问题全部失败的现象一致，但我没有逐条动态追踪其实际分支，所以还不能把静态分析说成完整的运行时证明。

另外，能连上 XPC 服务不代表能够写系统缓存。Helper 中存在 `rebuildCache:` 方法，也不代表它是一个可用的 DeviceBrand 修改接口。

## 8. 固件里有 Hermès 2025 表盘，为什么还是用不了

这次在 OTA 中确认的主要文件包括：

```text
System/Library/NanoTimeKit/FaceBundles/
  NTKHermes2025FaceBundle.bundle/
    NTKHermes2025FaceBundle
    Info.plist
    Assets.car
    hermes-*.plist
System/Library/PrivateFrameworks/NanoTimeKit.framework/
  nanotimekitd
System/Library/CoreServices/Carousel.app/Carousel
Applications/ClockFace.app/ClockFace
```

从 V10 和 V11 的代码线索来看，原生表盘能否使用，可能不止一个关卡：

1. 表盘是否会出现在可用目录中。
2. NanoTimeKit 是否允许当前设备使用对应的表盘类型。
3. Hermès bundle 自己的 `isRestrictedForDevice:` 是否通过。
4. `deviceCategory`、`collectionType` 和 Fall 2025 表盘能力等条件是否符合。
5. 即使前面通过了，仍要确认能否真正**添加、显示并长期正常使用**。

这只是基于静态调用位置整理出的判断路径，并不是我已经在 Ultra 上跑通的完整流程。**固件自带某个组件，并不自动代表每一台安装该固件的手表都能使用它。**

## 9. V12 从 ClockKit 中找到了什么

V12 之前，最容易产生的想法是：Hermès 的限制会不会就是 `DeviceBrand` 这一个开关？

ClockKit 提供了反证线索。`CLKDevice` 分别保存 `deviceBrand`、`deviceCategory`、`collectionType` 和 `isUltra`。至少从已经核对的 getter 来看，它们不是同一个布尔值。

目前还不知道的是：**这些字段在我的 Ultra 上分别是什么值，又是通过怎样的路径得到的？** `supportsFall2025FacesCapability` 最终依据哪些条件返回结果，也还没有完整答案。

因此下一步更值得做的，不是凭猜测去写受保护的缓存，而是先用只读方式取得实际设备信息，再对照 Hermès bundle 的判断逻辑。

## 10. 哪些已经确认，哪些还没有

| 研究内容 | 当前结论 |
|---|---|
| 读取并备份真实 MG 缓存 | **手表上已验证** |
| 找到正确的 DeviceBrand 描述符 | **已纠正，并有匹配二进制佐证** |
| 以写入方式打开受保护缓存 | **被 `EPERM` 拒绝** |
| Class 7 / Geod-MCM 替代路线 | **没有拿到可用访问权限** |
| 获取 Class 13 扩展 | **成功，但仍不能写入** |
| 连接 MobileGestaltHelper | **成功** |
| 通过 Helper 获取测试问题答案 | **失败，返回 `error=9`** |
| 在对应二进制中解释 error 9 | **有静态分析证据** |
| 找到 Hermès 2025 原生 bundle | **成功** |
| 找到通用及 Hermès 专属限制 | **静态分析中已发现** |
| 核对 ClockKit 的设备字段 getter | **成功** |
| 读取 Ultra 的实际 Fall 2025 相关能力值 | **尚未完成** |
| 真正启用并使用原生 Hermès 表盘 | **尚未实现** |

我会一直尽量区分三种情况：**实际手表日志确认过的结果、固件静态分析得出的结果，以及还需要验证的推测。** 它们不能混在一起当成“已经成功”。

## 11. 如何用 Xcode 查看项目

现在这个仓库主要面向愿意一起检查代码、复核研究过程的人。**它不是下载后就能直接解锁的成品。**

如果你要在自己的环境中查看或编译，需要 Mac、合适的 Xcode / watchOS SDK，以及你自己的开发签名设置。涉及手表测试时还需要可配对的 Apple Watch。

基本步骤：

1. 克隆或下载这个仓库。
2. 用 Xcode 打开 `HermesEnabler2.xcodeproj`。
3. 检查代码、entitlements、Bundle ID、App Group 和签名配置，按自己的环境调整。
4. 如果环境允许，使用自己的签名进行编译。
5. 仅使用明确标注的**手动触发、只读诊断**，并在应用的 Documents 目录检查日志。

主要文件大致如下：

```text
HermesEnabler2.xcodeproj/
HermesEnabler2/
  BQCore.m                  核心逻辑与研究诊断
  BQCore.h                  对外接口
  ContentView.swift         Watch 界面和诊断按钮
  HermesEnabler2App.swift
  HermesEnabler2.entitlements
  Gester-LICENSE.txt
LICENSE
NOTICE.md
README.md
README.zh-CN.md
```

普通开发者证书和普通 App Group **不会自动带来 Apple 私有 system-group 权限**。不要把早期本地写入实验、缓存备份，或者上游项目的 IPA 安装方法误当成 23U95 的可用解锁方案。

还要再次说明：**我尚未重新确认当前公开代码在真实手表上的完整编译和运行结果**。如果有人复测，希望记录清楚实际硬件、构建号与观察到的行为。

## 12. 研究文件和校验值

从 V8 开始，很多判断都依赖于**设备和构建版本匹配的系统二进制**。如果直接拿其他 iOS 或 watchOS 版本的代码来推断，很容易走偏。

下面是当时研究材料的 SHA-256：

| 文件 | SHA-256 |
|---|---|
| 下载的完整 OTA `.aea` | `8c04028c94a26eafc96e2dc50cf5c5296834ca30e0401b90fcf16d24d976c18b` |
| `MobileGestaltHelper`（V8） | `0e0c05244a3d35753e948783372f18e615ae2032cf7b750dd7a9cc57cfb3626e` |
| `libMobileGestalt.dylib`（V9） | `383dfd64b790ba505760bb4af7a08ed2df185cbf6fffca64a13608f9bdcc2baf` |
| `NanoTimeKit`（V11） | `bf3f7e360fe06ab7e513807bcb3b6ac695f38c6ea8cd8428b7aed579c2b58e1c` |
| `ClockKit`（V12） | `5fc1784de78830eb83808a5663c87bf2be39bca08453b5d11ddef4dcad56cce0` |

其中完整 OTA 的哈希，是**我实际下载文件**的摘要，并非 Apple 官方公布并由我独立验证的校验值。

用到的工具包括 [blacktop/ipsw](https://github.com/blacktop/ipsw)、LLVM `llvm-objdump`、Mach-O 分析工具、Xcode，以及手表本地日志。

文中列出的地址只针对**实际分析的特定二进制文件**，不能直接当成其他固件或设备的通用偏移量。

为了方便别人复核，我也建议把证据分清楚：

- **真实设备日志**：实际在 Ultra 上运行并观察到的结果。
- **匹配固件的静态分析**：某个符号、字段、方法或代码分支确实存在。
- **第三方报告**：其他人在其他环境里得到的发现。
- **推测**：目前能够解释现象，但还缺少运行时验证的判断。

截至 V12，没有成功写入受保护的 MobileGestalt 缓存，没有调用实时缓存重建，也没有成功启用原生 Hermès 表盘。

## 13. 接下来准备做什么

截至 V12，已经完成和还需要继续的部分如下：

- [x] 读取匹配的 23U95 MobileGestalt 缓存并留存验证过的备份。
- [x] 找出 DeviceBrand 正确的记录边界和偏移量。
- [x] 验证 Class 7、Class 13 MCM 与实际沙盒权限的区别。
- [x] 对比本地 MobileGestalt API 和 Helper XPC 的只读结果。
- [x] 提取并分析匹配的 MobileGestaltHelper 和 libMobileGestalt。
- [x] 在固件中找到 Hermès 2025 FaceBundle 与 NanoTimeKit 的可用性检查。
- [x] 找到 Hermès 自身的设备限制逻辑和 ClockKit 对应字段。
- [x] 从公开研究版本中移除旧强制写入路径，并把 RO23 诊断改成手动执行。
- [ ] 找出 `supportsFall2025FacesCapability` 的完整实现及其依赖条件。
- [ ] 只读检查这块 Ultra 实际的 `deviceCategory`、`collectionType` 和相关 capability。
- [ ] 分别验证表盘是否可见、能否通过检查、能否添加、能否正常显示与使用。
- [ ] 验证仓库当前版本能否干净编译并在真实手表上运行。
- [ ] 只有在真实设备上成功显示并添加原生 Hermès 表盘后，才更新项目的解锁状态。

后续我会尽量只在拿到新的、可以核对的结果时更新进度，不会把一个新猜测直接写成“突破成功”。

## 14. 原作者、致谢与许可

首先感谢 **[Jinwoo Kim（@pookjw）](https://github.com/pookjw)** 开发并公开了 [HermesEnabler](https://github.com/pookjw/HermesEnabler)。没有原项目，就不会有我现在继续研究的基础。原应用和原有工程成果都应当归功于他。

我是 **[@ZhuoXuan-MY](https://github.com/ZhuoXuan-MY)**，这里记录的是我在 Ultra 1 / 23U95 上进行的本地修改、设备实验、日志收集、固件分析和 RO23 研究笔记。研究过程也公开在 [Issue #17](https://github.com/pookjw/HermesEnabler/issues/17)。

另外感谢以下开源项目及研究者提供的资料和工具：

- [Gester](https://github.com/sasobhabha/Gester)
- [forcequitOS/worse_query](https://github.com/forcequitOS/worse_query) 与 [bad_query](https://github.com/forcequitOS/bad_query)
- [0xjohnnydev/Geod-MCM-PoC](https://github.com/0xjohnnydev/Geod-MCM-PoC)
- [PoomSmart/MGKeys](https://github.com/PoomSmart/MGKeys)
- [blacktop/ipsw](https://github.com/blacktop/ipsw)
- [EthanArbuckle 的 iOS 26.1 逆向研究](https://github.com/EthanArbuckle/iPhone18-3_26.1_23B85_Restore)
- [HermesEnabler Issue #7](https://github.com/pookjw/HermesEnabler/issues/7) 中提供其他设备测试结果的研究者

这些材料帮助我理解问题，但**其他系统或其他手表上的结果，不会被我写成 Ultra 1 已经验证成功**。

原 HermesEnabler 使用 **MIT License**，版权信息为 **Copyright (c) 2026 Jinwoo Kim**。仓库中的 [LICENSE](LICENSE) 保留原始版权和许可条款，[NOTICE.md](NOTICE.md) 说明本分支的来源与修改。重新分发使用到的第三方代码时，也需要保留对应声明，包括 `Gester-LICENSE.txt`。

MIT 许可并不意味着 Apple 的 watchOS 固件、私有 frameworks、Hermès 表盘资源或相关商标也可以自由重新发布。本仓库不以 MIT 许可分发这些专有系统文件。

## 15. 相关链接与说明

主要研究讨论在 **[HermesEnabler Issue #17](https://github.com/pookjw/HermesEnabler/issues/17)**，可以从以下记录找到前期过程：

- [最早的设备实验和 V1–V4 纠错](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6771229913)
- [V5–V7：Mach 服务和只读 XPC 测试](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6777128180)
- [iOS 26.1 上 error 9 的早期研究背景](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6777139375)
- [V8：对应固件和 MobileGestaltHelper 分析](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6777949079)
- [V9：对应版本的 libMobileGestalt 分析](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6778385658)

V10–V12 的总结来自后续本地固件分析；**我没有把它们说成已经逐条发布在 Issue #17 的评论中**。

最后还是想说明，涉及私有 API、系统缓存和权限机制的实验都有风险。错误的偏移量或写入方式，可能造成崩溃、系统异常甚至数据损坏。不要直接运行旧版强制写入路径，也不要随意重建正在使用的 MobileGestalt 缓存。

**目前第一代 Apple Watch Ultra / watchOS 26.6.1 上的原生 Hermès 表盘仍未成功解锁。** RO23 还会继续围绕已经找到的限制条件研究，但是否能最终实现，我不会提前给出保证。

---

*原项目：Jinwoo Kim（@pookjw）· RO23 独立研究：@ZhuoXuan-MY。与 Apple、Hermès 及原项目维护者均无官方关联。*
