# HermesEnabler · watchOS 26.x — 独立源码验证：WorstGestalt vs WatchRegion vs Ultra 1 / 23U95

**验证范围与时间：** 2026-11-12，北京时间（UTC+08:00）。目标设备是我实际使用的 Apple Watch Ultra 第一代 `Watch6,18 / n199ap`、watchOS 26.6.1 `23U95`。

**实际完成：** 从 GitHub 取得 WorstGestalt、WatchRegion、WQFiles 以及我自己的 HermesEnabler 最新仓库**源代码**，逐项检查权限请求、源文件分支顺序、文件打开方式、成功标准，并运行 10 项**纯源码静态断言**；另核对 WatchRegion 的公开 Issue 及评论以确认实机支持范围。此处的“验证”指**源码可复现性/已有案例验证**，**不是**在我的 Ultra 1 上实际运行新的漏洞或写入代码。没有连接手表、调用 MCM、修改文件或执行越狱。

## 一、我实际完成的源码断言

对源码快照进行的 10 项断言，**8 项符合 / 2 项不符合**；两个“不符合”不是代码出错，而是专门检查目前**没有**的能力或证据。

| 检查项 | 静态结果 | 含义 |
|---|---|---|
| WorstGestalt 有独立 `bad_query-file` 路径 | **YES** | `BQCore.swift` 里独立实现了文件级分支 |
| 这个分支在普通 Class 13 遍历之前运行 | **YES** | 其调用优先级和我现有项目不同 |
| WorstGestalt 会实际试探 `open(O_RDWR)` | **YES** | 以成功取得文件 FD 为判断标准，防止只取得不可写的 token 就报告成功 |
| WorstGestalt 文件级构造使用较短的相对路径形式 | **YES** | 与原有方案的访问对象和处理方式不一样 |
| WorstGestalt 文件级实现使用 Class 13 且有独立查询配置 | **YES** | 不是直接复用 `worse_query` 的普通 AppGroup 分支 |
| 当前 HermesEnabler 的旧 Class 13 方案采用不同访问形式与查询设置 | **YES** | 不能把此前旧测试的失败当成新方法已执行过 |
| **当前 HermesEnabler 已内置同样的文件级 `bad_query-file` 实现** | **NO** | **未内置**；当前只存在普通 Class 13 遍历/直连等路径 |
| WatchRegion 的真实写入仍先打开文件的可写描述符 | **YES** | 最终仍受 watchOS 文件权限约束 |
| WQFiles 官方 README 明确指出其 iOS 26 方法无法访问 SystemGroup | **YES** | 支持“`worse_query` 路线不等于 SystemGroup 写入”结论 |
| **WorstGestalt / WatchRegion 已在我这台 `Watch6,18 / 23U95` 上成功写入** | **NO** | **没有任何新真机证据**，不能声称成功 |

### 可独立核查的源文件版本

| 项目 | 本次读取的 Git blob SHA | 关键源码 |
|---|---|---|
| WorstGestalt | `16ef04546e7e99b65cee08eba3143d70a3ac8a25` | [`Sources/WorseGestalt/BQCore.swift`](https://github.com/GoldenNugget-Team/worstgestalt/blob/main/Sources/WorseGestalt/BQCore.swift) |
| 我自己的 HermesEnabler | `c523f026bfbe49444de6bb38f6268b5d619dbf4d` | [`HermesEnabler2/BQCore.m`](../HermesEnabler2/BQCore.m) |
| WatchRegion | `a6083a7bcde8f3799c812880c51634a5abfcd247` | [`WatchRegion/RegionCache.swift`](https://github.com/LogicSense1/WatchRegion/blob/main/WatchRegion/RegionCache.swift) |
| WQFiles | `dd31701074966d74cae4e2e0b9984efe6f2e6f93` | [README](https://github.com/kolbicz/WQFiles/blob/main/README.md) |

## 二、关于 WorstGestalt：具体证明了什么？

1. 上游 [WorstGestalt 1.0.0](https://github.com/GoldenNugget-Team/worstgestalt/releases/tag/v1.0.0) 声称在 **iOS 26** 可通过 `bad_query` 的 Class 13 Backend B 修改 MobileGestalt；适用声明是 **iPhone/iPad**，不是 watchOS。
2. 源码中有独立 `escapeBadQueryFile` 函数，尝试对**目标 plist 文件**获取访问能力。和我现有 HermesEnabler 中的 Class 13 **目录级**分支并不是同一个完整的调用流程。
3. 此文件级实现**取得沙盒令牌后还检查是否能打开可写文件**，而我旧版本的通用 Class 13 分支只根据 token/查询返回值判断早期阶段成功。这有可能解释之前“拿到 token，但实际打开被拒绝”的现象；**并不能证明新方法在 Watch 上一定会成功**。
4. 故障如果发生在 `open(O_RDWR)`，即使 `MobileGestalt.plist` 可读、其二进制结构完全掌握，仍然**不能实际修改受保护缓存**。

**判定：** 文件级 Class 13 是**新发现的、值得进一步审查的不同路径**，但当前并无 watchOS 26.6.1 实机执行结果。**静态一致性验证：通过；Ultra 1 写入权限验证：未完成。**

## 三、WatchRegion：有更新的实机证据，但全是 watchOS 27

我核对了 [WatchRegion 0.4.0](https://github.com/LogicSense1/WatchRegion/releases/tag/v0.4.0) 和作者的实际代码：

- `WatchRegion/RegionCache.swift` 仍调用 `worse_query` 得到 token，再打开 `com.apple.MobileGestalt.plist` 的写入文件描述符，进行带有回滚/读回确认的写入。
- 发布包明确为 **watchOS 27.0+**；公开成功的原有案例是 **Ultra 4 / watchOS 27.3 beta 1**。
- **新的额外成功案例（更正早期记录）：** [Issue #4](https://github.com/LogicSense1/WatchRegion/issues/4) 的使用者声称在 **Apple Watch Ultra 2 / watchOS 27.2 稳定版 `24S118`** 上，通过 WatchRegion 0.4.0 把地区改为 US/LL/A 并启用 Siri AI；这属于使用者自述，不是我们独立测试。由此不能再说“公开成功案例只有 Ultra 4”，但**仍没有 Ultra 1 / 23U95 成功证据**。
- [Issue #1](https://github.com/LogicSense1/WatchRegion/issues/1) 有人提出“Ultra 一代能否修改”问题，**截至本次核查没有维护者回复或实机成功报告**。

**判定：** WatchRegion 有多个 **watchOS 27** 不同机型的公开成功观察，证明它不是纯理论工程；**不能延伸到当前 Ultra 1 / watchOS 26.6.1。**

## 四、哪些结论不能夸大

- **不能说“新技术已修复 23U95 EPERM”。** 只有源代码比较和 iOS/其他 watchOS 构建报告，**没有 23U95 的可写文件描述符/读回数据**。
- **不能说“之前 Class 13 失败，WorstGestalt 一定失败”。** 实现路径不同；此前真实日志只覆盖已经执行的旧分支。
- **不能说“只要能写 MobileGestalt，就能开启 Hermès”。** 在目标固件里还存在独立的 Hermes2025/Circulaire-Poodle 资格判断与系统添加检查。
- **不能把手表 Simulator 与物理设备混为一谈。** 原作者 1.5 在 watchOS 27 Simulator 的 MobileGestalt 提示不代表真机权限结果。
- **不要直接让未经验证的新分支在主力手表上执行数据写入、截断、重命名或恢复**，否则存在损坏受保护缓存、甚至需要恢复整机的风险。

## 五、实际后续门槛

若未来确有同型号同构建的权限验证，必须分别记录：**文件能否以写权限安全打开、是否保持缓存数据完整、系统是否实际接受原生表盘、重启后是否持久存在**。目前仍不满足第一个条件。

**项目状态：`BLOCKED — NOT UNLOCKED`。** 本轮完成了能由我独立完成的仓库/公共证据验证，不冒充已在物理手表运行。

## 引用来源

- [WorstGestalt 源码](https://github.com/GoldenNugget-Team/worstgestalt/blob/main/Sources/WorseGestalt/BQCore.swift)
- [WorstGestalt 1.0.0 发布版](https://github.com/GoldenNugget-Team/worstgestalt/releases/tag/v1.0.0)
- [WatchRegion 0.4.0](https://github.com/LogicSense1/WatchRegion/releases/tag/v0.4.0)
- [WatchRegion Issue #1（Ultra 1 提问）](https://github.com/LogicSense1/WatchRegion/issues/1)
- [WatchRegion Issue #4（Ultra 2 / 27.2 用户报告）](https://github.com/LogicSense1/WatchRegion/issues/4)
- [WQFiles README（iOS 26 SystemGroup 界限）](https://github.com/kolbicz/WQFiles/blob/main/README.md)
- [我自己的历史真机状态页](RO23-STATUS.zh-CN.md)
