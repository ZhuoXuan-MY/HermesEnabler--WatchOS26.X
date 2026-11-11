# RO23 研究进度：Ultra 1 / watchOS 26.6.1（23U95）

**未完成，原生 Hermès 表盘尚未解锁。** 原作者：[Jinwoo Kim（@pookjw）](https://github.com/pookjw/HermesEnabler)。研究实机与 [Issue #17](https://github.com/pookjw/HermesEnabler/issues/17)：@ZhuoXuan-MY；部分代码和逆向由 AI 辅助分析。

- V1–V4：可读取 MG 缓存、但写入被 EPERM 拒绝。真正 DeviceBrand 槽位 103、值偏移 0x338、有效位 0x164F；早期 206/0x670 已判定错误。
- V5–V7：获取 Class-13 令牌并不意味着可写入，Helper XPC 查询返回错误 9。
- V8–V9：离线分析 23U95 对应原生固件及 ARM64_32 MobileGestalt，不对实机执行危险的缓存重建。
- V10–V12：找到了原生 Hermès 2025 FaceBundle 和 NanoTimeKit/ClockKit 准入检查代码。
- **V13 实机**：sizeClass=6、deviceCategory=4、collectionType=9、deviceBrand=0、isUltra=true。Hermès 2025 类别白名单 {2,3,5} 检查失败。
- **V14 实机**：isZeusBlack=false，NTKShowHardwareSpecificFaces=false，Zeus Analog、Spectrum 和 Hades/Secretariat 已研究门槛失败。
- V14.1：修正 deviceBrand 被误当成 int 导致 399803152 的读取错误。这不是品牌修改成功。

**新版 Xcode**：以原作者最新工程为基础，把 V13/V14.1/缓存快照放入独立只读诊断模块。23U95 无需 MG 备份就能进入研究页，且界面隐藏上游写入和重启控制。V1–V7 的历史实验源码保留于 research/legacy，**不参与编译**。

后续：Xcode 首次编译与真机验证、NanoTimeKit 其他合法准入路径研究。目前没有任何已验证的 Ultra 1 原生 Hermès 解锁方法。

[原作者项目](https://github.com/pookjw/HermesEnabler) · [上游研究 Issue #17](https://github.com/pookjw/HermesEnabler/issues/17)


## V14.2.1 真机验证完成／V15 静态研究（2026-11-11）

用户已通过 Xcode 在 Ultra 1／23U95 实际运行合并工程里的 V13、V14.1 和 MG 缓存只读诊断。结果稳定为 `deviceBrand=0`（`__NSCFNumber`）、`deviceCategory=4`、`collectionType=9`、`NTKShowHardwareSpecificFaces=false`。缓存再次验证索引 103／偏移 `0x338`／有效位 1。原生 Hermès 表盘**仍未解锁**，所有表盘判断仍为限制状态。

V15 对应 NanoTimeKit 静态反汇编已证明 `NTKShowHardwareSpecificFaces` 存在前置检查和 `ShowHardwareSpecificFaces` 配置键，但前置调用的实际身份未解析；**不能将配置键存在视为普通 Ultra 可开启该表盘的证据**。见 [V15 技术分析](RO23-V15-NanoTimeKit-Gate.md)。


## V16：明确内部构建版本前置条件（2026-11-11）

在 23U95 配套 NanoTimeKit 中，`_NTKInternalBuild`（`0x54601310`）直接跳到 `0x55CE731C`，而 `_NTKShowHardwareSpecificFaces`（`0x546014EC`）调用的也是**同一个目标**，返回零时立即跳到返回 `false` 的路径。这说明硬件专属表盘开关有内部构建版本的前置门槛。新增 **V16 · Internal-build gate** 只读按钮，读取 `NTKInternalBuild`、`NTKShowHardwareSpecificFaces`、`NTKShowInternalFaces`，不修改偏好设置、MG 或表盘。**V16 的真机数值还没有收到**，不能提前宣称结果。详见 [V16 报告](RO23-V16-InternalBuild-Gate.md)。


## V16.1：修正手表按钮入口

此前 V16 只显示在 Read-only diagnostics 二级页面，不在首页。已将 V16 · Internal-build gate 直接放在手表首页，并显示 RO23 V16.1 installed · read-only 版本标识和实际运行结果。此修改只涉及 UI，不修改 MobileGestalt 或安装表盘。用户需要从 GitHub 同步并在 Xcode 重新编译部署，旧版应用不会自动更新。


## V16.1 真机运行结果（2026-11-11）

用户已经在同一台 Ultra 1 / 23U95 上成功执行新按钮，获得真实日志：**`NTKInternalBuild=false`、`NTKShowHardwareSpecificFaces=false`、`NTKShowInternalFaces=false`**，`systemWrites=NO`。结合已核实的 `cbz` 分支，可确定本机内部版本检查未通过，并使硬件专属表盘显示谓词提前返回 false。**不能由此推论所有爱马仕表盘的全部路径均不可能**，但仅写 `ShowHardwareSpecificFaces` 偏好键没有已验证的作用。无需反复测试同样的三个返回值。见 [V16 真机证据](RO23-V16-InternalBuild-Gate.md)。


## RO23 V17：原生 FaceBundle 加载及加入表盘库的独立限制（2026-11-11）

对 23U95 匹配的 NanoTimeKit 反汇编确认：`NTKFaceBundleManager` 在**枚举表盘**、**根据 Bundle ID 查找**以及**按旧 Style 查找**时，均有 `isRestrictedForDevice:` 检查；而 `_NTKCanAddWatchFace` 还独立验证配置是否合法、设备能否使用该描述符、表盘类是否受限制。发现未解析的额外判断地址 `0x55CE73DC`，**不可与 V16 的 `0x55CE731C` 视为同一个函数**。系统内部 `forMigration:` 分支不能当作正常添加表盘的成功方案。此轮无需新增实机按钮、无需重新编译，也没有解锁原生 Hermès。详见 [V17 完整研究报告](RO23-V17-FaceBundle-Loading-Chain.md)。


## RO23 V18：系统级研究获授权，特殊判断仍待符号映射（2026-11-11）

设备所有者明确允许进一步评估其自有 Ultra 1 的越狱、系统级访问及写入可行性；但授权本身不会生成 Apple 私有 entitlement，也不代表聊天助手可以直接控制手表。离线反汇编再次确认，`0x55CE73DC` 只在两个 FaceBundle 查找路径中被直接调用，且都发生在 `isRestrictedForDevice:` 判断受限制之后。其真实函数名**尚未确认**；与 V16 的 `0x55CE731C` 不是同一地址。下一步使用 Mac 上已提取的完整 dyld cache 执行只读地址→符号映射，无需重新下载 OTA。没有实施越狱、系统写入或解锁。详见 [V18 研究报告](RO23-V18-Restricted-Face-Exception.md)。
