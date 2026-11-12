# 2026-11-12｜近期漏洞、Filza、MobileGestalt 工具与 watchOS 26.6.1 的兼容性核查

> **研究目标：** Apple Watch Ultra 第一代（`Watch6,18 / n199ap`），watchOS 26.6.1（`23U95`），寻找能**真实取得受保护 MobileGestalt SystemGroup 写入权限**的可验证工具或公开研究。  
> **证据截止：** 2026-11-12（北京时间 UTC+08:00），公开网页、开发者原始 README、GitHub 发布及源码静态比对。  
> **执行性质：** **仅公开资料和源码核查；没有连接手表、在真机运行工具、执行漏洞或修改系统缓存。**  
> **总体结论：** 尚无经过核实的 `Watch6,18 / 23U95` 可写方案；**最有研究价值的新线索是 WorstGestalt 的 `bad_query` Backend B，但只有 iOS 26 的公开支持声明，watchOS 移植未验证。** 旧项目状态继续 `BLOCKED / NOT UNLOCKED`。

## 一、逐一核查工具与版本

| 工具或资料（核查时版本） | 有证据的能力及日期 | 对目标 Ultra 1 / 23U95 的结论 |
|---|---|---|
| [WorstGestalt 1.0.0](https://github.com/GoldenNugget-Team/worstgestalt/releases/tag/v1.0.0)（11/10 发布） | 作者宣称**iOS 26.0–26.7.2** 通过 `bad_query` 的 Backend B 修改 iPhone/iPad MobileGestalt；还提供 `worse_query` Backend A | **唯一值得与原有代码进一步比较的线索**，但其成功声明与测试平台**不是 watchOS** |
| [Filza 5.0.1 beta build 3](https://www.tigisoftware.com/default/?p=439)（11/09 更新） | 官方提供 iPhone/iPad/iPod touch 的 plist、hex、SQLite 编辑器，改进受保护目录访问等；IPA 主要为 TrollStore/越狱使用 | 没有官方 watchOS 版本、跨设备写入能力或 23U95 成功测试。**不能用 iPhone Filza 替代手表端权限** |
| [WQFiles 0.9.3](https://github.com/kolbicz/WQFiles/releases/tag/v0.9.3)（11/12 北京时间 02:18 发布） | 新版启动时检查签名、App Group、文件夹及沙盒状态。开发者说明在 **iOS 26** 可以处理普通 App、daemon、App Group，**不能访问 System Data 与 SystemGroup**；iOS 27 能力不同 | 与原有 `worse_query` 的系统版本界限一致；**不是 watchOS 26 的 SystemGroup 解决方案** |
| [EscapeOS 0.3.2](https://github.com/pwnapplehat/EscapeOS/releases/tag/v0.3.2)（11/11 发布） | iPhoneOS 文件与普通 App Group 浏览，底层基于 `worse_query` | 不支持手表端 protected SystemGroup 写入 |
| [WatchRegion 0.4.0](https://github.com/LogicSense1/WatchRegion/releases/tag/v0.4.0)（11/10 发布） | 独立 watchOS 工具；发行说明 **watchOS 27.0+**；已报告实机成功的是 Ultra 4 / watchOS 27.3 beta，旧版和新版本增加销售地区自定义、回滚核验 | **没有适用于 Ultra 1/23U95 的成功报告**；不能直接移植未知缓存偏移 |
| [Erosion](https://github.com/jailbreakdotparty/Erosion)（截至 11/12） | 作者明确声明 iOS 26 的 `worse_query` 功能受限，**没有 MobileGestalt tweaks**；iOS 27 功能不同 | 与 WQFiles 结论互相印证；不代表 `bad_query` Backend B 一定也无效 |
| [worse_query](https://github.com/forcequitOS/worse_query)（截至 11/12） | 上游清楚标注 `/var/containers/Shared/SystemGroup/*` 访问只适用于 **iOS 27**；明确说不是 jailbreak | 不可从 iOS 26 的普通 App Group 可用推断 23U95 的 SystemGroup 可写 |
| [HermesEnabler 1.5.1](https://github.com/pookjw/HermesEnabler/releases/tag/1.5.1)（11/12 12:11 北京时间发布） | 最新发行说明只说改善 Ultra Face 布局选择、增加无法恢复原布局时的警告；原作者 README 仍注明 **watchOS 27.0 至 27.3 beta 1** | 本次没有新公告支持 **23U95**，也没有新的权限取得机制 |

## 二、为什么 WorstGestalt 与以前的研究不完全相同

我直接对比了 [WorstGestalt `Sources/WorseGestalt/BQCore.swift`](https://github.com/GoldenNugget-Team/worstgestalt/blob/main/Sources/WorseGestalt/BQCore.swift) 和本仓库现有 [`HermesEnabler2/BQCore.m`](../HermesEnabler2/BQCore.m)。

**确认有重叠：** 两边都使用 MCM `container_query`、Class 13 / `part_domain` 思路，也都使用普通 App Group/其他路径作为候选。之前我的 Ultra 1 测试曾在 Class 13 中**成功取得并激活沙盒令牌**，但 `file-write-data/create` 仍为 DENY，尝试打开受保护缓存的 `O_RDWR` 返回 `EPERM`。**“取得 token”不是“得到写权限”。**

**确认存在尚未在 Ultra 1 上验证的差异：**

- WorstGestalt 首先尝试一条专门针对**目标文件**的 `bad_query-file` 分支，然后再尝试一般 Class-13 遍历；本仓库当前 `BQCore.m` 有一般 Class-13 遍历，但**没有对应的同名、同顺序文件级访问分支**。
- WorstGestalt 的 Class-13 `part_domain` 查询参数与本仓库早期的值不同。它报告 iOS 26 可用，但这是否会改变 **watchOS 26.6.1** 的 token 范围、MCM 服务端行为和实际文件操作权限，**完全没有实机证据**。
- WorstGestalt 的实际写入仍要求先取得**可写的文件描述符**；缺乏写入权限时，换 `.plist` 编辑器、换 UI 或修改 DeviceBrand 偏移都不能弥补。

因此这是一条**可用于离线分析、对照底层实现的研究线索**，**不是可以直接安装到手表的工具，也不是已复现的 exploit**。若未来研究该路径，应先评估只读权限诊断与目标构建兼容性，**不可直接在真机上执行可能截断、覆盖或重建 MobileGestalt 缓存的实验代码**。

## 三、近期 watchOS 漏洞对 23U95 有没有帮助？

### Apple watchOS 26.6 安全公告（2026-07-27 发布）

在 [官方公告](https://support.apple.com/en-us/128068) 中，有些漏洞直接涉及越权：

- **`CVE-2026-43723` / MediaRemote**：Apple 表示恶意 App 可能获得 root 权限，属于路径处理问题；**已在 watchOS 26.6 修复**。
- **`CVE-2026-64747` / AVEVideoEncoder**：Apple 表示 App 可能以内核权限执行代码；**已在 watchOS 26.6 修复**。
- **`CVE-2026-28973` / libc**：可导致沙箱逃逸；**已在 watchOS 26.6 修复**。
- 另有内核内存损坏/内核写入等修复记录，但这些安全公告**不是可执行的漏洞 PoC，也没有公开证明能在已经修复的 23U95 上复现**。

### Apple watchOS 26.6.1 安全公告（2026-11-09 发布）

[官方 26.6.1 公告](https://support.apple.com/en-us/149723) 列出 AirPlay、Bluetooth、CoreUtils、rapportd 等**蓝牙、配对及邻近网络安全**修复（例如 `CVE-2026-113970` 蓝牙 UAF）。

这些漏洞是 **26.6.1 所修复**的内容，不代表该版本仍存在可利用的系统写入通路，也没有证据指向可用的 HermesEnabler / MobileGestalt 权限提升链。

### 公开越狱

[The Apple Wiki 的 26.x 兼容表](https://theapplewiki.com/wiki/Jailbreak/26.x) 对 watchOS 26.6.1 **未列出可用公开越狱工具**。这不意味着永远不可能出现新的工具或独立漏洞，但截止本次核查，**不能宣称已有可复现的 Ultra 1 / 23U95 root 或 SystemGroup writer**。

## 四、决定与后续研究优先级

1. **仅将 WorstGestalt 的 `bad_query` 文件级分支列为待验证研究线索**：先离线比对文件访问与权限模型，明确它与本仓库历史 Class-13 实验的区别；不开展不安全的直接写入。
2. **Filza 5.0.1、WQFiles 0.9.3、EscapeOS 0.3.2** 作为 iPhone 文件管理工具，不作为 Apple Watch SystemGroup 修复候选。
3. **WatchRegion 0.4.0、HermesEnabler 1.5.1** 留作 watchOS 27 工程参考，但不声称对 `23U95` 兼容。
4. Apple 已发布、被 watchOS 26.6/26.6.1 修复的 CVE 不能算新漏洞利用链，也不能推荐在无法恢复的日用手表上强行复现。
5. 另一个独立障碍仍在：即使未来可写入 MobileGestalt，也必须继续验证 **Hermès2025 / Circulaire-Poodle** 表盘的设备资格与正常添加流程。

**最终状态：`BLOCKED / NOT UNLOCKED`。没有 Xcode 编译、无 watchOS 真机漏洞运行、无受保护写入、无新的原生 Hermès 解锁结果。**

## Primary references

- [WorstGestalt 1.0.0 / README / BQCore](https://github.com/GoldenNugget-Team/worstgestalt)
- [Filza 5.0.1 developer notes](https://www.tigisoftware.com/default/?p=439)
- [WQFiles 0.9.3 release](https://github.com/kolbicz/WQFiles/releases/tag/v0.9.3)
- [EscapeOS 0.3.2 release](https://github.com/pwnapplehat/EscapeOS/releases/tag/v0.3.2)
- [WatchRegion 0.4.0 release](https://github.com/LogicSense1/WatchRegion/releases/tag/v0.4.0)
- [Erosion support statement](https://github.com/jailbreakdotparty/Erosion)
- [worse_query README](https://github.com/forcequitOS/worse_query)
- [HermesEnabler 1.5.1](https://github.com/pookjw/HermesEnabler/releases/tag/1.5.1)
- [watchOS 26.6 security update](https://support.apple.com/en-us/128068)
- [watchOS 26.6.1 security update](https://support.apple.com/en-us/149723)
- [The Apple Wiki / watchOS 26 jailbreak compatibility](https://theapplewiki.com/wiki/Jailbreak/26.x)
