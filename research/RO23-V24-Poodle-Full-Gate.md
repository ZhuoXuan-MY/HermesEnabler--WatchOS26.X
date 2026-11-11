# RO23 V24 — Complete NTKPoodleFace gate proved on 23U95

**Date:** 2026-11-11 · **Firmware:** Watch6,18 / watchOS 26.6.1 / `23U95` · **Target:** Hermès Circulaire / `com.apple.NTKPoodleFaceBundle` in shared `NTKZeusFaceBundle`.

**Finding:** For the **observed** Ultra 1 values `deviceCategory=4`, `collectionType=9`, `NTKShowHardwareSpecificFaces=false`, the full extracted `+[NTKPoodleFace isRestrictedForDevice:]` **evaluates restricted for both possible outcomes of its additional capability call**. This is complete **static path evaluation joined to live watch getters**, not a live call of the private Poodle class and **not an unlock**.


> **V25 correction (2026-11-11):** The unknown Poodle call `0x469C0` is **`-[CLKDevice supportsPDRCapability:]`**, proven by decoding the exact Zeus ObjC selector stub and references. Matching ClockKit at `0x49C6E724` returns **true** (`mov w0,#1; ret`), independently verified from original bytes. The result for measured Ultra 1 remains **RESTRICTED**. [See V25 source audit](RO23-V25-Poodle-Selector-ClockKit.md).

## Primary evidence

The device owner executed the V23 script directly against the already extracted `NTKZeusFaceBundle`. Original local binary SHA-256: `2b34d3d411b77ee73f3892638f419eda83b7bedc4653ecf44adf7c975bbd72e4`. The SHA-256 matched. LLVM path: `/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/llvm-objdump`.

I supplied **51,891 lines of console output**; the script's LLVM Mach-O `--start-address` / `--stop-address` did not effectively limit printed text. I filtered the actual instruction PCs locally: precisely **29 instructions at 0x13B4 through 0x1424** belong to the Poodle restriction implementation. The surrounding 0x12FC Hades and 0x1434 subsequent method instructions are *not part of this function*.

The original `+[NTKPoodleFace isRestrictedForDevice:]` entry at `0x13B4` was previously mapped to its Objective-C class method by checking original relative method lists (V14). Its instructions now establish the whole function:

```asm
0x13CC  bl   0x43B00                ; category getter (matched in V14)
0x13D0  cmp  w0, #1
0x13D4  b.eq 0x1404                ; category 1 -> restricted
0x13DC  mov  w2, #0xA3E7
0x13E0  movk w2, #0xD5DD, lsl #16  ; constant 0xD5DDA3E7
0x13E4  bl   0x469C0               ; unknown capability/eligibility predicate
0x13E8  cbz  w0, 0x1404           ; false -> restricted
0x13F0  bl   0x43480              ; collectionType getter
0x13F4  cmp  w0, #5
0x13F8  b.ne 0x141C
0x13FC  mov  w20, #0              ; collectionType 5 -> unrestricted on this method
0x1404  mov  w20, #1              ; restricted path
0x140C  mov  x0, x20              ; method's return register
0x1418  ret
0x141C  bl   0x340AC             ; NTKShowHardwareSpecificFaces
0x1420  eor  w20, w0, #1          ; !hardwareFaceFlag
0x1424  b    0x1408              ; return
```

The `0x469C0` call is a predicate shaped by the 32-bit immediate `0xD5DDA3E7`. **Its actual imported selector or implementation has not been independently resolved in this evidence.** Calling it a specific `supportsPDRCapability` method would be premature. Its unknown outcome **does not change the result for this my known category / collection / hardware-face values**.

## Reconstructed high-level behavior (read-only; explanatory pseudocode)

```c
bool PoodleIsRestricted(Device device) {
    if (device.deviceCategory == 1) return true;
    if (!CapabilityAt_0x469C0(device, 0xD5DDA3E7)) return true;
    if (device.collectionType == 5) return false;
    return !NTKShowHardwareSpecificFaces();
}
```

### Exhaustive outcomes for the measured Ultra 1

| Observed device / unknown predicate | Control flow | Return |
|---|---|---|
| `category=4`, `CapabilityAt_0x469C0(...)=false` | `0x13E8 → 0x1404` | **restricted = true** |
| `category=4`, capability predicate `true`, `collectionType=9`, hardware flag `false` | `0x13F8 → 0x141C → 0x1420` | **restricted = true** |

**Thus no earlier acceptance path remains inside this exact function** for the measured device values. This supersedes the V21/V22 statement that the complete early branch was unresolved, but it does **not** claim the native class was dynamically invoked by my app.

## Different layers and remaining work

- **Face file valid:** real user-provided `Hermès Circulaire(1).watchface` is valid ZIP, bundle id `com.apple.NTKPoodleFaceBundle`.
- **Firmware implementation present:** its class is in the shared `NTKZeusFaceBundle` in the matching 23U95 image.
- **Current diagnostic process:** V22 reported `NTKPoodleFace registered in this process=false`, which is unsurprising because that private FaceBundle was not loaded in that process; it does **not** overturn this static gate result.
- **Normal discovery/import:** V17 `NTKFaceBundleManager` checks `isRestrictedForDevice:` during normal enumeration/lookup; additional private exception predicate `0x55CE73DC` remains unresolved. The existence of the class/face file is **not** an import success.
- **System privileges:** no tested protected write on stock 23U95, no jailbreak proven, no native Hermès watchface installed.

### Script output correction

The existing `scripts/ro23-v21-poodle-disasm.sh` now **filters output from LLVM AND otool by actual instruction PC**, keeping only `0x13B4 <= PC < 0x1428`. This yields the **29 Poodle function instructions** rather than dumping ~52,000 lines. The correction is source-reviewed and a locally parsed user log confirmed 29 lines; **it has not yet been rerun on my Mac**. File SHA-256 guard and fallback to Xcode's tools remain. No new watch UI or projects.

**Next legitimate research:** identify the `0x469C0` selector for completeness and the `0x55CE73DC` restricted-face-manager exception, then separate supported face-selection APIs from internal/migration-only behavior. Avoid repeating the same watch probe or altering live paired-device identity.

[Original HermesEnabler](https://github.com/pookjw/HermesEnabler) · [V21](RO23-V21-Poodle-Gate-Mapping.md) · [V22 real watch report](RO23-V22-Poodle-Runtime-Gate.md) · [V17 registration checks](RO23-V17-FaceBundle-Loading-Chain.md)
