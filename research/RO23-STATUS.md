# RO23 investigation: current evidence on Watch6,18 / 23U95

**NOT UNLOCKED.** Native Hermès faces are not activated on the user's stock Ultra 1.

Original app: [Jinwoo Kim / @pookjw](https://github.com/pookjw/HermesEnabler), MIT license. Field research and issue logs: [@ZhuoXuan-MY](https://github.com/pookjw/HermesEnabler/issues/17), with AI-assisted analysis.

| Stage | Confirmed observation |
|---|---|
| V1–V4 | Protected MobileGestalt cache readable; direct write-open denied EPERM. Correct DeviceBrand descriptor index 103, value offset 0x338, valid offset 0x164F. Prior 206/0x670 was wrong. |
| V5–V7 | Class-13 sandbox token did not grant protected writes. MobileGestaltHelper XPC queries returned error 9; do not equate this alone with entitlement denial. |
| V8–V9 | Matching 23U95 OTA, arm64_32 MobileGestaltHelper and libMobileGestalt analyzed offline. Do not call live MGRebuildCache. |
| V10–V12 | Native Hermes2025FaceBundle, NanoTimeKit, ClockKit found; bundle's category restriction studied. |
| V13 | Real Ultra 1 log: sizeClass 6, deviceCategory 4, collectionType 9, deviceBrand 0, isUltra true; Hermes2025 category whitelist {2,3,5} FAIL. |
| V14 | Real Ultra 1 log: isZeusBlack false and NTKShowHardwareSpecificFaces false; Zeus Analog/Spectrum and Hades/Secretariat studied gates RESTRICTED. |
| V14.1 | Fixed false number 399803152: deviceBrand was an ObjC object pointer, not an integer. |

All current active RO23 UI probes are **read-only**, manually invoked, and report to app-owned logs. No native face bundle was loaded or installed by these diagnostics. This is not a tested unlock.

**Current merged Xcode design:** the latest upstream code is the functional base; a separate RO23Diagnostics.m/.h and RO23ResearchView.swift hold the probes. On 23U95 the landing UI hides upstream feature-changing controls and allows the research screen without requiring MG backup. Older V1–V7 code is archived as text (not compiled).

Sources: [Issue #17](https://github.com/pookjw/HermesEnabler/issues/17), [Issue #7](https://github.com/pookjw/HermesEnabler/issues/7), V8/V9 reports and other notes in this folder.


## V14.2.1 on-device validation / V15 static follow-up (2026-11-11)

The device owner successfully ran the merged RO23 V13, V14.1 and MG cache read-only diagnostics under 23U95. `deviceBrand=0` was confirmed as `__NSCFNumber`, and cache layout index 103 / offset 0x338 / validity 1 was independently reported again. Observed gate outcomes remain RESTRICTED/FAIL; **no native Hermès unlock**. [Full V15 analysis](RO23-V15-NanoTimeKit-Gate.md).


## V16: identified internal-build precondition (2026-11-11)

On the matching 23U95 NanoTimeKit binary, `_NTKInternalBuild` at `0x54601310` branches directly to `0x55CE731C`; `_NTKShowHardwareSpecificFaces` at `0x546014EC` calls that **same target** and returns false when it returns zero. A new **V16 · Internal-build gate** button reads the exported `NTKInternalBuild`, `NTKShowHardwareSpecificFaces`, and `NTKShowInternalFaces` functions in the user's own process. It makes no protected writes or face changes. The actual watch-side V16 result is **not yet measured**. [V16 evidence](RO23-V16-InternalBuild-Gate.md).


## V16.1 device verification (2026-11-11)

The owner's Watch6,18/23U95 log now confirms **`NTKInternalBuild=false`, `NTKShowHardwareSpecificFaces=false`, and `NTKShowInternalFaces=false`**. This directly corroborates the disassembled precondition and excludes a simple preferences-only change as a demonstrated route. Three read-only predicate calls completed; no protected writes or face installations. [Actual V16 record](RO23-V16-InternalBuild-Gate.md).


## RO23 V17 — Native FaceBundle manager and add-to-library gates (2026-11-11)

Offline disassembly of matching NanoTimeKit confirms that `NTKFaceBundleManager` filters `isRestrictedForDevice:` both when **enumerating** bundles and when **looking up by bundle ID or legacy style**. Separately, `_NTKCanAddWatchFace` checks configuration validity, descriptor availability and the face class restriction before other library checks. An extra unresolved native predicate is called at `0x55CE73DC`; it is **not** the same address as the V16 internal-build call. The special `forMigration:` branch is not a demonstrated ordinary add flow. No watch-side test needed and no native Hermès unlock. [Complete V17 disassembly analysis](RO23-V17-FaceBundle-Loading-Chain.md).


## RO23 V18 — system-level methods now in scope, predicate still unresolved (2026-11-11)

With the device owner's explicit authorization, system-level read/write and jailbreak compatibility **may be researched**, but no privileges or remote watch access are acquired by that declaration. Local disassembly verifies two direct calls to `0x55CE73DC` after `isRestrictedForDevice:` rejects a face. The call remains unidentified; it is distinct from V16's `0x55CE731C`. Full symbol mapping requires the already-extracted Watch6,18/23U95 shared cache still on the owner's Mac. No watch writes or unlock performed. [V18 report](RO23-V18-Restricted-Face-Exception.md).


## RO23 V19 — iPhone/Watch pairing and Filza scope audit (2026-11-11)

Compared the user's Filza 27.2.2 release screenshot against the independent `forcequitOS/worse_query` access matrix, Apple ClockKit docs and forensic locations of iPhone-side `DeviceRegistry` / `NanoPreferencesSync` watch-face backups. iOS 26 app containers may be visible but **neither full Watch pairing state nor watchOS system access follows**. The exact Gitea Filza 27.2.2 source is currently inaccessible, so its implementation has **not** been audited. Proposed read-only per-container test without handling serial numbers, tokens or unrelated data; no Xcode code modifications or new test UI. [V19 report](RO23-V19-Filza-iPhone-Watch-Sync.md).


## RO23 V19.1 — Filza source reviewed and Bridge app data container verified (2026-11-11)

Audited the user's exact `filza27.2-v27.2.2.zip` (SHA-256 `2711ade73f7a383862b6fa0c451fddb69595f970441196cac2d58ebc6c7f7b41`). The user's iPhone Filza screenshots confirm `Watch [com.apple.Bridge]` application container listing, with `tmp`, `SystemData`, `Library`, and `Documents`. The nested `SystemData` is not root/system-group access. Source review reveals a WebDAV autostart configuration (default enabled when unset), unauthenticated HTTP when username unset, and optional SSH using fixed `alpine` credentials. Do not infer watchOS file write access or native Hermes unlock. [Full V19.1 audit](RO23-V19.1-Filza-Source-And-Bridge-Verification.md).
