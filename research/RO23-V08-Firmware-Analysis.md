# HermesEnabler · watchOS 26.x — V8 — Ultra 1 / 23U95 Full OTA Acquisition, Native MobileGestaltHelper Extraction, ARM64_32 Reversing, and Error-9 Call-Chain Findings

**Date:** 2026-11-11 (UTC+08:00)
**Issue:** https://github.com/pookjw/HermesEnabler/issues/17
**Previous on-device report (RO23 V5–V7):** https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6777128180
**Prior iOS-26.1 error-9 research:** https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6777139375
**Device:** Apple Watch Ultra (1st generation), `Watch6,18` / `n199ap`
**System:** watchOS `26.6.1`, build `23U95`
**Scope of this update:** Mac-side/offline analysis of the matching Apple Watch Ultra 1 OTA and its original `MobileGestaltHelper` executable. No further privileged actions were performed on the watch.
**Outcome:** A genuine, build-matched `MobileGestaltHelper` was extracted, its cryptographic hash checked, its Objective-C implementation addresses recovered, and the actual call from `getServerAnswerForQuestion:reply:` to `_MGServerCopyAnswerWithError` was verified in ARM64_32 machine code. The Helper forwards the lower-level error into the XPC `error` reply field. The internal `libMobileGestalt` reason for error 9 is still unverified on watchOS 23U95. Native Hermès activation remains unsuccessful.

---

## 中文摘要（主体报告为英文，可直接作为 Issue #17 的新评论）

继 #17 中已经完成的 DeviceBrand 缓存定位纠正（`index=103`, `type=5`, `valueOffset=0x338`, `validOffset=0x164F`）、Class 13 令牌实验，以及 RO23 V5–V7 的 XPC 测试之后，本次研究不再对手表进行反复调用，而是转为**直接分析原版 Watch6,18 / watchOS 26.6.1 / 23U95 系统固件**。

设备所有者在自己的 Mac 上下载了约 3.5 GiB 的完整 `.aea` OTA。使用 `ipsw 3.1.737` 和匹配的 AEA 解密密钥成功读取 OTA 元数据；设备匹配 `Apple Watch Ultra / Watch6,18_N199AP_23U95`。OTA 资源和 `post.bom` 文件列表明确包含 `usr/libexec/MobileGestaltHelper` 以及多个 `arm64_32` dyld shared cache 分片。通过定向提取，仅从 `payload.054` 得到真正的 **76,112 字节** Helper 二进制，避免了全量解包。

原始 Helper 的 SHA-256 为 `0e0c05244a3d35753e948783372f18e615ae2032cf7b750dd7a9cc57cfb3626e`；报告编制时已对上传 ZIP 内的原文件再次计算并确认一致。该文件为 `Mach-O EXECUTE arm64_32_v8`，watchOS MinOS/SDK 均为 26.6。原生方法 `getServerAnswerForQuestion:reply:` 的 IMP 为 `0x5110`，其代码在 `0x51C4` 明确调用 `_MGServerCopyAnswerWithError`。从调用参数和回复对象构建逻辑可验证：**客户端收到的数字 `error` 由下层 MobileGestalt 调用输出，Helper 将其封装到 XPC 字典中，并非 Helper 内硬编码 `9`。** 但这不等于已找到 libMobileGestalt 返回 9 的确切条件。

另外，Helper 的 Apple 代码签名包含 `com.apple.private.security.storage.MobileGestaltCache=true` 和私有 `com.apple.security.system-groups`（含 `systemgroup.com.apple.mobilegestaltcache`）。与先前普通开发者签名的 HermesEnabler2 程序缺少这些私有权限的实机日志形成对比。`rebuildCache:` 与 `setCacheSentinel:` 均不是任意设置 DeviceBrand 的接口，未在手表上调用。

**进展与限制必须分开：真实固件提取与 Helper 调用链已经证实；`libMobileGestalt.dylib` 内部错误 9 分支尚未针对 Ultra 1 的 23U95 反汇编；没有获得写入系统缓存的权限；没有解锁原生 Hermès 表盘。**

---

## 1. Why this investigation changed direction

Prior work on this same watch established two independent observations:

1. The correctly parsed `DeviceBrand` cache descriptor has been strongly identified as index `103`, type `5`, value offset `0x338`, and validity offset `0x164F`. The much earlier index `206` / type `11` / offset `0x670` was a descriptor-boundary parsing error and is **superseded**, not a second valid mapping.
2. MobileGestalt cache write attempts remain blocked. A direct `O_RDWR` open returned `EPERM`. An MCM Class 13 query with flags `0x0800000000` returned an extension and `sandbox_extension_consume` succeeded (handle `2`), but protected-cache `file-write-data` and `file-write-create` remained denied. The normally signed application possessed an ordinary App Group entitlement, not the tested private system-group entitlements.

RO23 V5–V7 subsequently demonstrated that the normally development-signed watch app could locate `com.apple.mobilegestalt.xpc`, construct an `NSXPCConnection`, and receive a reply from `getServerAnswerForQuestion:reply:`. Nevertheless, four distinct questions all produced a dictionary containing only `error=9`:

| Question | Local `MGCopyAnswer` on the watch | MobileGestaltHelper XPC |
|---|---|---|
| `DeviceBrand` | NSNumber `0` | `{ "error": 9 }` |
| `fuKL2rMywRgQF1wowOA/cg` (hashed DeviceBrand) | NSNumber `0` | `{ "error": 9 }` |
| `BuildVersion` | String returned | `{ "error": 9 }` |
| `ProductType` | String returned | `{ "error": 9 }` |

No `answer` or `logString` key was present in the XPC responses. This is an application-level MobileGestalt error, not Mach bootstrap status, MCM extension-consumption status, or the `EPERM` from earlier write attempts.

A public reverse-engineered **iOS 26.1** implementation suggested multiple paths to error 9 (such as invalid server context, access checks, and questions not designated for server processing), but that is *not* a substitute for the actual watchOS 23U95 implementation. This V8 investigation therefore obtained and examined native firmware rather than repeating the same XPC questions or unsafe cache methods.

## 2. Source provenance and evidence levels

This report distinguishes:

- **MY MAC OUTPUT:** `ipsw` CLI output supplied by me after running commands on their own Mac.
- **BUILD-MATCHED BINARY:** the 76,112-byte `MobileGestaltHelper` extracted from `Watch6,18 / 23U95`, supplied as a ZIP and independently SHA-256 checked during analysis.
- **DIRECT MACHINE-CODE FINDING:** executable instructions or metadata actually read from this binary.
- **OTHER-BUILD REFERENCE:** iOS 26.1 `libMobileGestalt` and other-watch investigations, clearly distinguished from the Ultra 1 binary.
- **INFERENCE / OPEN QUESTION:** claims which remain to be tested or cannot be proved from the Helper executable alone.

I performed the downloads and extractions on macOS. The AI-assisted analysis did not remotely control my Mac or Apple Watch, did not execute the Helper on the watch, and did not access or rewrite the live MobileGestalt cache in this stage.

## 3. Host tooling and the exact firmware archive

I confirmed these properties:

```text
File: 596a9cab7fd039cffd431b392185c4cc2b355afe56aa743b27f18b9dd54e33c0.aea
Size: 3,758,096,384 bytes (3.50 GiB)
macOS `file` result: data
ipsw: Version 3.1.737, BuildCommit: Homebrew
Initial free disk space: approximately 17 GiB
```

The generic `file: data` output is not evidence of corruption: the source is an encrypted Apple AEA archive. An initial interactive-shell issue was also encountered (`zsh: command not found: #` when pasted comment lines were interpreted as commands); setting `setopt interactivecomments` addressed that command-entry problem, unrelated to the firmware.

I used the AEA key obtained for this OTA with `ipsw ota info --key-val ...` and successfully read metadata. The following is the observed output, abridged only to relevant fields:

```text
[OTA Info]
Version        = 26.6.1
BuildVersion   = 23U95
OS Type        = PreRelease
FileSystem     = 141-53318-006.dmg
RestoreRamDisk = [arm64_32SURamDisk.dmg]
RestoreVersion = 23.21.95.0.0,0

Devices
Apple Watch Ultra
  > Watch6,18_N199AP_23U95
    - TimeStamp: 04 Nov 2026 03:30:21 PST
    - KernelCache: kernelcache.release.watch6d
    - CPU: S6/S7/S8 (ARMv8.4-A), ID: t8301
    - BootLoaders: iBEC.n199.RELEASE.im4p,
                   iBoot.n199.RELEASE.im4p,
                   iBSS.n199.RELEASE.im4p,
                   LLB.n199.RELEASE.im4p,
                   sep-firmware.n199.RELEASE.im4p
```

Note: `OS Type = PreRelease` is the literal OTA metadata field; this report does not extrapolate an unrelated release-channel conclusion from it.

The Mac's SHA-256 of the AEA archive was:

```text
8c04028c94a26eafc96e2dc50cf5c5296834ca30e0401b90fcf16d24d976c18b
```

This digest was calculated locally. It has **not** been independently compared against an Apple-published expected hash and must not be described as external checksum verification. Successful `ipsw ota info` parsing and correct build/device identifiers establish a usable archive and metadata match, not a comprehensive proof of every contained payload's integrity.

Firmware catalog used in the earlier investigation: https://cpeoples.github.io/signet/watch/watch6-18/ . The original AEA is retained on my Mac; the firmware has not been reflashed or installed onto the watch during this analysis.

## 4. The OTA inventory located the target artifacts

I ran the `ipsw ota ls` inventory commands, saving their outputs locally:

```sh
ipsw ota ls --key-val "$KEY" "$FW" > "$ROOT/ota-assets.txt"
ipsw ota ls --bom --key-val "$KEY" "$FW" > "$ROOT/ota-bom.txt"
```

Resulting inventory text files:

```text
ota-assets.txt   19 KB
ota-bom.txt      55 MB
```

The OTA asset listing included `AssetData/payloadv2/payload.000`, `.001`, and many subsequent numbered payloads, plus `payload.bom`, `payloadv2.bom`, kernel/boot assets, and disk image metadata.

The `post.bom` inventory confirmed important targets:

```text
usr/libexec/MobileGestaltHelper                         76 kB
System/Library/LaunchDaemons/com.apple.mobilegestalt.xpc.plist 424 B
System/Library/Caches/com.apple.dyld/dyld_shared_cache_arm64_32
System/Library/Caches/com.apple.dyld/dyld_shared_cache_arm64_32.01
...
System/Library/Caches/com.apple.dyld/dyld_shared_cache_arm64_32.31.dyldlinkedit
System/Library/Caches/com.apple.dyld/dyld_shared_cache_arm64_32.symbols
System/DriverKit/System/Library/dyld/dyld_shared_cache_arm64_32
```

The system cache is a **multi-file family** with numbered segments and auxiliary/linkedit/symbol files, not a single small dylib. Listed examples included individual approximately 100–116 MB data segments, an approximately 256 MB `.31.dyldlinkedit` segment, and an approximately 458 MB `.symbols` file. Such inventory sizes explain why attempting a complete extraction on a nearly full Mac would be unnecessary and risky.

The `post.bom` is an inventory/manifest, not proof that every file is independently materialized as an unmodified standalone OTA asset. The subsequent `payload.054` extraction provided direct confirmation for the Helper specifically.

## 5. Targeted extraction of the build-matched Helper

Instead of extracting the full OTA or the entire dyld cache, me used the targeted `ipsw` regex extraction path:

```sh
FW="$HOME/Downloads/596a9cab7fd039cffd431b392185c4cc2b355afe56aa743b27f18b9dd54e33c0.aea"
OUT="$HOME/Downloads/RO23-23U95-Static/Helper"
mkdir -p "$OUT"
ipsw ota extract "$FW" \
  --key-val "$KEY" \
  --pattern '^usr/libexec/MobileGestaltHelper$' \
  --confirm \
  --output "$OUT"
```

The `--confirm` flag here tells the **host-side** `ipsw` tool to proceed with the optional payload scan. It does not authorize an on-watch action or change any system permission. Relevant owner output:

```text
Extracting Files Matching Pattern pattern=^usr/libexec/MobileGestaltHelper$
Found 'MobileGestaltHelper' in post.bom (most likely in payloadv2 files)
Searching for '^usr/libexec/MobileGestaltHelper$' in OTA payload files
Extracting from 'payload.054' -> 76 kB
  .../Helper/23U95__Watch6,18/usr/libexec/MobileGestaltHelper
提取命令执行成功
```

The resulting executable was approximately 74 KiB on disk. It was packaged with `ditto -c -k --keepParent` into an approximately 11 KB ZIP for analysis. The small ZIP size results from compression and is not evidence of a truncated original file.

Exact raw executable properties:

```text
Name:   MobileGestaltHelper
Size:   76,112 bytes
Type:   Mach-O executable arm64_32_v8
SHA256: 0e0c05244a3d35753e948783372f18e615ae2032cf7b750dd7a9cc57cfb3626e
UUID:   9C92827B-594D-3731-9A6C-AF6E75886171
```

The SHA-256 was computed once by me after extraction, again before ZIP upload, and independently checked on the decompressed upload; all results matched. This verifies that analysis used the exact supplied extracted executable. The ZIP contained the original executable and a small AppleDouble resource-fork metadata entry; the latter was not used for code analysis.

## 6. Mach-O build information and dependencies

`ipsw macho info` successfully parsed the build-matched executable as follows:

```text
Magic:             32-bit MachO
Type:              EXECUTE
CPU:               ARM64_32, v8
Commands:          24
Flags:             NoUndefs, DyldLink, TwoLevel, PIE
LC_BUILD_VERSION:  Platform: watchOS, MinOS: 26.6, SDK: 26.6
LC_SOURCE_VERSION: 1484.120.3.0.0
LC_UUID:           9C92827B-594D-3731-9A6C-AF6E75886171
LC_LOAD_DYLIB:     /usr/lib/libMobileGestalt.dylib
```

The binary also links Foundation, IOKit, CoreFoundation, libobjc, libSystem, and weakly QuartzCore. The native symbol imports include:

```text
_MGCopyAnswer
__MGCacheValid
__MGGetFastPathLog
__MGRebuildCache
__MGServerCopyAnswerWithError
__MGServerQuestionIsPlatform
__MGSetServer
__MGWriteCache
```

Important Mach-O symbol naming detail: names printed in the import symbol table contain their leading Mach-O underscore. Thus `__MGServerCopyAnswerWithError` in the symbol listing corresponds to the API/function conventionally written `_MGServerCopyAnswerWithError`; likewise `__MGRebuildCache` represents `_MGRebuildCache`.

Import-table presence alone establishes a dependency. The direct `BL` instruction at `0x51C4` discussed below establishes the actual Helper call site, which is stronger evidence.

## 7. Why two first-pass tools failed (and what actually worked)

I initially generated three static-analysis files with `ipsw macho info` and `ipsw macho disass`:

| Output | Actual result | Interpretation |
|---|---|---|
| `helper-symbols.txt` | Success | Contains direct imported symbols listed above. |
| `helper-objc.txt` | `failed to dump objc data: failed to read __DATA_CONST.__objc_protolist pointers: unexpected EOF` | The installed `ipsw` Objective-C decoder failed on this ARM64_32 image's metadata. It does **not** prove the executable is corrupt. |
| `helper-disassembly.txt` | `can only disassemble arm64 binaries` | The CLI's architecture guard did not accept the `arm64_32_v8` subtype in that path. It does **not** prove ARM64_32 instructions are undecodable. |

The original extracted executable was then analyzed directly using **LLVM 17 `llvm-objdump --macho --disassemble`**, which successfully decoded the `__TEXT.__text` ARM64_32 instructions. `llvm-objdump --macho --objc-meta-data` also gave lower-level ObjC section data, but did not by itself fully reconstruct all methods. Method addresses were recovered separately by manually interpreting the compact relative Objective-C method-list entries and selector references.

Reproducible host-side (read-only) example:

```sh
llvm-objdump --macho --disassemble MobileGestaltHelper > helper-disassembly-llvm.txt
llvm-objdump --macho --objc-meta-data MobileGestaltHelper > helper-objc-llvm.txt
```

No dynamic instrumentation of the watch, cache writes, or execution of extracted watchOS code was required for this recovery.

## 8. Recovered Objective-C method implementation addresses

The method list in the native Mach-O image yielded these method-to-implementation mappings (VM addresses **within the unslid executable image**, not universal exploit offsets or watch runtime addresses):

| Objective-C selector / method | Build-matched IMP VM address |
|---|---|
| `listener:shouldAcceptNewConnection:` | `0x4BBC` |
| `processNameForConnection:` | `0x4C3C` |
| `getSpringboardRegionOverride:reply:` | `0x4E78` |
| **`getServerAnswerForQuestion:reply:`** | **`0x5110`** |
| `getAppleTVMode:` | `0x545C` |
| **`rebuildCache:`** | **`0x55F0`** |
| **`setCacheSentinel:`** | **`0x5714`** |
| `queryBootUUID` | `0x5844` |
| `getSentinelPath` | `0x5978` |
| `setCacheSentinel` | `0x598C` |
| `needsNewCachePostBoot` | `0x5A7C` |

These addresses are tied to this exact 76,112-byte build and must not be copied as functional offsets for another firmware, device, or shared-cache library. The corresponding protocol's required methods are also present as protocol metadata; they are not additional implementation addresses.

## 9. Main finding: the real XPC query calls `_MGServerCopyAnswerWithError`

Inside the genuine `getServerAnswerForQuestion:reply:` implementation at `0x5110`, LLVM recovered the following instruction sequence:

```asm
0x5184  STR  XZR, [SP, #0x8]              ; initialize an output slot (32-bit pointer target)
...
0x51B4  ADD  X2, SP, #0xC              ; address of integer error output slot
0x51B8  ADD  X3, SP, #0x8              ; address of optional log output slot
0x51BC  MOV  X0, X22                   ; connection/context object
0x51C0  MOV  X1, X19                   ; requested question
0x51C4  BL   0x62CC                    ; stub: __MGServerCopyAnswerWithError
0x51C8  MOV  X24, X0                    ; answer return value
0x51CC  MOV  X0, X19
0x51D0  BL   0x62D8                    ; stub: __MGServerQuestionIsPlatform
```

This directly proves that the Helper has an XPC request path which passes the connection/context and question to the library's server-answer routine, receiving a returned answer and output parameters including an integer error and optional logging data.

`_MGServerQuestionIsPlatform` is called **after** the answer routine. In this Helper, its nearby use is associated with optional logging; there is no evidence in the corresponding Helper instructions that this method itself hardcodes an error-9 rejection for the tested questions.

### 9.1 Reply dictionary construction

Subsequent instructions show the error field being read from the stack and converted into a value object:

```asm
0x52E8  LDR  W2, [SP, #0xC]            ; get returned error
0x52EC  BL   0x6760                    ; ObjC NSNumber construction stub
...
0x5304  MOV  X0, X23                   ; mutable dictionary
0x5308  MOV  X2, X25                   ; NSNumber containing error
0x530C  BL   0x68E0                    ; setObject:forKey: style call
...
0x5314  CBZ  W24, 0x532C               ; omit answer if null
0x5328  BL   0x68E0                    ; insert returned answer
0x532C  LDR  W2, [SP, #0x8]           ; optional log pointer on arm64_32
0x5330  CBZ  W2, 0x534C               ; omit logString if null
0x5340  BL   0x68E0                    ; insert logString
0x534C  LDR  W8, [X20, #0xC]          ; reply block invoke pointer
0x5358  BLR  X8                        ; send response dictionary
```

The CFString constants referenced by the insertions resolve to:

- `error` — constant-string address `0x81F8`, underlying text `0x6D99`
- `answer` — constant-string address `0x8208`, underlying text `0x6D9F`
- `logString` — constant-string address `0x8218`, underlying text `0x6DA6`

The following equivalent pseudocode summarizes the observable function-level behavior. It is **not** leaked Apple source code, not an exact source reconstruction, and omits logging and lifetime-management details:

```objc
int mgError = 0;
CFStringRef optionalLog = NULL;
id context = [NSXPCConnection currentConnection];

id answer = _MGServerCopyAnswerWithError(
    context, question, &mgError, &optionalLog);

NSMutableDictionary *response = [NSMutableDictionary dictionary];
response[@"error"] = @(mgError);
if (answer != nil)     response[@"answer"] = answer;
if (optionalLog != nil) response[@"logString"] = (id)optionalLog;
reply(response);
```

### 9.2 Precise implication for RO23 V7's `error=9`

The earlier V7 reply shape — only `error`, no `answer`, no `logString` — matches the observed Helper reply construction when the library produces a nonzero error and null optional outputs.

**Direct finding:** The Helper forwards the integer error produced through `_MGServerCopyAnswerWithError` rather than visibly assigning the literal value 9 itself in this XPC query method.

**Not yet established:** Why the 23U95 `libMobileGestalt.dylib` returns 9 for those four questions. The library could reject the question routing, the server context, authorization, or another condition. This exact internal branch has not yet been recovered from a matching watchOS library and must not be mislabeled as a proven entitlement failure.

**Not a write method:** This XPC query is a read/answer path. Successfully contacting the Helper does not grant permission to edit its protected system-group cache.

## 10. Cache-management methods are not arbitrary DeviceBrand setters

The recovered native methods have these relevant operations:

### `rebuildCache:` — IMP `0x55F0`

The compiled method directly calls the imported `_MGRebuildCache` stub at `0x56B8`, then invokes the caller's reply callback with the resulting return value:

```asm
0x56B8  BL   0x62C0                   ; __MGRebuildCache
0x56BC  MOV  X1, X0                    ; result for reply
0x56C8  BLR  X8                        ; invoke reply block
```

This method has no argument representing a replacement `DeviceBrand` value. Its presence does **not** establish a safe or appropriate way to modify the Hermès feature flags. It was **not called** by these tests. The separate Series 8 / 23U95 findings in Issue #7 warn that rebuilding the cache can have destructive side effects; this is specifically why no exploratory on-watch rebuild was performed here.

### `setCacheSentinel:` — IMP `0x5714`

This method delegates to an internal `setCacheSentinel` implementation (at `0x598C`) and passes a boolean-like result to the reply callback. The `getSentinelPath` implementation is at `0x5978`. The internal path relates to a cache-rebuild sentinel (the `.rebuild` marker), not a generic key/value setter. No arbitrary DeviceBrand modification method was established.

### `_MGWriteCache` import

The executable imports `_MGWriteCache`, but the import alone does not imply that `setCacheSentinel:` provides a remote arbitrary write primitive or that the development-signed watch app can call it with privileged effect. Any claims about authorization and cache-writer behavior need to be based on the actual caller, service context, and matched library code.

## 11. Actual Apple-private entitlements in the native Helper

The extracted executable's embedded XML code-signature entitlements were independently parsed. They contain **16 entitlement keys**, including the relevant entries:

```xml
<key>com.apple.private.security.storage.MobileGestaltCache</key>
<true/>
<key>com.apple.security.system-groups</key>
<array>
    <string>systemgroup.com.apple.mobilegestaltcache</string>
    <string>systemgroup.com.apple.mobileactivationd</string>
</array>
```

This is binary-level evidence that Apple's system Helper is provisioned with private cache-storage and system-group permissions. It should be contrasted with earlier **on-device** RO23 V4 logs from the development-signed app:

```text
com.apple.security.application-groups present=1
com.apple.security.system-groups present=0
com.apple.security.system-group-containers present=0
```

The app's previously acquired Class 13 extension was successfully consumed, but its post-consumption sandbox checks still denied protected-cache writes. These observations are compatible with an authorization boundary between Apple's privileged Helper and a normally signed third-party app. They do not prove the full kernel decision tree or show that a particular entitlement alone would suffice on every system.

Do **not** infer from the Helper's entitlement list that a third-party developer-signing workflow can simply add these Apple-private permissions. No such permission acquisition was demonstrated.

## 12. Current blocker and what is still missing

| Question / step | Status | Source |
|---|---|---|
| Correct Ultra 1 / 23U95 DeviceBrand descriptor | Strongly identified: index 103, type 5, offsets 0x338 / 0x164F | Earlier Ultra tests in #17 |
| Local `MGCopyAnswer(DeviceBrand)` | Works, returns numeric 0 | RO23 V7 |
| Mac-side full OTA metadata match | Confirmed, Watch6,18_N199AP_23U95 | my `ipsw ota info` |
| Source archive AEA SHA-256 calculated | Yes; no independent expected-hash comparison | my `shasum` |
| OTA `post.bom` location of MobileGestaltHelper | Found | my `ipsw ota ls --bom` |
| Targeted native Helper extraction | Success, from `payload.054` | my `ipsw ota extract` |
| Native Helper binary SHA-256 consistency | Success, 76,112-byte executable | Owner and independent ZIP check |
| Objective-C query method location | Confirmed, IMP `0x5110` | Build-matched binary method list |
| Direct BL to `_MGServerCopyAnswerWithError` | Confirmed at `0x51C4` | Build-matched ARM64_32 code |
| Helper error/answer/logString forwarding | Confirmed in broad control flow | Build-matched ARM64_32 code |
| Actual reason for numeric error 9 inside watchOS library | **UNRESOLVED** | Matching `libMobileGestalt` not yet analyzed |
| User-app write to protected cache | **DENIED** | Earlier `EPERM`/sandbox checks |
| Generic XPC DeviceBrand setter identified | **NO** | Current Helper analysis |
| System cache rebuild performed in V8 | **NO** | Offline analysis only |
| Native Hermès watch faces activated | **NO** | No activation evidence |

A very important distinction: the Helper's code proves **who reports** the error to the app; it does **not** yet prove **which branch inside libMobileGestalt generates** the error.

## 13. Next technical stage: matching ARM64_32 shared-cache library

The next missing artifact is the actual watchOS 23U95 `/usr/lib/libMobileGestalt.dylib` image, expected in the corresponding `arm64_32` dyld shared-cache family. I have not acquired that library yet, and this report must not pretend that its watchOS internals have already been disassembled.

Planned, **not yet executed** on my Mac:

1. Recheck available disk space before extracting the multi-segment cache family. During the above experiments, free space declined from roughly 17 GiB, to 15 GiB after inventory, then approximately 14 GiB after Helper extraction.
2. Once me has adequate storage, use `ipsw ota extract` with `--dyld --dyld-arch arm64_32` and an explicit output directory, avoiding extraction of unrelated firmware content where possible.
3. Use `ipsw dyld extract <DSC> /usr/lib/libMobileGestalt.dylib --output <dir>` to export only the relevant library (if present in that family). Do not use `--all` for dylib exports.
4. Preserve source build identifiers, image UUID, extracted binary SHA-256, and dyld subcache companions; then statically trace `_MGServerCopyAnswerWithError`, `_MGServerQuestionIsPlatform`, server-context setup and question flags.
5. Compare the real 23U95 implementation against the published **iOS 26.1** source, taking care not to treat same-named functions as proof of identical branch conditions on different operating systems.
6. Determine whether RO23 V7's four questions are classified as non-server questions, whether connection/session checking is involved, or whether another verified check produces `9`. Do not label the result as entitlement denial until the relevant branch and context have been proven.
7. Keep experimentation read-only. Do not invoke `rebuildCache:`, write sentinel files, change cache bytes, or claim native Hermès enablement based only on access to a lookup service.

The following commands illustrate the **planned** host workflow, not completed work:

```sh
# Example only. Ensure sufficient available disk space FIRST.
ipsw ota extract "$FW" --key-val "$KEY" \
  --dyld --dyld-arch arm64_32 --confirm --output "$ROOT"

# After identifying the actual system DSC path:
ipsw dyld extract "$DSC" \
  /usr/lib/libMobileGestalt.dylib \
  --output "$ROOT/target"
```

Some `ipsw` extraction paths create temporary decrypted/staging files despite small final target size. Do not run full extraction on my nearly full Mac without an appropriate space margin.

## 14. Reproduction and research references

- Original HermesEnabler Issue #17: https://github.com/pookjw/HermesEnabler/issues/17
- Earlier detailed Ultra 1 / 23U95 research and DeviceBrand correction: https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6771229913
- RO23 V5–V7 XPC logs: https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6777128180
- Follow-up iOS 26.1 error-code research: https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6777139375
- Independent Series 8 / 23U95 research (different device): https://github.com/pookjw/HermesEnabler/issues/7
- OTA catalog for Watch6,18: https://cpeoples.github.io/signet/watch/watch6-18/
- blacktop/ipsw project: https://github.com/blacktop/ipsw
- OTA targeted-extraction CLI implementation: https://github.com/blacktop/ipsw/blob/master/cmd/ipsw/cmd/ota/ota_extract.go
- OTA list/BOM CLI implementation: https://github.com/blacktop/ipsw/blob/master/cmd/ipsw/cmd/ota/ota_ls.go
- OTA AEA opening logic: https://github.com/blacktop/ipsw/blob/master/pkg/ota/aa.go
- dyld image extraction CLI: https://github.com/blacktop/ipsw/blob/master/cmd/ipsw/cmd/dyld/dyld_extract.go
- Earlier **iOS 26.1** (not Watch6,18) reverse-engineered `libMobileGestalt`: https://github.com/EthanArbuckle/iPhone18-3_26.1_23B85_Restore/blob/main/usr/lib/libMobileGestalt/libMobileGestalt.mm

The executable itself is not embedded in this public issue text. The file hash, build UUID, extracted path, and relevant instructions are sufficient to identify the artifact without publishing an Apple copyrighted binary or disclosing my home-directory username.

## 15. Final status for the maintainer

**The match-specific binary analysis has now crossed a useful boundary:** I am no longer relying solely on guessed XPC interface behavior or a reverse-engineered iOS binary. On the tested Ultra 1 build, the actual Apple MobileGestaltHelper executable was located in the full OTA, extracted, and independently analyzed. Its native query implementation directly calls `_MGServerCopyAnswerWithError` and packages the returned error, answer and optional log into the XPC dictionary, accounting for the exact shape observed in RO23 V7.

**What this does not mean:** it is not a sandbox escape, a watchOS kernel exploit, a writable SystemGroup token, a verified explanation of the `libMobileGestalt` error-9 branch, or a method to turn on Hermès faces. The earlier `EPERM`/sandbox-write denial still stands. The current safest next research step is static examination of the matching `libMobileGestalt.dylib` from the actual watchOS 23U95 dyld cache.

I hope this build-matched evidence is useful for distinguishing Helper reply mechanics from the more difficult platform authorization and cache-editing questions. Thank the reader to @pookjw and everyone contributing reproducible watchOS research.
