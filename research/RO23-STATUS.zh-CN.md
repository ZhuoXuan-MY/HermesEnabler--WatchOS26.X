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
