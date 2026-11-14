# watchOS 26.6.1 工具、漏洞与沙箱逃逸路线全类目核查（2026-11-14）

> **实际研究对象：** 我自己的 Apple Watch Ultra 第一代，`Watch6,18 / n199ap`，watchOS 26.6.1，build `23U95`。  
> **核查日期：** 2026-11-14（北京时间/马来西亚时间，UTC+08），对已发现的公开项目按类别系统性核查，并非声称穷尽互联网上一切私人 exploit。  
> **方法：** 我重新查看本仓库现行中英文 README、历史真机报告与最近的四份审计；从 GitHub 原始仓库的 README、发行版本和部分源码，以及 Apple 官方兼容/安全公告、研究者公开页面交叉核验。区分 **watchOS 真机证据**、**iPhone/iPad 实测**、**源码静态分析**、**工具说明**、**历史漏洞**、**未经验证的移植设想**。  
> **实际执行：** 这次**没有连接 Apple Watch、编译 IPA、利用漏洞、重签工具、修改系统缓存、越狱或解锁 Hermès**；没有修改本仓库应用程序代码。  
> **结论：** 截止本轮证据，**没有一个工具已在我的 `Watch6,18 / 23U95` 上独立证明可打开并写入受保护 `systemgroup.com.apple.mobilegestaltcache`**。历史实机 `open(O_RDWR) → EPERM` 仍然有效；与此独立的 Hermès 表盘资格限制也没有解决。

## 一、如何判断“对 Apple Watch 有帮助”

**A = 本机相关、值得直接跟踪的研究路径**（不是已能解锁）；**B = 有具体技术/源码借鉴价值但尚未适配 watchOS**；**C = 只辅助测试、通信、签名、取证，不提供权限**；**D = 当前平台或漏洞时代不匹配，不能当候选解锁工具**。

判断门槛依次是：①在 Apple Watch 上运行或有明确 Watch 通道；②能否访问 **Watch 自己的**受保护 `SystemGroup`，不混淆 iPhone 的相似路径；③能否得到**真实的可写文件描述符**（有令牌但 `EPERM` 算失败）；④写入后完整读回、重启持久；⑤原生 Hermès 资格、正常添加与持续显示。单独获得路径、配对、App Group、沙盒令牌、root 于**另一台设备**，或者取得 Watch 诊断日志，都不算通过这些门槛。

## 二、真正面向 Apple Watch 的项目与配对/开发工具（7 项）

| 工具 / 原始来源 | 平台及已有证据 | 对 `Watch6,18 / 23U95` 的判断 | 类别 |
|---|---|---|---|
| [pookjw/HermesEnabler](https://github.com/pookjw/HermesEnabler) · [v1.5.4](https://github.com/pookjw/HermesEnabler/releases/tag/1.5.4) | 真正 watchOS 原生应用；**1.5.4（11/13）仅新增越南语本地化**；1.5.3 新增部分 watchOS 27 build；README 写明仅 **watchOS 27.0–27.3 beta 1** | **A（持续观察上游）**：真实代码可作为表盘/缓存处理参考，但 **不支持 `23U95`**；不能把上游发布的新版本当新漏洞 | A |
| [LogicSense1/WatchRegion](https://github.com/LogicSense1/WatchRegion) · [v0.4.0](https://github.com/LogicSense1/WatchRegion/releases/tag/v0.4.0) | **watchOS 27+** 独立应用；Ultra 4/27.3 beta 与 [Ultra 2/27.2 Issue #4](https://github.com/LogicSense1/WatchRegion/issues/4) 有用户真机写入报告；[Issue #1](https://github.com/LogicSense1/WatchRegion/issues/1) 有人问 Ultra 1，但没有成功回复 | **A（权限模型/写入核验参考）**：需手表本身拿到权限；`worse_query` 的 27 成功不能证明 26.6.1 | A |
| [AdminZachary/WatchBridge](https://github.com/AdminZachary/WatchBridge) | Windows/macOS Watch 开发者模式准备、配对、IPA/Watch App 签名安装、RSD/Wi-Fi；README 说明已在物理设备走通完整安装流程 | **C（便利实机诊断部署）**：连接/开发者模式/签名 **不是越狱、不是 SystemGroup 写权限**；Watch 组合仍需验证 | C |
| [AdminZachary/iloader-for-windows](https://github.com/AdminZachary/iloader-for-windows) | 另一份可用的 Windows/macOS 手表侧载工具，开发者模式/IPA 安装，借鉴 `xtool` 实验流程 | **C**：可供 Windows 端部署只读诊断，但没有新的内核权限或对 Watch 的任意文件写入 | C |
| [RomashkaTea/apple-pairback](https://github.com/RomashkaTea/apple-pairback) | **真实 watchOS 26 配对案例**：例如 SE2/26.6 与 iOS 18.6；使用 **iPhone 端 DarkSword** 来开启跨版本 Network Relay Pairing | **B/C（跨版本配对机制参考）**：成果是 iPhone 与 Watch **配对成功**，不是对 Watch 内部 MG 写入；不建议为此在个人 iPhone 运行危险 exploit | B |
| [tihmstar/jelbrekTime](https://github.com/tihmstar/jelbrekTime) | 历史真正的手表越狱研究：**Series 3 / watchOS 4.1 / v0rtex**（2018） | **D（体系结构参考）**：旧内核/硬件/系统，不支持 Ultra 1/watchOS 26 | D |
| [PsychoTea/OverCl0ck](https://github.com/PsychoTea/OverCl0ck) | 实验原型，针对 **watchOS 3** / v0rtex；原 README 甚至标示仍需修复 | **D（历史资料）**：不能通过旧系统内核补丁路线推断 `23U95` 可用 | D |

## 三、MobileGestalt、SystemGroup 与沙箱访问项目（10 项）

| 工具 / 原始来源 | 实际公开支持与代码事实 | 对本机写入权限的结论 | 类别 |
|---|---|---|---|
| [GoldenNugget-Team/worstgestalt](https://github.com/GoldenNugget-Team/worstgestalt) · 1.0.0 | iPhone/iPad **iOS 26/27**；Backend A `worse_query`、Backend B `bad_query`；`BQCore.swift` 包含**文件级 Class-13 查询**并在拿到令牌后检查可写 FD | **B（本轮最值得细查的未验证变体）**：不同于我旧项目的普通 Class-13 路径；仅 **iOS 26** 支持声明，无 23U95 Watch 结果 | B |
| [forcequitOS/bad_query](https://github.com/forcequitOS/bad_query) | iOS 26/27 sandbox 路径研究，源码/README 描述 MCM 与容器范围；平台是 **iOS** | **B**：有 API 与权限模型参考，**不能推断 Watch MCM/沙盒相同**；仅返回 token 不代表能写 | B |
| [forcequitOS/worse_query](https://github.com/forcequitOS/worse_query) | iOS 26/27 工具；原 README 特别把 `/var/containers/Shared/SystemGroup/*` 标记为 **iOS 27** | **B**：可参考容器查询，但对 `23U95` **没有已验证的 SystemGroup writer** | B |
| [0xjohnnydev/Geod-MCM-PoC](https://github.com/0xjohnnydev/Geod-MCM-PoC) | iOS 26、27 beta 的 geod/MCM traversal PoC，针对系统缓存目录的特定访问范围 | **B（历史尝试已覆盖部分思想）**：本项目 Ultra 1 既有 geod-MCM 实机诊断没有得到有效 Watch 写入，不能把 iOS PoC 再称为新成功 | B |
| [kolbicz/WQFiles](https://github.com/kolbicz/WQFiles) · [v0.9.6](https://github.com/kolbicz/WQFiles/releases/tag/v0.9.6) | **11/13 更新到 0.9.6**，新增文件搜索、最大文件等；README 说明 iOS 26 可处理应用/扩展/daemon/App Group，**不能访问 System Data / SystemGroup** | **D（作为直接写入方案）／C（诊断交互借鉴）**：不是 watchOS App，无法赋予手表 SystemGroup 权限 | C |
| [jailbreakdotparty/Erosion](https://github.com/jailbreakdotparty/Erosion) · [0.3.1](https://github.com/jailbreakdotparty/Erosion/releases/tag/0.3.1) | iOS 26/27 定制工具；**0.3.1 改为 `pathleak` 枚举容器**；README 明说 **iOS 26 上没有 MobileGestalt tweaks** | **B（容器发现研究）**：`pathleak` 用于列举可见容器，不等于能打开手表系统文件为写入 | B |
| [pwnapplehat/EscapeOS](https://github.com/pwnapplehat/EscapeOS) · [v0.3.2](https://github.com/pwnapplehat/EscapeOS/releases/tag/v0.3.2) | iPhone 应用容器、App Group 浏览与备份；没有 watchOS 目标 | **C**：对 iPhone Bridge 数据核查可能有帮助，不能直接访问配对手表 MG | C |
| [huamidev/GestaltX](https://github.com/huamidev/GestaltX) · [v1.1.1](https://github.com/huamidev/GestaltX/releases/tag/v1.1.1) | iPhone/iPad；自配对 + RSD/Lockdown + LocalDevVPN + syslog，**采集本机通知音路径**；README 说系统 MG 访问需要 **iOS 27** | **C（只读日志思路）**：`Pair this iPhone once` 不是 Watch 系统文件授权。详见[此前已审计报告](2026-11-14-GestaltX-v1.1.1-Device-Pairing-Compatibility.md) | C |
| [TIGI Filza](https://www.tigisoftware.com/default/?p=439) · 5.0.1 beta build 3 | iPhone/iPad/iPod touch 的文件编辑器，有文件浏览/编辑能力但受本机已有沙盒/越狱权限限制；无已验证的 watchOS 安装或远端系统写入 | **C**：即使在 iPhone Watch App 的普通容器里见到 `ClockKit.plist`，也不是手表内的受保护 MG 缓存 | C |
| [Gester（HermesEnabler 上游引用的组件）](https://github.com/pookjw/HermesEnabler) | HermesEnabler 官方 README 给出 Gester credit；本轮**未核实独立上游仓库版本或 23U95 适配** | **证据不足**：仅作为上游代码来源线索，不杜撰独立 watchOS 26 绕过方案 | B |

## 四、越狱、旧漏洞、备份/恢复改写工具（12 项）

| 工具 / 原始来源 | 实际平台或局限 | 本机结论 | 类别 |
|---|---|---|---|
| [opa334/Dopamine](https://github.com/opa334/Dopamine) · [3.0.13](https://github.com/opa334/Dopamine/releases/tag/3.0.13) | **iOS/iPadOS** 越狱；新版确实支持特定 **A12/A13 iOS 26.0–26.0.1** 设备，并不是 watchOS 26.6.1 | **D**：不能安装在 Ultra 1/23U95，也不能因 iPhone 已越狱就取得 Watch root |
| [palera1n](https://github.com/palera1n/palera1n) | checkm8 路线面向 A8–A11 iOS/iPadOS/tvOS/bridgeOS 指定设备；**没有 Ultra 1 的 bootrom 支持声明** | **D**：跨设备/芯片/启动链不适用 |
| [opa334/TrollStore](https://github.com/opa334/TrollStore) | 依赖特定 **iOS CoreTrust** 签名漏洞，iOS 17.0.1+ 不在其常规支持范围；并非 watchOS 通用私有权限发行器 | **D**：即使 iPhone 侧载成功，**不能给 Watch 受保护容器签出额外系统 entitlement** |
| [DarkSword 公开研究（Google Threat Intelligence）](https://cloud.google.com/blog/topics/threat-intelligence/darksword-ios-exploit-chain) | 真实存在的**iOS 18.4–18.7** exploit chain；涉及 WebKit、sandbox、内核与权限；部分组件已在 iOS 26.1–26.3 修复 | **B（漏洞链研究）／D（现成工具）**：不能据此认定 watchOS 26.6.1 仍有可用链；不运行来源不明 payload |
| [Lrdsnow/PureKFD](https://github.com/Lrdsnow/PureKFD) | iOS 14–18.1 beta 相关 KFD/MDC/SparseRestore 自定义工具 | **D**：非 watchOS 26.x 权限路径 |
| [leminlimez/Cowabunga](https://github.com/leminlimez/Cowabunga) | iOS 旧版本 MacDirtyCow（CVE-2022-46689）工具，旧项目已停更 | **D**：不能适用 watchOS 26.6.1 |
| [straight-tamago/misaka](https://github.com/straight-tamago/misaka) | iOS/tvOS 旧版 KFD/MDC 定制工具 | **D**：旧 OS/漏洞不匹配 |
| [straight-tamago/misakaX](https://github.com/straight-tamago/misakaX) | iOS 16–18.1 beta 备份/恢复改写工具 | **D**：未提供 Watch 26 SystemGroup 路线 |
| [leminlimez/Nugget](https://github.com/leminlimez/Nugget) | iOS 备份/部分恢复工具，部分 MG 功能在 **iOS 26.1 以下**，且作者警告 iOS 27 有丢数据风险 | **B（备份安全设计）／D（目标可用性）**：iPhone 的 restore 域不是手表的 SystemGroup 写权限 |
| [MNS82/nugget-iOS](https://github.com/MNS82/nugget-iOS) | iPhone 端 SparseRestore/BookRestore；README 明确 **iOS 26.2+ 不支持 MG tweaks** | **D**：不适用于 watchOS 26.6.1 |
| [khanhduytran0/SparseBox](https://github.com/khanhduytran0/SparseBox) | iOS 端 SparseRestore/BookRestore、AFC、配对/恢复组件 | **B（恢复/备份模型参考）**：不能等同于可写 Apple Watch 系统缓存 |
| [jailbreakdotparty/bookrestore](https://github.com/jailbreakdotparty/bookrestore) | iOS 任意文件覆盖 PoC 的历史仓库已归档，README 作者甚至标明旧实现不工作；补丁边界为 iOS 26.2 beta 2 | **D**：历史脆弱路径与今天的 watchOS `23U95` 不是同一漏洞成功验证 |

## 五、部署、诊断、固件分析与工具链（8 项）

| 工具 | 已核实用途 | 项目价值 | 类别 |
|---|---|---|---|
| [blacktop/ipsw](https://github.com/blacktop/ipsw) | 提取和分析 Apple OTA / dyld cache / Mach-O 等静态内容；已有我研究中配套 `23U95` 固件分析经验 | **A（离线分析）**：可用于核查 NanoTimeKit/ClockKit、MCM 版本差异，但不是获取设备权限 | A |
| [PoomSmart/MGKeys](https://github.com/PoomSmart/MGKeys) | MobileGestalt 键名、哈希对应分析；README 的键库目前依据 iOS 27.2 | **A（只读研究）**：可用来核对键名，**不用于猜测 Watch 专有缓存记录偏移或写入权限** | A |
| [doronz88/pymobiledevice3](https://github.com/doronz88/pymobiledevice3) | 配对、设备诊断、Lockdown/相关协议客户端 | **C**：读日志/设备服务参考，取决于具体 Watch 服务是否可用，配对≠系统 root | C |
| [libimobiledevice/libimobiledevice](https://github.com/libimobiledevice/libimobiledevice) | iOS 设备通信与配对协议库 | **C**：可辅助开发测试/取证，不发放 Apple Watch 系统写权限 | C |
| [libimobiledevice/idevicerestore](https://github.com/libimobiledevice/idevicerestore) | iOS 固件恢复/升级相关工具 | **D/C**：没有通过工具就可以任意改写 `23U95` MG 的证据；不可当作无风险手表降级方案 | C |
| [pwnapplehat/iPASide](https://github.com/pwnapplehat/iPASide) | Windows 端 iPhone IPA 签名侧载程序 | **C**：侧载 ≠ 越狱；不替代 Watch App 签名/部署的独立验证 | C |
| [checkra1n/PongoOS](https://github.com/checkra1n/PongoOS) | 老设备 boot chain 的研究环境 | **D（历史参考）**：非 Ultra 1 的公开通用引导 exploit | D |
| [Xcode / Apple Developer watchOS 工具链](https://developer.apple.com/watchos/) | 官方开发者模式、真机 App 运行、只读日志、符号调试 | **A（可信的只读基线）**：能验证真实 `23U95` 行为，但普通签名依然受到 sandbox/entitlement 限制 | A |

**本轮覆盖上表共 37 个工具/项目/独立组件（7+10+12+8）。** “全部”仅指我在本轮可发现且能核查的公开候选，**不是保证世界上不存在私有工具、未公开 PoC 或未来 0-day**。不把没有来源的项目名强行填进去。

## 六、Apple 官方漏洞公告和与 23U95 相关的门槛

| 来源 | 有哪些值得研究的类别 | 为什么不是现成解锁 |
|---|---|---|
| [Apple watchOS 26.6 安全公告](https://support.apple.com/en-us/128068)（2026-07-27） | MediaRemote root `CVE-2026-43723`；libc sandbox escape `CVE-2026-28973`；AVEVideoEncoder 内核执行 `CVE-2026-64747`；Kernel write `CVE-2026-43724` / `CVE-2026-64751`；WebKit 沙盒外读 `CVE-2026-43821` | **这些是 26.6 已修复项**；目标 26.6.1 是更新的构建。官方说明冲击面不等于给出仍可在当前固件复现的 PoC |
| [Apple watchOS 26.6.1 安全公告](https://support.apple.com/en-us/149723)（2026-11-09） | Bluetooth `CVE-2026-113970`、CoreUtils 配对相关缺陷、AirPlay/rapportd 等 | **这些是 26.6.1 修复项**；配对/邻近网络缺陷不等于设备端已获得 MG 写入权限 |
| [The Apple Wiki: watchOS 26 jailbreak matrix](https://theapplewiki.com/wiki/Jailbreak/26.x) | 在公开社区矩阵中 **watchOS 26.6.1 / Ultra 1 为 No Tool Available** | 只能推出“未发现公开可用工具”，不能证明理论上永远无法越狱 |
| [Apple watchOS 27 兼容设备](https://support.apple.com/en-my/108926) | 官方限定 watchOS 27 支持 **Series 9+、Ultra 2+、SE 3** | **第一代 Ultra 不在列表**；不能以升级到 watchOS 27 作为已经可行的解决方案 |

## 七、这轮真正增加的情报（相对于 11/12–11/14 已有记录）

1. **HermesEnabler 新版本：`1.5.4`（2026-11-13）**，发布说明仅添加越南语；`1.5.3` 主要扩大 watchOS 27 build 支持。**未出现 `23U95` 写入权限证据**。
2. **WQFiles 新版本：`0.9.6`（2026-11-13）**，文件夹搜索、最大文件等便利功能；**作者仍明确 iOS 26 无法访问 SystemGroup**。
3. **Erosion `0.3.1`** 的 `pathleak` 容器枚举是新的源代码研究方向，但只说明**找到路径**，并没有宣称 watchOS 或 protected SystemGroup writable。
4. **WatchBridge** 当前包含 Windows/macOS 物理手表安装流程，对开展真实 Watch **只读诊断部署**有参考价值；它不是沙箱逃逸工具。
5. **PairBack 的 watchOS 26 跨版本配对结果**值得保留作为 Watch 通信/配对机制材料；它使用的是 iPhone 端实验性漏洞，**不能跨设备授权 Watch 文件访问**。
6. **Dopamine 3.x 有特定 A12/A13 iOS 26.0–26.0.1 支持**；因系统和硬件都不同，**不是 Ultra 1/watchOS 26 的公开越狱**。
7. 我额外查了旧 watchOS 真实越狱 **jelbrekTime / OverCl0ck** 及官方 26.6/26.6.1 多类 CVE，仍**没有**今天可在 Ultra 1/23U95 上验证成功的路径。

## 八、下一步只保留可验证的研究问题

**优先级 1（A/B）：** 继续看新的 **watchOS 原生 MCM/SystemGroup** 成功证据；核对 WorstGestalt 与当前 BQCore 的文件级/Class 13 权限判断差异。要先有能证明在同型号同固件取得 **可写文件访问**的独立材料，不能直接写受保护文件试错。

**优先级 2（A/C）：** 用 Xcode、匹配固件、`ipsw`、MGKeys、可授权的只读日志/配对服务，保留不修改 Watch 系统的实证。WatchBridge 和 PairBack 只能解决测试环境中的**部署/配对**问题，不能当权限突破。

**优先级 3（独立门槛）：** 如未来第一个障碍真的解除，仍需检查 Hermès2025/Circulaire/Poodle 的**原生资格、添加流程和重启持久性**。

**暂停追逐 D 类方案：** 不把 iPhone 26 的越狱、旧 KFD/MDC、TrollStore、任意 iOS 恢复覆盖、Filza 文件浏览、root 于配对 iPhone 等同于 Ultra 1 的系统写入。尤其不能建议将未验证的覆盖程序直接作用于个人主力手表的 MG 缓存。

**最终判定：`BLOCKED / NOT UNLOCKED`。** 这是版本化的公开工具比较与源码研究，不是 watchOS 真机的新增成功实验，也不证明未来的所有攻击面都不可行。

## English research abstract

On November 14, 2026 I surveyed **37 publicly discoverable tools, repositories and distinct components** across watch-native projects, MCM/sandbox tooling, jailbreak/restore techniques, and deployment/firmware-analysis workflows. I cross-checked primary developer READMEs/releases and Apple security/compatibility information against my real **Watch6,18 / watchOS 26.6.1 / 23U95** baseline.

Newly recorded updates include **HermesEnabler 1.5.4**, **WQFiles 0.9.6**, **Erosion 0.3.1**, **WatchBridge** device-install tooling, **PairBack** watchOS 26 pairing evidence, and **Dopamine 3.x** iOS-only jailbreak support. These are meaningful distinct developments but **none demonstrates protected watchOS 26.6.1 SystemGroup write access**, let alone persistent native Hermès activation.

I performed **research and documentation only**; there was **no physical-watch connection, exploit execution, app build, protected-cache write or successful unlock**. My historical `EPERM` and native-face eligibility findings are unchanged. All 37 assessments and primary references are preserved in the tables above.
