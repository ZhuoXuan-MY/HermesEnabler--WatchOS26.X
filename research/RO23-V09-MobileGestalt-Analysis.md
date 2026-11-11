libMobileGestalt 逆向研究报告
# HermesEnabler Issue #17 — RO23 V9
## Exact watchOS 26.6.1 / 23U95 libMobileGestalt reverse engineering: error 9, question descriptors, DeviceBrand provider

Date: 2026-11-11 (Malaysia, UTC+08)
Target: Apple Watch Ultra (1st generation), Watch6,18 / n199ap
System: watchOS 26.6.1, build 23U95
Issue: https://github.com/pookjw/HermesEnabler/issues/17
Follows: RO23 V5–V7 XPC tests and RO23 V8 MobileGestaltHelper binary analysis
Status: Host-only static investigation. No watch changes; no cache writes; no Hermès face activation.

## 中文摘要

本次 RO23 V9 已从初代 Apple Watch Ultra 对应的 23U95 Full OTA 中提取并独立解析真正的 arm64_32 `libMobileGestalt.dylib`。源 ZIP 由设备所有者在 Mac 上用 `ipsw ota extract --dyld --dyld-arch arm64_32` 和 `ipsw dyld extract` 制作并上传。独立 SHA-256 校验匹配。

最重要的发现：在原始 watchOS 库的 `_MGServerCopyAnswerWithError` 中，直接观察到设置 `error=9` 的指令（0x215B4590），并还原出服务端访问检查函数 0x215B4BF4。原生 `MobileGestaltHelper` 在启动时调用 `_MGSetServer`。`DeviceBrand`、`BuildVersion`、`ProductType` 三个描述符均为 flags=12（0x0C），bit 1 未设置，且服务端检查回调指针为空，因此按正常 Helper 服务端路径会被该检查拒绝并返回 `error=9`。与 V7 中三个名称及 DeviceBrand 哈希共四个 XPC 查询全部收到 `{"error":9}` 的现象一致。这不等于缺乏 entitlement 的直接证明，也不意味着 Helper 无法连接；关键区别是普通本地 MG 查询与服务器专用查询的访问规则不同。由于没有对每次 V7 请求做动态指令追踪，这里对“实际命中哪一分支”的判断来自确切描述符和匹配版本静态控制流，而非每次请求的运行时分支轨迹。

另外，已直接验证 DeviceBrand 的正确描述符：flags=12、index=103、type=5、值偏移 0x338、有效位偏移 0x164F。原先的 index 206、type 11 属于紧邻的上一条记录的尾部，这是 #17 既有修正的独立固件级复核。DeviceBrand 的 provider 位于 0x215CAAE0，读取 `IODeviceTree:/chosen` 中的 `marketing-software-behavior` 属性；属性数据长度至少 4 字节时，读取第 3 字节（offset 2），仅保留 1 或 2，否则用 0。该读取函数并不是写入或修改 DeviceBrand 的 setter。

全程仅分析 Mac 上的已提取系统库。之前在手表上得到 Class 13 token 但受保护缓存仍然拒绝写入的事实不变。没有执行 `_MGRebuildCache`、修改系统缓存、利用提权或解锁 Hermès 原生表盘。

---

## 1. Provenance and evidence levels

**DEVICE OWNER / MAC:** me downloaded the encrypted full OTA for `Watch6,18_N199AP_23U95`, verified its embedded metadata, extracted the ARM64_32 dyld cache family, and ran:

    ipsw dyld extract "$DSC" "/usr/lib/libMobileGestalt.dylib" --output "$ROOT/target"

my log confirms successful creation of `target/libMobileGestalt.dylib`. I then uploaded `libMobileGestalt-23U95.zip` to this conversation. AI-assisted analysis independently inspected the ZIP payload and performed offline ARM64_32 disassembly and descriptor parsing from its bytes.

**INDEPENDENT STATIC BINARY EVIDENCE:** Findings labeled as direct evidence below come from the actual submitted library image, not from an unrelated iOS source tree. The library is an `ipsw`-exported image reconstructed from the corresponding OTA dyld shared cache; this report does not claim a byte-for-byte dump from live watch process memory.

**EARLIER WATCH LOGS:** V4 and V5–V7 findings were collected by me on the watch, as previously documented in Issue #17. They are not repeated experiments in this V9 stage.

**OTHER SOURCES:** Public MGKeys mappings and independent Series 8 research are cross-checks only. The concrete V9 addresses and control-flow decisions below were recovered from the matching Watch6,18 / 23U95 library.

## 2. Input artifact verification

Uploaded ZIP member: `target/libMobileGestalt.dylib`
Uncompressed byte count: 991,764 bytes (~969 KiB)
SHA-256: `383dfd64b790ba505760bb4af7a08ed2df185cbf6fffca64a13608f9bdcc2baf`

This SHA-256 exactly matches my earlier Mac terminal output for the extracted file. The ZIP also contained a small macOS `._libMobileGestalt.dylib` AppleDouble sidecar; it is **not** the dynamic library and was excluded from analysis.

Mach-O:
- Format: Mach-O ARM64_32 / armv8 (ILP32 ABI)
- Type: dynamically linked library (`MH_DYLIB`)
- Install name: `/usr/lib/libMobileGestalt.dylib`
- Platform: watchOS
- Minimum OS and SDK: 26.6
- `LC_UUID`: `0A5FAD07-F08A-343C-88E4-121E27540393`
- Tool used for instruction decoding: LLVM 17 `llvm-objdump -d` (which accepts the ARM64_32 Mach-O in this environment)
- No live process instrumentation, watch execution, signing, or patching was performed.

The earlier `ipsw macho disass` frontend rejected this ABI; LLVM 17 successfully disassembled the file.

## 3. Critical exported symbols in this exact library

The Mach-O export trie identifies, among other symbols:

    _MGServerCopyAnswerWithError      0x215B42A8
    _MGServerQuestionIsPlatform       0x215C122C
    _MGWriteCacheOnHelper             0x215C1254
    _MGWriteCache                     0x215F4608
    _MGRebuildCache                   0x215F4F88
    _MGSetServer                      0x215BAA04

Note: When referring to the Objective-C helper's imported C functions, its Mach-O symbol table displays an extra leading underscore in some representations. These addresses are **image virtual addresses from this reconstructed library**, not portable file offsets, and must not be reused blindly on other builds.

## 4. MobileGestaltHelper enters server mode

The separately acquired, exact-match Ultra 1 `MobileGestaltHelper` executable (SHA-256 `0e0c05244a3d35753e948783372f18e615ae2032cf7b750dd7a9cc57cfb3626e`) includes the following startup call:

    Helper 0x00005CB8: BL ... ; symbol stub for __MGSetServer

The matching watchOS library implementation is only three instructions:

    0x215BAA04: ADRP X8, ...       ; address of server-mode state byte
    0x215BAA08: MOV  W9, #1
    0x215BAA0C: STRB W9, [X8,#0x184]
    0x215BAA10: RET

Therefore, the standard system Helper initializes the library's server-mode flag before accepting normal requests. This is different from calling a server-only function from an ordinary app process without that initialization.

## 5. Exact 23U95 `_MGServerCopyAnswerWithError` error conditions

Function entry: `0x215B42A8`.

The following branches were confirmed in the real binary:

A. **Not running in MobileGestalt server context**

    0x215B42E4: LDRB W8, [X8,#0x184]          ; server-mode byte
    0x215B42E8: TBZ  W8,#0,0x215B4378       ; false: reject

Related diagnostic string from this actual image:

    `_MGServerCopyAnswer(%@) called outside of server`

That branch ultimately initializes an empty result and error 9.

B. **Question not recognized by the descriptor lookup**

    0x215B4324: BL   0x215B2108              ; question descriptor lookup
    0x215B432C: CBZ  W24,0x215B43F4        ; unknown question
    ...
    0x215B447C: MOV  X21,#0                 ; no answer
    0x215B4480: MOV  W22,#5                 ; unknown -> error 5

Diagnostic string:

    `server asked to answer unknown question %@ for pid %d`

C. **Descriptor-based server access check fails**

    0x215B4330: ADD  X2,SP,#0xC             ; optional log/out
    0x215B4334: MOV  X0,X24                ; descriptor
    0x215B4338: MOV  X1,X22                ; caller context / pid
    0x215B433C: BL   0x215B4BF4            ; server access-check routine
    0x215B4340: TBZ  W0,#0,0x215B4488      ; if false, reject
    ...
    0x215B4488: ...                        ; denial logging
    ...
    0x215B458C: MOV  X21,#0                 ; no answer
    0x215B4590: MOV  W22,#9                 ; error 9
    ...
    0x215B4638: STR  W22,[X19]             ; write error to output pointer

Confirmed diagnostic string:

    `server_access_check denied access to question %@ for pid %d`

D. **Additional per-question callback rejection**

    0x215B4344: LDR  W8,[X24,#0xC]
    0x215B4348: CBZ  W8,0x215B435C
    0x215B4354: BLR  X8
    0x215B4358: TBZ  W0,#0,0x215B4504

The `0x215B4504` path logs:

    `server asked to answer non-server question %@ for pid %d`

and also joins the same error-9 setup. The tested descriptors below have this callback pointer equal to zero, so the descriptor-access-check route in C—not this extra callback route—is the relevant static explanation for those particular questions.

E. **Common error/result-return block**

    0x215B4594: LDR  W8,[SP,#0xC]           ; optional diagnostic value
    0x215B459C: STR  W8,[X20]             ; optional log output, if non-null
    0x215B4634: CBZ  W19,0x215B463C
    0x215B4638: STR  W22,[X19]            ; error output
    0x215B4654: MOV  X0,X21               ; return answer (0 if denied)
    0x215B466C: RET

The Helper's already-proven `getServerAnswerForQuestion:reply:` implementation stores the returned error into the XPC dictionary under `error`, and includes an `answer` only when a value exists. This explains the prior `{"error":9}` shape without assuming that an XPC transport failure occurred.

## 6. Server access-check function: disassembly and interpretation

Internal function start: `0x215B4BF4`, directly called at `0x215B433C`.

Its relevant server-mode path is:

    0x215B4C28: LDRB W8,[X8,#0x184]          ; server-mode state
    0x215B4C2C: TBNZ W8,#0,0x215B4D24       ; normal Helper path
    ...
    0x215B4D24: LDRB W8,[X19,#0x5C]        ; descriptor flags
    0x215B4D28: TBNZ W8,#1,0x215B4D44      ; server eligibility bit set -> allow
    0x215B4D2C: LDR  W8,[X19,#0x8]         ; descriptor access callback
    0x215B4D30: CBZ  W8,0x215B4DE4        ; no callback -> deny
    0x215B4D34: MOV  X0,X21
    0x215B4D38: MOV  X1,X20
    0x215B4D3C: BLR  X8                     ; callback when present
    ...
    0x215B4D44: MOV  W0,#1                 ; ALLOW
    0x215B4DE4: MOV  W0,#0                 ; DENY
    0x215B4DE8: ...                        ; function exit

There are additional branches for other kinds of descriptors and caller environments (including fields `+0x58` and flag bit `0x10`). Those paths should not be flattened into a claim that all access decisions are entitlement-only. Importantly, **the concrete descriptors below do not set bit 1, do not set bit 0x10, and have a null access callback at +0x8**. Thus in the normal Helper server-mode path these requests fail the descriptor gate without needing to infer a missing third-party entitlement.

## 7. Actual descriptor-table parse for V7 questions

The library's `__TEXT,__cstring` contains known obfuscated MobileGestalt hashes. Using a pointer-width-correct parser for ARM64_32 and the 100-byte descriptor records, I found the actual record for each of the three logical keys. Public name-to-hash mapping was cross-checked with `PoomSmart/MGKeys`:

- `DeviceBrand` -> `fuKL2rMywRgQF1wowOA/cg`
- `BuildVersion` -> `mZfUC7qo4pURNhyMHZ62RQ`
- `ProductType` -> `h9jDsbgj7xIVeIQ8S3/X3Q`

These records have the following metadata **in the source file**, not guessed from a different iOS build:

    Question      Desc file offset    Flags   Index   Type   AccessCB(+8)  ExtraCB(+0xC)
    --------------------------------------------------------------------------------------
    DeviceBrand   0x000944E0          0x000C  103     5      NULL          NULL
    BuildVersion  0x0009799C          0x000C  62      9      NULL          NULL
    ProductType   0x0009E698          0x000C  530     9      NULL          NULL

All are 100-byte records with their flag/index/type metadata in the descriptor tail at +0x5C:

    [descriptor + 0x5C]   uint16 flags
    [descriptor + 0x5E]   uint16 cache index
    [descriptor + 0x60]   uint32 internal type

The flags value 0x000C is binary `0000 1100`; the required **bit 1** is clear. Each record's access callback (`+0x8`) is zero. The library's ordinary/local `MGCopyAnswer` does not apply this server-only routing gate in the same way, consistent with V7's successful local queries.

The hashed DeviceBrand query and the plaintext `DeviceBrand` name resolve to the same logical key; there is no evidence that switching between the two representations alters the access rule.

**Important limitation:** V7 did not record instruction-level traces of individual requests. However, the real Helper enters server mode, the matching descriptors unambiguously fail the shown server-eligibility test, and the error-9 handling matches the live XPC replies. The matching-build static explanation is now strongly supported, but a complete live per-request path trace is not claimed.

## 8. Independent confirmation of corrected DeviceBrand index

The original Issue #17 body described index 206 / type 11 / value offset 0x670 as a *candidate*. The earlier detailed follow-up corrected this to index 103 / type 5 / value offset 0x338 after recognizing that the preceding eight bytes belonged to the **previous descriptor**.

The newly analyzed firmware bytes independently confirm that correction:

    DeviceBrand obfuscated-key string VM address: 0x2161C46E
    Descriptor key pointer file offset:         0x000944E0
    Provider callback:                         0x215CAAE0
    Own descriptor metadata at offset +0x5C:  0C 00 67 00 05 00 00 00
                                               flags 12, index 103, type 5

Preceding bytes at `0x000944D8` (the previous descriptor tail):

    0D 00 CE 00 0B 00 00 00
    flags 13 / index 206 / type 11

This resolves the misleading original index-206 association without assuming a hidden divide-by-two encoding. The presence of this adjacent record also explains why a naive scan of bytes just *before* the DeviceBrand string pointer produced a plausible but incorrect descriptor candidate.

Given the **previously observed 701 cache slots** on the live watch:

    DeviceBrand value offset    = 103 * 8 = 824   = 0x338
    DeviceBrand validity offset = 701 * 8 + 103    = 0x164F

Previous live observations found `CFNumber(0)` for the actual question and zero at the corrected cached slot. Nothing in V9 modified the file or revalidated a live write.

## 9. DeviceBrand source provider directly verified on 23U95

The DeviceBrand record points to a provider function at `0x215CAAE0`.

Key instructions:

    0x215CAAFC: ADRP X0,...
    0x215CAB00: ADD  X0,X0,#0xBEC        ; `IODeviceTree:/chosen`
    0x215CAB04: ADRP X1,...
    0x215CAB08: ADD  X1,X1,#0xF48        ; CFString `marketing-software-behavior`
    0x215CAB10: BL   0x215B2450        ; property-reading helper
    ...
    0x215CAB4C: CMP  W0,#4              ; require length >= 4
    0x215CAB50: B.LT ...                ; otherwise default path
    0x215CAB54: LDRB W8,[X20,#2]       ; byte at offset 2
    0x215CAB58: SUB  W9,W8,#1
    0x215CAB5C: CMP  W9,#2
    0x215CAB60: CSEL W8,W8,WZR,LO     ; keep 1 or 2, otherwise 0

The code constructs a numeric MobileGestalt result from that value (with a default zero-valued path). Thus the source of DeviceBrand is a DeviceTree property, not a user-controlled XPC argument or a generic preference key. This is a device/build-specific direct confirmation of the comparable result discussed by another researcher for Series 8 on build 23U95.

It is **not** evidence of a writable route to `IODeviceTree:/chosen` or a public API for changing this property.

## 10. `_MGServerQuestionIsPlatform` is not an authorization bypass

In this library:

    0x215C122C: _MGServerQuestionIsPlatform
    0x215C1238: BL  0x215B2108         ; descriptor lookup
    0x215C1240: LDRB W8,[X0,#0x5C]
    0x215C1244: TST  W8,#0x10
    0x215C1248: CSET W0,EQ

This helper reports a classification based on descriptor flag `0x10`; it does not edit a descriptor or grant access. For the tested 0x0C records, bit 0x10 is clear. That observation does **not** override the access-check denial for bit 1 at `0x215B4D28`.

## 11. Interpretation: what has and has not been proven

| Question | V9 conclusion |
|---|---|
| Does the exact 23U95 library contain `_MGServerCopyAnswerWithError`? | YES, virtual address 0x215B42A8 |
| Does it itself produce error code 9? | YES, explicit MOV W22,#9 at 0x215B4590 |
| Is error 9 *always* an entitlement failure? | NO; several paths lead to error 9 |
| Are the V7 keys unknown questions? | NO; all three logical keys have real descriptors |
| Is a normal Helper server-context call made? | Helper startup calls `_MGSetServer`; binary server mode confirmed |
| Can these descriptors pass the shown server bit-1 gate with null access callbacks? | NO; all are flags 0x0C and have no access callbacks |
| Does this explain V7's four `{"error":9}` responses? | YES, a directly supported matching-firmware static explanation |
| Has the individual dynamic branch of each V7 XPC request been traced? | NO; static explanation + previous replies, not live instruction tracing |
| Is DeviceBrand's correct cache index 103? | YES, directly corroborated from this library's record tail |
| Where does DeviceBrand obtain its value? | `IODeviceTree:/chosen` property `marketing-software-behavior` |
| Did V9 write the cache or execute a watch method? | NO |
| Did V9 unlock native Hermès watch faces? | NO |
| Did the previously denied system-group write permission change? | NO evidence of change |

This V9 result substantially resolves the *interpretation of error 9* but does **not** resolve the separate entitlement/sandbox barrier against modifying the protected MobileGestalt cache. Repeating V7 with different spellings of the same non-server question would not test a new capability.

## 12. Recommended next work (read-only)

A. Determine whether the HermesEnabler/Gester DeviceBrand change depends only on altering the cache, or also on further authorization / pairing state. Do not infer that read-only XPC access confers write permissions.

B. Further inspect the cache provider, DeviceTree source and Hermes-specific feature gates in the exact watchOS code (host-only static analysis). If looking for APIs, distinguish setters from cache rebuild/sentinel maintenance methods.

C. Validate any proposed new technique against **Watch6,18** and **23U95** specifically; source code or exploits for iOS 26.x or a different watch model are not equivalent evidence.

D. Keep the existing watchOS 23U95 backup. Do not use the older 26.5 backup for this build. Do not try `rebuildCache:` simply to test an interface—it may delete or regenerate the protected cache. Do not write unverified offsets and do not claim Hermès activation until observed on the watch.

## 13. Reproducibility commands (host-only)

Requires an already-extracted watchOS `libMobileGestalt.dylib`. No watch is needed.

    shasum -a 256 libMobileGestalt.dylib
    llvm-objdump --macho --exports-trie libMobileGestalt.dylib
    llvm-objdump -d --start-address=0x215B42A8 --stop-address=0x215B4674 libMobileGestalt.dylib
    llvm-objdump -d --start-address=0x215B4BF4 --stop-address=0x215B4E14 libMobileGestalt.dylib
    llvm-objdump -d --start-address=0x215BAA04 --stop-address=0x215BAA14 libMobileGestalt.dylib
    llvm-objdump -d --start-address=0x215CAAE0 --stop-address=0x215CABF0 libMobileGestalt.dylib

To reproduce the key-descriptor lookup with only Python's standard library:

```python
import struct
b = open('libMobileGestalt.dylib', 'rb').read()
keys = {
    'DeviceBrand':  'fuKL2rMywRgQF1wowOA/cg',
    'BuildVersion': 'mZfUC7qo4pURNhyMHZ62RQ',
    'ProductType':  'h9jDsbgj7xIVeIQ8S3/X3Q',
}
text_vm_base = 0x215B0000
for name, obfuscated in keys.items():
    offset = b.find(obfuscated.encode() + b'\0')
    assert offset >= 0, (name, 'missing hash')
    ptr = struct.pack('<I', text_vm_base + offset)
    # Bound the scan to this library's __DATA_CONST,__const range.
    matches = [i for i in range(558264, 804976, 4) if b[i:i+4] == ptr]
    for i in matches:
        flags, index, typ = struct.unpack_from('<HHI', b, i+0x5C)
        access_cb = struct.unpack_from('<I', b, i+0x8)[0]
        print(name, hex(i), 'flags=', flags, 'index=', index,
              'type=', typ, 'access_callback=', hex(access_cb))
```

Expected output (matched to this file):

    DeviceBrand  0x944e0 flags=12 index=103 type=5 access_callback=0x0
    BuildVersion 0x9799c flags=12 index=62  type=9 access_callback=0x0
    ProductType  0x9e698 flags=12 index=530 type=9 access_callback=0x0

The values are specific to this file and must not be used as universal offsets for another system version or architecture.

## 14. Related references

- Issue #17 (overall Ultra research): https://github.com/pookjw/HermesEnabler/issues/17
- Corrected DeviceBrand mapping and sandbox studies: https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6771229913
- RO23 V5–V7 on-device XPC diagnostics: https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6777128180
- Earlier iOS-only source analysis of error 9: https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6777139375
- Other device research, Series 8: https://github.com/pookjw/HermesEnabler/issues/7
- MobileGestalt key mapping: https://github.com/PoomSmart/MGKeys/blob/master/mapping-gestalt.h
- `ipsw` OTA / dyld extraction tooling: https://github.com/blacktop/ipsw

## 15. Maintainer-facing conclusion

The real Ultra 1 / watchOS 23U95 `libMobileGestalt.dylib` is now available for exact-build static analysis. `_MGServerCopyAnswerWithError` explicitly constructs error 9, and the internal server-access check refuses the tested ordinary question descriptors because their flags lack server bit 1 and their optional access callbacks are absent. The actual Helper initializes server mode, so the matching binary explains why earlier XPC requests returned `error=9` even when direct local `MGCopyAnswer` worked. The same binary independently verifies the corrected DeviceBrand cache descriptor and the underlying DeviceTree property provider.

This does not unlock native Hermès watch faces, provide an arbitrary DeviceBrand setter, or bypass the protected MobileGestalt SystemGroup write policy. The useful outcome is a reproducible, device-appropriate explanation for the previously unexplained RO23 V7 behavior without risking my watch.
