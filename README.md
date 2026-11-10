# HermesEnabler RO23 — Apple Watch Ultra 1 / watchOS 26.6.1 Research Fork

**English** · [简体中文 (complete Chinese documentation)](README.zh-CN.md) · [Original HermesEnabler project](https://github.com/pookjw/HermesEnabler) · [Research Issue #17](https://github.com/pookjw/HermesEnabler/issues/17)

> [!IMPORTANT]
> **RESEARCH ONLY · NOT A WORKING UNLOCK · NO VERIFIED watchOS 26.6.1 SUPPORT.**
>
> This is an **unofficial, experimental derivative** of **[HermesEnabler / HermesEnabler 2](https://github.com/pookjw/HermesEnabler)**, originally developed by **Jinwoo Kim ([@pookjw](https://github.com/pookjw))**. The RO23 branch documents independently performed on-device experiments and offline firmware analysis by **[@ZhuoXuan-MY](https://github.com/ZhuoXuan-MY)**, with AI-assisted diagnostic code and technical reporting. On the tested Apple Watch Ultra (first generation), **the protected MobileGestalt cache was not modified and genuine Hermès watch faces were not unlocked**.
>
> **Historical warning (original local archive, identified November 11, 2026):** The supplied original modified archive contained a historical `BQWriteHermes23U95()` path in `HermesEnabler2/BQCore.m` that still hard-codes the **incorrect** `0x670`/`0x16B6` cache offsets. The corrected DeviceBrand offsets are `0x338`/`0x164F`. The old values refer to **another descriptor**. **That forced-write path is not present in the sanitized source accompanying this README; never reintroduce it as a working function or distribute an unverified IPA.** Replacing the offsets alone does not solve the sandbox or face-availability restrictions.

> **Public-source snapshot (11 November 2026):** The repository package accompanying this README is a **sanitized, system-cache-write-disabled research build**. The historical `BQWriteHermes23U95()` implementation, including its incorrect `0x670` offset, has been **removed from the distributed code**, and `BQSaveGestalt`, restore, and enable operations are blocked. Auto-running RO23 diagnostics were replaced by an opt-in button. The detailed sections below retain descriptions of the **original uploaded experimental snapshot** as research history. The app has **not been compiled or run on an Apple Watch from this package**; building requires your own signing settings.

## Contents

1. [Project overview](#1-project-overview)
2. [Original author, provenance, and contribution](#2-original-author-provenance-and-contribution)
3. [Device and support matrix](#3-device-and-support-matrix)
4. [What is actually modified in the local snapshot](#4-what-is-actually-modified-in-the-local-snapshot)
5. [Complete RO23 V1–V12 investigation](#5-complete-ro23-v1v12-investigation)
6. [DeviceBrand correction and cache format](#6-devicebrand-correction-and-cache-format)
7. [Why the MobileGestaltHelper XPC requests return error 9](#7-why-the-mobilegestalthelper-xpc-requests-return-error-9)
8. [Native Hermès 2025 face bundle and device restrictions](#8-native-hermès-2025-face-bundle-and-device-restrictions)
9. [RO23 V12: matching ClockKit evidence](#9-ro23-v12-matching-clockkit-evidence)
10. [Results and unresolved limitations](#10-results-and-unresolved-limitations)
11. [Source layout and building for research](#11-source-layout-and-building-for-research)
12. [Public release safety checklist](#12-public-release-safety-checklist)
13. [Reproducibility and binary provenance](#13-reproducibility-and-binary-provenance)
14. [Roadmap](#14-roadmap)
15. [License and acknowledgements](#15-license-and-acknowledgements)
16. [Research links and disclaimer](#16-research-links-and-disclaimer)

## 1. Project overview

**HermesEnabler RO23** is a research branch focused on understanding whether and why **native Apple Hermès watch faces** are restricted on a **first-generation Apple Watch Ultra** (`Watch6,18`, board `n199ap`) running **watchOS 26.6.1, build `23U95`**.

The project studies:

- How `MobileGestalt` provides and caches `DeviceBrand` on watchOS's `arm64_32` architecture.
- Why direct MobileGestalt reads succeed while writable access to its protected SystemGroup cache fails.
- What an MCM sandbox extension actually grants, compared with what a developer-signed process is still denied.
- How `com.apple.mobilegestalt.xpc` and `MobileGestaltHelper` process read-only questions.
- What native Hermès 2025 face components exist in the matching watchOS OTA.
- Where NanoTimeKit, ClockKit, and the Hermès 2025 FaceBundle implement device, capability, and availability restrictions.

The objective is **reproducible compatibility research**, not a claim that the code currently bypasses these restrictions. The existence of an Apple-supplied face bundle does **not** imply it can be installed, enabled, or used on an unsupported watch.

### What this is not

It is **not** an official release by the upstream author, Apple, or Hermès; not a jailbreak; not a confirmed entitlement bypass; not a replacement for the current upstream project; and not a distributable unlock tool for watchOS 26.6.1. No kernel exploit, remote access, cache rebuild, or successful modification of the watch's system cache is claimed.

## 2. Original author, provenance, and contribution

### Original software: Jinwoo Kim / @pookjw

**Full credit for the original application and upstream engineering belongs to [Jinwoo Kim (@pookjw)](https://github.com/pookjw).** The original project is [pookjw/HermesEnabler](https://github.com/pookjw/HermesEnabler), also known as **HermesEnabler 2**. Its existing Watch App implementation, MobileGestalt-related capabilities, interfaces, backup and restore infrastructure, and dependencies are the foundation of this derivative.

The upstream README, checked for this documentation, states that its supported range is **watchOS 27.0 to 27.3 beta 1**. That is an **upstream support statement**, not a support promise for this RO23 research branch.

The upstream repository is licensed under the **MIT License**, including **Copyright (c) 2026 Jinwoo Kim**. Preserve the original license and copyright notice when publishing derivative source. The original project also credits code from [Gester](https://github.com/sasobhabha/Gester); the local snapshot retains `Gester-LICENSE.txt`.

### RO23 research: @ZhuoXuan-MY

The RO23 investigation, local experimental modifications, data collection, and issue reports were conducted by **[@ZhuoXuan-MY](https://github.com/ZhuoXuan-MY)**, using their own Apple Watch Ultra and Mac/Xcode environment. The device owner installed local builds, ran tests on the watch, preserved logs, acquired matching firmware, and supplied the resulting binaries for offline static analysis. AI tools assisted with diagnostic scaffolding, shell commands, report drafting, and reverse-engineering interpretation. **AI-generated suggestions are not equivalent to successful on-device tests.**

The research trail is documented in [the original upstream Issue #17](https://github.com/pookjw/HermesEnabler/issues/17). The issue and reports distinguish on-watch observations, public third-party findings, offline static analysis, and remaining hypotheses.

### Why maintain an independent repository?

The RO23 code was developed against a watchOS build outside the upstream's currently advertised supported range. An independent repository allows detailed experimental findings to be shared while preserving upstream attribution and keeping **unsupported diagnostics** clearly separate from **working upstream functionality**. The project is **not endorsed by or affiliated with** the upstream maintainer.

## 3. Device and support matrix

| Property | Observed / documented value |
|---|---|
| Physical test device | Apple Watch Ultra, first generation |
| Machine identifier | `Watch6,18` |
| Board | `n199ap` |
| OS/build | watchOS `26.6.1` / `23U95` |
| Relevant ABI | `arm64_32` / ILP32 |
| On-device environment | Locally modified HermesEnabler2, Xcode development signing, custom App Group |
| `MobileGestalt` read | **Success** |
| MG cache backup and parsing | **Success** |
| MG protected cache write | **Denied: `EPERM`** |
| Class 13 sandbox token | **Obtained and consumed; write access remained denied** |
| MobileGestaltHelper XPC | **Connection and reply succeeded; tested questions returned `error=9`** |
| Native Hermès 2025 FaceBundle | **Found and extracted from matching firmware** |
| Face-specific availability checks | **Found in static analysis; runtime results unresolved** |
| Native Hermès activation on this Ultra | **Not achieved** |
| Tested working public IPA for 23U95 | **None** |

Findings are **build- and device-specific**. Other Apple Watch hardware and watchOS versions can have different descriptors, restrictions, entitlements, and resources. A method found in a Series 8 report or iOS decompilation is **not automatically proven on Ultra 1**.

## 4. What is actually modified in the local snapshot

The uploaded local archive `HermesEnabler(1).zip` was reviewed directly, including `HermesEnabler2/BQCore.m`, `BQCore.h`, `ContentView.swift`, entitlements, and Xcode project settings. It is an **experimental local snapshot**, containing both inherited upstream code and RO23 additions, not a cleaned or release-tested distribution.

| Area | Code or behavior found in this snapshot | Research interpretation |
|---|---|---|
| MCM and sandbox-extension infrastructure | Runtime symbol loading, container queries, token handling, optional fallback paths | Inherited/experimental mix; does not establish write privileges |
| MG backup and parsing | Reads MG plist and validates `CacheUUID`, `CacheData`, `CacheExtra` | Corresponds to confirmed device observations |
| `BQProbeClass7Flags23U95` | Three Class 7 flag configurations and restoration of temporary app-owned Caches state | All tested configurations failed to obtain usable tokens |
| Geod MCM test | `BQGeodOpen23U95` probes an alternative container route | Required object unavailable on tested build |
| Forced 23U95 writer | `BQWriteHermes23U95` validates/backs up before attempting a protected writable open | **Unsafe historic experiment; uses superseded offsets and must be disabled** |
| RO23 V1 | Read-only MobileGestalt key/reference and Mach-O cache candidate analysis | No system writes |
| RO23 V2 | Reads plain and hashed DeviceBrand via local `MGCopyAnswer` | No system writes |
| RO23 V3 | Descriptor stride, record boundary, and corrected index analysis | Corrects previous false association |
| RO23 V4 | Runtime entitlements, MCM Class 13, before/after `sandbox_check` | Token acquired, write permission not granted |
| RO23 V5 | Bootstrap lookup of `com.apple.mobilegestalt.xpc` | Mach service discovery only |
| RO23 V6 | Single read-only `DeviceBrand` Helper XPC query | `error=9` |
| RO23 V7 | Four read-only local-versus-XPC queries | Local values present; XPC returned only error 9 |
| UI diagnostics | Added compatibility, MG access and Class 7 reporting paths in `ContentView.swift` | Diagnostic UI does not mean activation is successful |

The snapshot also registers multiple `__attribute__((constructor))` callbacks, scheduling diagnostic steps after launch (about **3, 5, 7, 10, 13, and 26 seconds**). A public build should make research diagnostics opt-in and document their behavior explicitly.

**Critical code finding:** `BQWriteHermes23U95()` in the uploaded snapshot still contains `valueOffset=0x670` and `presentOffset=0x16B6`. Later RO23 V3 and V9 evidence **disproved these as DeviceBrand offsets**. Even though the watch denied `O_RDWR` in the recorded experiment, an unsafe pointer/offset must not be left in a public, potentially future-writable code path. Do not assume swapping in the corrected offsets would make the feature work.

## 5. Complete RO23 V1–V12 investigation

### Initial device trials: cache access and the first failed write

The locally modified Watch App launched, detected its own App Group, and successfully performed a direct read of the live MobileGestalt plist on `23U95`.

```text
Live plist size:       13,328 bytes
CacheUUID:             3BE19A76-F253-4CE4-AAC1-DF6D801CAAB1
CacheData length:      6,309 bytes (0x18A5)
CacheData slot count:  701, using 9 bytes per slot
CacheExtra entries:    72
Local DeviceBrand:     0
```

An older watchOS 26.5 backup was 13,329 bytes and had a different CacheUUID. It was **not** restored onto the `23U95` installation. A separate matching `OriginalGestalt-23U95.plist` backup was created and verified.

The first descriptor hypothesis incorrectly assigned `DeviceBrand` to **index 206**, value offset `0x670`, presence offset `0x16B6`. This is superseded. A special 23U95 write attempt reached the new code path and verified its backup, but the protected file could not be opened for writing:

```text
MG FORCE: entering 23U95 write path
MG FORCE: 23U95 backup verified
MG FORCE: WRITE DENIED errno=1 (Operation not permitted)
```

Therefore, the attempted write **never reached `pwrite`**. Geod-MCM Class 12 did not yield the required container object. Class 7 flags `0x0800000000`, `0x8000000000`, and `0x8100000000` each failed to return a usable sandbox token, and the diagnostic reported restoration of the temporary app-owned Caches structure.

### V1 — Read-only Mach-O and hashed-key examination

The research scanned mapped `libMobileGestalt.dylib` Mach-O sections in the on-watch `arm64_32` process, searching for the exact DeviceBrand hashed key (`fuKL2rMywRgQF1wowOA/cg`). Key and pointer references were found in string and data sections. However, an early interpretation erroneously read the **previous descriptor's tail** as if it belonged to the DeviceBrand record.

### V2 — Verify the local API and numeric type

The investigation used the correct two-argument `MGCopyAnswer(CFStringRef, CFDictionaryRef)` calling convention for both `DeviceBrand` and the hashed key. Both returned **CFNumber 0**. A Core Foundation numeric type and a MobileGestalt internal descriptor type are different enums and must not be confused.

### V3 — Correct the DeviceBrand descriptor boundary

The matching `arm64_32` MobileGestalt descriptor was examined with a **100-byte (`0x64`) record stride**. The DeviceBrand record's own metadata yields:

```text
flags = 12 (0x0C)
index = 103
type  = 5
value offset    = 103 * 8 = 0x338
validity offset = (701 * 8) + 103 = 0x164F
cached value = 0
validity = 1
```

The previously reported `flags=13, index=206, type=11` values came from the **preceding descriptor**, not DeviceBrand. The coincidence that `206 / 2 = 103` is not a data-format rule.

### V4 — Class 13 token is not writable access

A direct Class 13 MCM query using flags `0x0800000000` returned and consumed a sandbox extension (reported `handle=2` in this particular run). The on-watch `sandbox_check` calls still denied protected cache writing and creation both before and after consumption:

```text
MobileGestalt file-read-data     before=ALLOW  after=ALLOW
MobileGestalt file-write-data    before=DENY   after=DENY
MobileGestalt file-write-create  before=DENY   after=DENY
```

The development-signed process had the regular application-groups entitlement but not the queried private `com.apple.security.system-groups` or `com.apple.security.system-group-containers` entitlements. A separate metadata permission check returned `-1` (**an error, not a valid policy-denial result**). The V4 test made **no system writes**.

### V5 — Mach service lookup

`task_get_special_port` and `bootstrap_look_up` successfully resolved `com.apple.mobilegestalt.xpc` (`kr=0`; valid Mach right). A valid service lookup is not authorization to modify the system cache.

### V6 — Initial MobileGestaltHelper XPC query

The locally signed Watch App established an `NSXPCConnection`, invoked `getServerAnswerForQuestion:reply:` for `DeviceBrand`, and received a reply containing **`error=9` but no `answer`**. No cache-management function was called.

### V7 — Compare four local questions to XPC responses

| Question | Local `MGCopyAnswer` | Helper XPC reply |
|---|---|---|
| `DeviceBrand` | `CFNumber(0)` | `error=9`, no answer |
| `fuKL2rMywRgQF1wowOA/cg` | `CFNumber(0)` | Same |
| `BuildVersion` | String | Same |
| `ProductType` | String | Same |

All four reply dictionaries contained **only the `error` key** (no `answer` or `logString`). This error is not POSIX `EPERM`, a Mach bootstrap return code, or an MCM token error; these must be reported separately.

### V8 — Matching AEA OTA and native MobileGestaltHelper

The investigator downloaded the correct encrypted watchOS OTA, confirmed its metadata for `Watch6,18` / `n199ap` / `23U95`, inspected `post.bom`, and extracted `usr/libexec/MobileGestaltHelper` from `payload.054`.

The native Helper is **76,112 bytes, Mach-O `arm64_32`**. `ipsw macho info` recognized it, but its ObjC dump encountered an `__objc_protolist` EOF and its disassembler initially rejected the ABI. Using LLVM and direct Mach-O analysis, method implementations were recovered:

| Helper method | Address in analyzed binary |
|---|---:|
| `getServerAnswerForQuestion:reply:` | `0x5110` |
| `rebuildCache:` | `0x55F0` |
| `setCacheSentinel:` | `0x5714` |

At `0x51C4`, the Helper **actually calls** `_MGServerCopyAnswerWithError`. It constructs a reply containing `error` and optional `answer` / `logString` fields from the returned values. Neither cache rebuild nor sentinel operations were established as an arbitrary DeviceBrand setter. Cache rebuilding is **not a safe experiment** and was not invoked.

### V9 — Matching libMobileGestalt and error 9

The investigator extracted `libMobileGestalt.dylib` (**991,764 bytes**) from the matching `arm64_32` dyld shared cache, allowing direct code-level examination rather than inferring watchOS behavior from an unrelated iOS binary.

`_MGServerCopyAnswerWithError` was identified at `0x215B42A8` and the server-access check in the analyzed disassembly at `0x215B4BF4`. The function has explicit error-9 paths. Three plain-key descriptors had the following metadata:

| Question | Index | Internal type | Flags |
|---|---:|---:|---:|
| `DeviceBrand` | 103 | 5 | 12 (`0x0C`) |
| `BuildVersion` | 62 | 9 | 12 (`0x0C`) |
| `ProductType` | 530 | 9 | 12 (`0x0C`) |

These flags and access checks provide a **code-level explanation consistent with** the V7 results: questions available to the *local API* are not necessarily allowed through the *server-only Helper API*. This is **static reasoning**, not a complete dynamic trace of each V7 call. The matching library's DeviceBrand provider also refers to `IODeviceTree:/chosen` and its `marketing-software-behavior` property, a distinct input from the cached value.

### V10 — Native Hermès 2025 FaceBundle exists in the OTA

The OTA BOM and subsequent targeted extraction confirmed the following `Watch6,18`/`23U95` components:

| Native file | Approx. size | Role |
|---|---:|---|
| `NTKHermes2025FaceBundle.bundle/NTKHermes2025FaceBundle` | 1.2 MB | Hermès 2025 face implementation |
| Hermès `Assets.car` | 32 KB | Bundle assets |
| `Carousel.app/Carousel` | 185 KB | Watch face interface process |
| `ClockFace.app/ClockFace` | 406 KB | Face-related application |
| `NanoTimeKit.framework/nanotimekitd` | 734 KB | Face framework companion/service |

`nanotimekitd` contained `com.apple.Hermes2025Face`, references to `_NTKFaceStyleIsAvailable`, and logging strings resembling `Removing unavailable faces` and `Removing face of style %@`. The static call site at `0x8260` provided concrete evidence of a general face availability filter. **Firmware inclusion does not prove this device passes availability checks or has every resource needed at runtime.**

### V11 — NanoTimeKit and the Hermès-specific gate

The matching `NanoTimeKit` framework binary (**11,395,800 bytes**) was extracted from the dyld cache. Selected method addresses in the analyzed Mach-O were:

```text
_NTKFaceStyleIsAvailable                               0x544392B0
-[NTKFaceDescriptor isAvailableForDevice:]             0x543D998C
-[NTKFaceBundleManager faceBundleForBundleIdentifier:onDevice:forMigration:]
                                                        0x544B0DDC
```

Static analysis of the native Hermès bundle found `+[Hermes2025Face isRestrictedForDevice:]` at `0x3B2C` and related logic at `0x46B8`. The corresponding call sites include the selectors `deviceCategory`, `supportsFall2025FacesCapability`, and `collectionType`, with one `collectionType` comparison against `0x5`.

These are **additional restrictions beyond the general availability check**. The Ultra's actual runtime values for those selectors were **not measured**. We have not proved that `DeviceBrand=1` alone satisfies the Hermès 2025 checks, or that those checks are sufficient for end-to-end face activation.

### V12 — Matching ClockKit: device data and capability plumbing

The supplied `RO23-V12-ClockKit.zip` was directly unpacked and inspected for this README. The inner `ClockKit` is a valid **1,425,840-byte `arm64_32` Mach-O** (SHA-256 below). Symbols identify `CLKDevice`, its `_loadDeviceInfo` initializer/loader, NanoRegistry/PDR capability handling, and field accessors.

The following getter instructions were independently verified from the uploaded binary:

```asm
-[CLKDevice deviceBrand]      0x49C6F144: ldr  w0, [x0, #0x3c]
-[CLKDevice deviceCategory]   0x49C30EB4: ldr  w0, [x0, #0x2c]
-[CLKDevice collectionType]   0x49C354F0: ldr  w0, [x0, #0x30]
-[CLKDevice isUltra]          0x49C6F11C: ldrb w0, [x0, #0x17]
```

These are **instance-field accessors**, not the entire provenance of those fields or the Hermès restriction logic. `_queryAndCacheNanoRegistryDeviceCapabilities` invokes PDR-related capability processing. The string `supportsFall2025FacesCapability` was **not found as a direct definition in this ClockKit binary**; it may reside in another framework, a category, or the calling face bundle. The runtime values on this watch and the precise relationship of each capability to `DeviceBrand` remain unresolved.

**V12 is a successful extraction plus partial static analysis, not a completed capability override, privilege bypass, or Hermès face unlock.**

## 6. DeviceBrand correction and cache format

The DeviceBrand key has a hashed representation:

```text
DeviceBrand -> fuKL2rMywRgQF1wowOA/cg
```

The corrected metadata for this **specific** `23U95` environment is:

```text
CacheData bytes:         6309 = 701 * 9
Descriptor stride:       100 bytes in the observed arm64_32 layout
Descriptor flags:        12
Descriptor index:        103
Descriptor internal type: 5
Value offset:            0x338
Validity offset:         0x164F
Observed cached value:   0
Observed validity:       1
```

**Do not use `index=206`, `offset=0x670`, or `presentOffset=0x16B6` for DeviceBrand**. They were an earlier descriptor-boundary error. Both candidate slots happened to contain zero, so a matching numeric read alone was not enough to prove descriptor identity. Knowing the right slot does not provide write authorization, and write access would still not demonstrate face eligibility.

## 7. Why the MobileGestaltHelper XPC requests return error 9

```text
Local MGCopyAnswer(DeviceBrand)         -> CFNumber(0)
Helper getServerAnswerForQuestion(...)   -> { "error": 9 }
```

V8 confirmed that the Helper calls `_MGServerCopyAnswerWithError`; V9 located error-9 paths and server question handling in the **matching watchOS library**. The evaluated descriptors for DeviceBrand, BuildVersion, and ProductType share `flags=0x0C` and are not automatically valid requests for the Helper's server-only path. This explains why the four tested XPC questions could fail even though local MobileGestalt reads work.

The same code path does **not** grant arbitrary writes or establish that `rebuildCache:` can change DeviceBrand. The latter operation may affect the live cache and was deliberately **not** called. Exact runtime branches were not dynamically traced for every earlier V7 query.

## 8. Native Hermès 2025 face bundle and device restrictions

The matching OTA contains:

```text
System/Library/NanoTimeKit/FaceBundles/
  NTKHermes2025FaceBundle.bundle/
    NTKHermes2025FaceBundle
    Info.plist
    Assets.car
    hermes-*.plist (additional OTA resources)
System/Library/PrivateFrameworks/NanoTimeKit.framework/
  nanotimekitd
System/Library/CoreServices/Carousel.app/Carousel
Applications/ClockFace.app/ClockFace
```

The core question is no longer simply *“Is the bundle present?”* but *“Which checks let this hardware enumerate, load, add, and use the bundle?”* The current static model is:

```text
Face selection / catalog
     ↓
General NTK face style availability
     ↓
Face descriptor and bundle lookup
     ↓
Hermes2025Face isRestrictedForDevice:
     ↓
Device category / collection type / Fall 2025 capability
     ↓
Potential eligibility — NOT YET CONFIRMED ON ULTRA 1
```

This is a **research synthesis across observed static call sites**, not a fully instrumented end-to-end runtime trace. The identified checks may have further conditions. A native Apple bundle must not be copied into this repository: Apple's binaries and assets are not covered by the upstream MIT code license.

## 9. RO23 V12: matching ClockKit evidence

ClockKit adds information that matters when interpreting the V11 Hermès restrictions: a `CLKDevice` contains separate fields for `deviceBrand`, `deviceCategory`, `collectionType`, and `isUltra`. The getter instructions above establish these as distinct properties, **not** a single Boolean predicate.

The examined binary also includes device setup and PDR/NanoRegistry capability querying. It does **not** yet establish the runtime field values for `Watch6,18` or prove how `supportsFall2025FacesCapability` is derived. This is why the RO23 roadmap prioritizes **read-only runtime value verification** over modifying a cache field based on an assumption.

## 10. Results and unresolved limitations

| Investigation | Evidence | Result |
|---|---|---|
| MG direct read and compatible backup | Real watch logs | Success |
| DeviceBrand correction | On-device descriptor analysis + matching library | Index 103 strongly corroborated |
| Direct protected MG write-open | Real watch log | `EPERM`, no write |
| Class 7 MCM flags | Real watch logs | No usable token for three configurations |
| Geod-MCM | Real watch log | Required object not returned |
| Class 13 token consumption | Real watch logs | Successful token consumption, protected writes still denied |
| MobileGestaltHelper XPC request/reply | Real watch logs | Replied; error 9 for four questions |
| Helper's call into MobileGestalt | Matching firmware static analysis | Confirmed |
| Error-9 source and descriptor access check | Matching firmware static analysis | Code-level explanation, not individual dynamic traces |
| DeviceBrand provider | Matching library static analysis | `marketing-software-behavior` related |
| Hermès 2025 native bundle | OTA inventory and extracted binary | Present |
| General and Hermès-specific availability checks | V10/V11 native binaries | Static checks found |
| CLKDevice getter fields | V12 ClockKit native binary | Verified |
| Ultra 1's actual Fall 2025 capability value | Not yet recorded | Unknown |
| Hermès face activation or long-term use | No success evidence | **Not achieved** |

## 11. Source layout and building for research

The user-supplied local archive approximately contains:

```text
HermesEnabler/
├── HermesEnabler2.xcodeproj/          # Main research Watch App project
├── HermesEnabler2/
│   ├── BQCore.m                       # Upstream mechanisms plus RO23 changes
│   ├── BQCore.h
│   ├── ContentView.swift              # Research UI / diagnostic entry points
│   ├── HermesEnabler2App.swift
│   ├── HermesEnabler2.entitlements
│   ├── Gester-LICENSE.txt
│   └── BQCore.m.before-*              # Private iteration backups; do not publish
├── HermesEnabler.xcodeproj/           # Older project snapshot
├── HermesEnabler/                     # Older source tree
├── README.md
└── local .git metadata, build/person-specific files, historic backups
```

For **research development only**: use a Mac with an appropriate Xcode/watchOS SDK, open `HermesEnabler2.xcodeproj`, review every changed source file and configuration, configure **your own** signing team, Bundle ID and App Group, and test against an appropriate paired Apple Watch. The current local snapshot must **not** be compiled as a general 23U95 unlock tool before the unsafe writer is disabled and all automatic diagnostics have been reviewed.

A development signing identity or a normal App Group does **not** grant the Apple-private system-group entitlement or write permissions demonstrated absent in these tests. Upstream IPA installation instructions refer to the upstream project's supported versions and are **not** evidence of RO23 unlock support.

## 12. Public release safety checklist

> [!CAUTION]
> **Do not upload the supplied `HermesEnabler(1).zip` unchanged.** Direct inspection found an embedded `.git` history, multiple large source backups, personal signing/App Group identifiers, automatic research callbacks, and a wrong-offset forced-write code path. Publishing all of that is neither a clean fork nor a safe release.

- [ ] **Remove or unconditionally disable `BQWriteHermes23U95()` and any UI route calling it.** Merely swapping the old offsets for corrected ones is not a solution. The tested system still blocks writing, and face restrictions are independent.
- [ ] Review and make RO23 constructor-based diagnostics opt-in, clearly describing which read-only requests are made at launch.
- [ ] Replace local signing-team, Bundle ID and App Group configuration with your own **non-personal example values** or a setup guide; exclude certificates and provisioning profiles.
- [ ] Start from a clean source tree or use GitHub **Fork**; never upload the local `.git` directory or claim the upstream code as independently authored.
- [ ] Exclude historic `_历史备份` and `.before-*` files, `.class7-flag-probe-source-backup`, diagnostic logs, device identifiers, caches/backups, `DerivedData`, and unnecessary duplicates.
- [ ] Keep the upstream **MIT LICENSE**, including `Copyright (c) 2026 Jinwoo Kim`, and retain all relevant third-party notices such as `Gester-LICENSE.txt`.
- [ ] Do not redistribute Apple OTA/AEA files, extracted private frameworks, dyld caches, Hermès assets, code signatures, or Apple proprietary binaries as your own MIT-licensed repository assets.
- [ ] Audit the repository diff for hardcoded paths, personal identifiers, local secrets, and unintended state-changing code; verify a clean Xcode build after the safety work.
- [ ] Mark GitHub About, README, Issues, and Releases **Research-only / not working on watchOS 26.6.1**. Do not promise a native unlock or release a prebuilt 23U95 IPA without real successful validation.

See also [PUBLICATION_CHECKLIST.md](PUBLICATION_CHECKLIST.md) and [NOTICE.md](NOTICE.md) included with this documentation pack.

## 13. Reproducibility and binary provenance

Evidence is differentiated as follows:

- **On-device observation**: logs from the owner's real Ultra 1 while running the local modified Watch App.
- **Matching firmware static analysis**: OTA, Helper, `libMobileGestalt`, FaceBundle, NanoTimeKit, ClockKit files verified against the appropriate target/build where available.
- **Upstream/third-party material**: public projects or different Apple OS/hardware, explicitly **not equivalent to an Ultra 1 test**.
- **Inference**: interpretation of static control flow and incomplete availability restrictions; not represented as a working bypass.

Key research file hashes:

| Research input | SHA-256 |
|---|---|
| Downloaded Full OTA `.aea` | `8c04028c94a26eafc96e2dc50cf5c5296834ca30e0401b90fcf16d24d976c18b` |
| `MobileGestaltHelper` (V8) | `0e0c05244a3d35753e948783372f18e615ae2032cf7b750dd7a9cc57cfb3626e` |
| `libMobileGestalt.dylib` (V9) | `383dfd64b790ba505760bb4af7a08ed2df185cbf6fffca64a13608f9bdcc2baf` |
| `NanoTimeKit` (V11) | `bf3f7e360fe06ab7e513807bcb3b6ac695f38c6ea8cd8428b7aed579c2b58e1c` |
| `ClockKit` (V12) | `5fc1784de78830eb83808a5663c87bf2be39bca08453b5d11ddef4dcad56cce0` |

The Full OTA digest describes the investigator's **downloaded file**, not independent verification against a trusted Apple checksum. Tooling included [blacktop/ipsw](https://github.com/blacktop/ipsw), LLVM `llvm-objdump`, Xcode, Mach-O inspection, and local watch logs.

All memory addresses, XPC result pointers and call sites are **binary- and build-relative evidence**, not universal instructions for arbitrary devices. No live cache rebuild or successful protected-cache write occurred during V1–V12.

## 14. Roadmap

- [x] Read and preserve a build-matched 23U95 MG cache backup.
- [x] Correct the DeviceBrand record boundary and cached slot.
- [x] Separate MCM Class 13 token acquisition from actual sandbox write permissions.
- [x] Compare local MobileGestalt answers against Helper XPC responses.
- [x] Extract and reverse-engineer matching MobileGestaltHelper and libMobileGestalt binaries.
- [x] Find the Apple-supplied Hermès 2025 FaceBundle and general NanoTimeKit filtering logic.
- [x] Locate Hermès-specific `isRestrictedForDevice:` code and V12 CLKDevice accessors.
- [ ] **Safely refactor the public project to disable the erroneous 23U95 writer.**
- [ ] Locate the complete `supportsFall2025FacesCapability` implementation and dependency graph.
- [ ] Record, through read-only diagnostics, the watch's actual `deviceCategory`, `collectionType`, and applicable capability values.
- [ ] Distinguish catalog visibility, bundle eligibility, face addition and full runtime availability.
- [ ] Maintain an anonymized, reproducible research log and verify a clean Xcode build.
- [ ] Update activation status **only after a real watch successfully displays and adds genuine Hermès faces**.

## 15. License and acknowledgements

### Thank you, Jinwoo Kim (@pookjw)

Sincere thanks to **[Jinwoo Kim (@pookjw)](https://github.com/pookjw)** for developing and openly sharing **[HermesEnabler / HermesEnabler 2](https://github.com/pookjw/HermesEnabler)**. The upstream project's application structure and system research made the RO23 investigation possible. This derivative is intentionally attributed to the original author and does **not** imply endorsement.

### RO23 investigator and experimental modifications

**[@ZhuoXuan-MY](https://github.com/ZhuoXuan-MY)** carried out the on-watch tests, Xcode experiments, local source iterations, firmware acquisition and ongoing reporting in [Issue #17](https://github.com/pookjw/HermesEnabler/issues/17). AI-assisted suggestions and technical writing supported this work. The on-device results were generated on the owner's hardware, not on a simulated Apple Watch.

### Third-party and community contributors

- [Gester](https://github.com/sasobhabha/Gester) and its original contributors; upstream includes code from this project, so preserve `Gester-LICENSE.txt`.
- [forcequitOS/worse_query](https://github.com/forcequitOS/worse_query), [bad_query](https://github.com/forcequitOS/bad_query), and [0xjohnnydev/Geod-MCM-PoC](https://github.com/0xjohnnydev/Geod-MCM-PoC): public MCM research background, **not confirmed successful routes on this watch**.
- [PoomSmart/MGKeys](https://github.com/PoomSmart/MGKeys): mapping of obfuscated MobileGestalt keys.
- [blacktop/ipsw](https://github.com/blacktop/ipsw): OTA, dyld and Mach-O tooling.
- [EthanArbuckle's iOS 26.1 reverse engineering](https://github.com/EthanArbuckle/iPhone18-3_26.1_23B85_Restore): useful preliminary Helper/XPC background; the matching watchOS binaries were independently examined before drawing watch-specific conclusions.
- Other researchers in [HermesEnabler Issue #7](https://github.com/pookjw/HermesEnabler/issues/7), especially the independently reported Series 8 / `23U95` findings. Their device observations are **not** presented as Ultra 1 observations.

**License:** The original HermesEnabler project is **MIT licensed** and includes `Copyright (c) 2026 Jinwoo Kim`. Preserve the original copyright and permission notice in all derivative copies or substantial portions. This documentation pack provides an unmodified copy of the upstream `LICENSE` and a separate `NOTICE.md` describing the RO23 contributions. Rights to Apple's firmware and proprietary FaceBundles and to Hermès trademarks are **not** granted by that MIT license.

## 16. Research links and disclaimer

**Main documented research:** [HermesEnabler Issue #17](https://github.com/pookjw/HermesEnabler/issues/17)

- [Early on-watch findings and V1–V4 corrections](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6771229913)
- [V5–V7 Mach and XPC read-only tests](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6777128180)
- [Historical iOS 26.1 error-9 investigation](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6777139375)
- [V8 matching firmware and Helper analysis](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6777949079)
- [V9 matching libMobileGestalt analysis](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6778385658)

V10–V12 are summarized from the locally supplied firmware binaries and research session; they are **not described as already posted Issue #17 comments**.

This is an independent educational/research project. Use of private APIs and system modifications can cause crashes, data loss, broken installations, unsupported behavior, or service complications. **The supplied experimental build has never been shown to unlock genuine native Hermès watch faces on watchOS 26.6.1.** Do not execute unsafe legacy write paths or rebuild the live MobileGestalt cache. Public examples and logs should be anonymized before posting.

---

*Original project: HermesEnabler by Jinwoo Kim (@pookjw). RO23 experimental research: @ZhuoXuan-MY, with AI-assisted diagnostics and documentation. Not affiliated with or endorsed by Apple, Hermès, or the upstream author.*
