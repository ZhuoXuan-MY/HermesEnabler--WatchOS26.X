# HermesEnabler · watchOS 26.x — V27 — 从普通资格检查转向 FaceBundleManager 特殊例外跳板

**日期：2026 年 11 月 11 日（北京时间 UTC+08:00）**  
**固件：Watch6,18 / watchOS 26.6.1（23U95）**  
**状态：仍未解锁原生 Hermès 表盘；不运行任何沙箱逃逸程序或修改系统文件。**

## 已有证据与新目标

V24/V25 已完整还原正常的 `NTKPoodleFace isRestrictedForDevice:` 函数。我希望不再重复该普通资格路径，因此 V27 专门检查 **NanoTimeKit 在受限表盘被报告为 restricted 后，额外调用的系统级谓词**。

来自已核对的 V17/V18 23U95 静态反汇编：

```asm
; FaceBundleManager: Bundle-ID lookup
0x544B0F94  bl  _objc_msgSend$isRestrictedForDevice:
0x544B0F98  cbz w0, 0x544B0FA4
0x544B0F9C  bl  0x55CE73DC  ; actual external target unresolved
0x544B0FA0  tbz w0, #0, 0x544B0FF0

; FaceBundleManager: legacy-style lookup
0x544B1164  bl  _objc_msgSend$isRestrictedForDevice:
0x544B1174  bl  0x55CE73DC
0x544B1178  cbz w0, 0x544B1188
```

另一个地址 `0x55CE731C` 与 V16 内部构建检查有关。两者相差 `0xC0`，但**相近地址绝不等于同一符号或同一授权策略**。此前我通过 `ipsw dyld a2s` 查这两个地址只得到了 `__TEXT_STUBS ?`。V27 故意不重复 `a2s`。

## 新增实际工具

`scripts/ro23-v27-exception-stub-trace.sh` 已针对我已有的 23U95 dyld shared cache 编写。它通过现有 `ipsw` CLI，对上述**两个地址分别**执行：

1. `ipsw dyld a2f` —— 获取函数所属信息；
2. `ipsw dyld a2o` —— 定位缓存映射与文件偏移；
3. `ipsw dyld disass --vaddr ... --count 12 --quiet` —— 只对目标地址读取有限指令。

每个命令最多显示 80 行，避免 V23 中出现过的巨量反汇编输出；若查询失败将报告退出码而不是虚构解码结果。

```bash
REPO="$HOME/Downloads/HermesEnabler-RO23-Live"
git -C "$REPO" fetch origin main
git -C "$REPO" show origin/main:scripts/ro23-v27-exception-stub-trace.sh | bash
```

不新建工程、不更改签名、不安装 watch App、不修改两台设备。注意 `ipsw` 可能生成其自身的本地分析索引，但**不会因此改写输入固件本体**。

**验证边界：** 命令参数已对照官方文档 [a2f](https://blacktop.github.io/ipsw/docs/cli/ipsw/dyld/a2f/)、[a2o](https://blacktop.github.io/ipsw/docs/cli/ipsw/dyld/a2o/) 和 [disass](https://blacktop.github.io/ipsw/docs/cli/ipsw/dyld/disass/)；**本脚本尚未在我的 Mac 上实际运行**，因此未声称已经解出 `0x55CE73DC` 的最终函数身份。

## 与 worse_query / WatchRegion 的关系

V26 已对照源码确认：`forcequitOS/worse_query` 的上游项目是 iPhone/iPad 的 iOS 沙箱研究 PoC；另一项目 `LogicSense1/WatchRegion` 确有 watchOS target，但其最低 watchOS 为 27.0、作者报告的测试环境与本机 Ultra 1 / 23U95 不同，并非目前已经验证的 watchOS 26 漏洞。它们与 NanoTimeKit 的**表盘授权谓词**也是不同问题。

上游的 App Group 符号链接过程会改动自身 `Library/Caches`，故**不能宣称运行沙箱 PoC 一定无副作用**。没有复制 GPL 源代码进继承 MIT 的 RO23 工程，也没有借助它进行系统写入。

## 下一步的证据门槛

如果 `ipsw` 可进一步解析 stub，下一次才可以根据真实调用指令和绑定表识别例外谓词。如果仍只显示 `?`，就必须深入绑定/间接符号数据，而不能根据地址位置猜测隐藏 API。即便存在特殊例外，`_NTKCanAddWatchFace` 与真正导入流程仍有独立检查。

**没有对这台 Ultra 1 实施 jailbreak、MobileGestalt 改写、系统组件替换或 Hermès 表盘安装。**
