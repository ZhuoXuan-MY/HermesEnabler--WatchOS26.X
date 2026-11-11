# RO23 V15 — Validated device diagnostics and NanoTimeKit hardware-face gate (23U95)

> **Status: NOT UNLOCKED.** This is an offline static analysis and a report of the device owner's read-only diagnostics, not a native face installation. Original HermesEnabler 2 © Jinwoo Kim (@pookjw); research logs supplied by @ZhuoXuan-MY.

## 1. Device owner evidence (2026-11-11)

First-generation Apple Watch Ultra, `Watch6,18` / `n199ap`, watchOS 26.6.1, build `23U95`. The owner compiled/ran the RO23 merged Xcode watch project and obtained all three reports. The tool did not directly operate the watch.

| Field | Actual log |
|---|---|
| sizeClass | 6 |
| deviceCategory | 4 |
| collectionType | 9 |
| deviceBrand | 0, Objective-C `__NSCFNumber` |
| isUltra | true |
| isZeusBlack | false |
| NTKShowHardwareSpecificFaces | false |
| Hermès 2025 allowed category set | {2,3,5}; calculated FAIL for category 4 |
| ZeusAnalog | calculated RESTRICTED for collectionType 9 + false hardware-face setting |
| SpectrumZeus | calculated RESTRICTED for observed properties |
| Hades / Secretariat category | calculated RESTRICTED |
| MobileGestalt plist | 13328 bytes |
| CacheUUID | `3BE19A76-F253-4CE4-AAC1-DF6D801CAAB1` |
| CacheData | 6309 bytes |
| DeviceBrand cache descriptor | index 103, value 0 at offset 0x338, presence byte 1 at offset 0x164F |
| Protected system writes | NO; app-owned diagnostic logs only |

These are property readings and branch evaluations; **they are not traces of face bundle loading or proof of all conditions in a face eligibility function**.

The V14 transient `deviceBrand=399803152` was a pointer-to-integer error. Corrected V14.1 reads `__NSCFNumber(0)`, matching V13 and the MobileGestalt cache value.

## 2. New static evidence: NTKShowHardwareSpecificFaces

Input: extracted `NanoTimeKit` Mach-O arm64_32 from the matching `23U95` dyld shared cache, 11,395,800 bytes, SHA-256:

`bf3f7e360fe06ab7e513807bcb3b6ac695f38c6ea8cd8428b7aed579c2b58e1c`.

`_NTKShowHardwareSpecificFaces` starts at VM address `0x546014DC`.

Relevant disassembly:

```asm
0x546014EC  bl   0x55CE731C      ; external call; symbol not resolved from extracted dylib
0x546014F0  cbz  w0, 0x546015A4 ; if precondition is false, return false
...
0x5460159C  ldrb w8, [x20, #0x2fd] ; cached decision
0x546015A0  b    0x546015A8
0x546015A4  mov  w8, #0
0x546015A8  and  w0, w8, #1
```

The function also has a cached setting / notification path. Its embedded CFString at VM `0x74A86FFC` points to the key `ShowHardwareSpecificFaces`. The CFString at `0x74A86FAC` points to the notification `NTKShowHardwareSpecificFacesChangedNotification`. An analogous `_NTKShowInternalWidgets` function invokes the same unresolved preliminary external routine, suggesting a shared internal-feature precondition but **not proving its exact identity**.

**Conclusion:** a configuration key exists, but its presence does not prove that ordinary watchOS devices can use it to enable faces. The preliminary gate may reject the operation before the setting is evaluated, and the owner's actual `NTKShowHardwareSpecificFaces=false` confirms the final result only, not which subcondition failed.

Do not write the setting speculatively, modify MobileGestalt, or call `MGRebuildCache` on the live watch to test this. This investigation does not supply any verified privilege escalation, system write method, or native Hermès unlock.

## 3. What changed in the RO23 project?

- Fixed Objective-C `Boolean` name conflict (`RO23ReadBool`) and removed placeholder App Group entitlement from the **read-only** signing profile (commit `ebc7693`).
- The user has now successfully run the combined V13, V14.1, and MG cache diagnostics on the watch. This resolves the previous "not compiled" uncertainty for this set of source changes, but does not verify other targets or other watches.
- No new on-watch test is justified by the current disassembly; the next step would be resolving the unidentified external shared-cache function and mapping the supported face-installation surface, without unverified writes.

Original: https://github.com/pookjw/HermesEnabler

Research: https://github.com/pookjw/HermesEnabler/issues/17
