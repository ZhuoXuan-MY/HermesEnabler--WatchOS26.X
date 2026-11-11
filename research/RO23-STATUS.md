# HermesEnabler · watchOS 26.x — Research status (Watch6,18 / 23U95)

**Official status: `BLOCKED` — native Hermès unlock unsuccessful on Watch6,18 / watchOS 26.6.1 (`23U95`)** (recorded 2026-11-11 23:43 Beijing Time). The current technique is blocked, **not** proven impossible in principle. Existing V0–V30 research, watch logs and source are retained. Historical “next steps” below are archival, not current instructions. See [README](../README.md) and [CHANGELOG](../CHANGELOG.md).

### Evidence behind BLOCKED

- my Watch6,18 / 23U95 protected MobileGestalt cache read succeeded, but `open(O_RDWR)` returned **`EPERM`**. Consuming a Class-13 sandbox extension did **not** grant protected file write/create permission. Geod-MCM and the tested Class-7 variants did not furnish writable access.
- Face eligibility is a second, independent blocker: real device `deviceCategory=4` fails the Hermès 2025 category whitelist, and the matched Circulaire/Poodle restriction function returns restricted with `collectionType=9` and `NTKShowHardwareSpecificFaces=false`. A hypothetical writable cache alone would **not** establish native face activation.
- Public `worse_query` SystemGroup support is documented for **iOS 27**, not demonstrated for this **watchOS 26** target; iPhone Filza/EscapeOS and ordinary App Groups do not grant remote watchOS SystemGroup write authority.
- The V27.2 branch identity `_CLKIsFaceSnapshotService` describes a face snapshot exception, **not an ordinary native face-unlock authorization**.

**Development is paused pending material new evidence.** Do not resume repeated read-only probes, speculative protected writes, or fake “force-enable” UI. Reopen only with (1) a reproducible **Watch6,18/23U95** authorized privileged write or equivalent route, (2) verified safe readback/persistence and (3) live native Hermès eligibility, addition and durable display. **Current milestones: 0/3.** This is a research archive, not a working unlock.

---

**NOT UNLOCKED.** Native Hermès faces are not activated on my stock Ultra 1.

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

me successfully ran the merged RO23 V13, V14.1 and MG cache read-only diagnostics under 23U95. `deviceBrand=0` was confirmed as `__NSCFNumber`, and cache layout index 103 / offset 0x338 / validity 1 was independently reported again. Observed gate outcomes remain RESTRICTED/FAIL; **no native Hermès unlock**. [Full V15 analysis](RO23-V15-NanoTimeKit-Gate.md).


## V16: identified internal-build precondition (2026-11-11)

On the matching 23U95 NanoTimeKit binary, `_NTKInternalBuild` at `0x54601310` branches directly to `0x55CE731C`; `_NTKShowHardwareSpecificFaces` at `0x546014EC` calls that **same target** and returns false when it returns zero. A new **V16 · Internal-build gate** button reads the exported `NTKInternalBuild`, `NTKShowHardwareSpecificFaces`, and `NTKShowInternalFaces` functions in my own process. It makes no protected writes or face changes. The actual watch-side V16 result is **not yet measured**. [V16 evidence](RO23-V16-InternalBuild-Gate.md).


## V16.1 device verification (2026-11-11)

my Watch6,18/23U95 log now confirms **`NTKInternalBuild=false`, `NTKShowHardwareSpecificFaces=false`, and `NTKShowInternalFaces=false`**. This directly corroborates the disassembled precondition and excludes a simple preferences-only change as a demonstrated route. Three read-only predicate calls completed; no protected writes or face installations. [Actual V16 record](RO23-V16-InternalBuild-Gate.md).


## V17 — Native FaceBundle manager and add-to-library gates (2026-11-11)

Offline disassembly of matching NanoTimeKit confirms that `NTKFaceBundleManager` filters `isRestrictedForDevice:` both when **enumerating** bundles and when **looking up by bundle ID or legacy style**. Separately, `_NTKCanAddWatchFace` checks configuration validity, descriptor availability and the face class restriction before other library checks. An extra unresolved native predicate is called at `0x55CE73DC`; it is **not** the same address as the V16 internal-build call. The special `forMigration:` branch is not a demonstrated ordinary add flow. No watch-side test needed and no native Hermès unlock. [Complete V17 disassembly analysis](RO23-V17-FaceBundle-Loading-Chain.md).


## V18 — system-level methods now in scope, predicate still unresolved (2026-11-11)

With my explicit authorization, system-level read/write and jailbreak compatibility **may be researched**, but no privileges or remote watch access are acquired by that declaration. Local disassembly verifies two direct calls to `0x55CE73DC` after `isRestrictedForDevice:` rejects a face. The call remains unidentified; it is distinct from V16's `0x55CE731C`. Full symbol mapping requires the already-extracted Watch6,18/23U95 shared cache still on my Mac. No watch writes or unlock performed. [V18 report](RO23-V18-Restricted-Face-Exception.md).


## V19 — iPhone/Watch pairing and Filza scope audit (2026-11-11)

Compared my Filza 27.2.2 release screenshot against the independent `forcequitOS/worse_query` access matrix, Apple ClockKit docs and forensic locations of iPhone-side `DeviceRegistry` / `NanoPreferencesSync` watch-face backups. iOS 26 app containers may be visible but **neither full Watch pairing state nor watchOS system access follows**. The exact Gitea Filza 27.2.2 source is currently inaccessible, so its implementation has **not** been audited. Proposed read-only per-container test without handling serial numbers, tokens or unrelated data; no Xcode code modifications or new test UI. [V19 report](RO23-V19-Filza-iPhone-Watch-Sync.md).


## V19.1 — Filza source reviewed and Bridge app data container verified (2026-11-11)

Audited my exact `filza27.2-v27.2.2.zip` (SHA-256 `2711ade73f7a383862b6fa0c451fddb69595f970441196cac2d58ebc6c7f7b41`). my iPhone Filza screenshots confirm `Watch [com.apple.Bridge]` application container listing, with `tmp`, `SystemData`, `Library`, and `Documents`. The nested `SystemData` is not root/system-group access. Source review reveals a WebDAV autostart configuration (default enabled when unset), unauthenticated HTTP when username unset, and optional SSH using fixed `alpine` credentials. Do not infer watchOS file write access or native Hermes unlock. [Full V19.1 audit](RO23-V19.1-Filza-Source-And-Bridge-Verification.md).


## V20 — watchface archive and import-result research (2026-11-11)

Verified FaceRead's actual .watchface JSON parser and Apple's public import error codes. Added **offline, read-only** `scripts/ro23-inspect-watchface.py` to inspect face identifiers and hashes without extracting images, touching system files, or modifying the watch. The real Hermès Circulaire file has only appeared as a Filza filename screenshot; **no file bytes yet, no known bundle ID, no unlock**. [V20 report](RO23-V20-Watchface-Archive-Import.md).


## V20.1 — real Hermès Circulaire archive decoded (2026-11-11)

I already uploaded the authentic 249,760-byte `Hermès Circulaire(1).watchface`. Direct ZIP/CRC and JSON checks passed (SHA-256 `d8364f574fbfcbf16a46d7ae07fbdf74267621a7f6ec2e7525e8018d2659fb03`). Actual identifiers are **`bundle id=com.apple.NTKPoodleFaceBundle`, `analytics id=poodle`, `face type=bundle`, `forMigration=false`**. The Poodle gate studied in V16 depends in part on collectionType 5 or the hardware-specific face flag, while my watch reports 9/false. Filza viewer decompression error did not indicate corruption of this verified copy. **No face installation or unlock**. Private complication JSON was not published. [V20.1 report](RO23-V20-Watchface-Archive-Import.md).


## V21 — Poodle-specific restrictions with actual Circulaire target (2026-11-11)

Cross-referenced the real `NTKPoodleFaceBundle` face.json against my original V14 Zeus firmware research and V16 disassembly. **Poodle's earlier known category-1 exclusion must not be conflated with Hermes2025's separate {2,3,5} whitelist**; me has category 4, which does not hit the single known Poodle category-1 test. But given collectionType=9 and NTKShowHardwareSpecificFaces=false, the previously disassembled Poodle fallback evaluates restricted **if that branch is reached**. Added a SHA-256-gated, read-only offline Poodle disassembly script to inspect the still-unknown early path from the already-extracted 23U95 binary. No new watch install or unlock. [V21 details](RO23-V21-Poodle-Gate-Mapping.md).


## V22.2 — V22 real watch result recorded (2026-11-11)

Device owner successfully ran V22 on first-gen Ultra / 23U95. The on-watch output confirms `deviceCategory=4`, `collectionType=9`, `NTKInternalBuild=false`, `NTKShowHardwareSpecificFaces=false`, `NTKPoodleFace registered in this process=false`. The Poodle conditional fallback reports RESTRICTED **as a static model**, but `NTKPoodleFace.isRestrictedForDevice` could not be called, since the class is not registered in the diagnostic process. This does **not** establish that the class is absent from watchOS or that native Hermès faces are available. Next: offline full early Poodle disassembly, **not** another same-value watch button. [Verbatim V22.2 log and analysis](RO23-V22-Poodle-Runtime-Gate.md).


## V24 — Full Poodle eligibility function reconstructed (2026-11-11)

my actual V23 Mac dump verifies the matching SHA-256 `2b34d3…` and supplies the entire 29-instruction Poodle function at `0x13B4–0x1424`. Its early test is `deviceCategory==1`; an unresolved capability call `0x469C0` with constant `0xD5DDA3E7` rejects on zero. If this call succeeds, the watch's `collectionType=9` and `NTKShowHardwareSpecificFaces=false` still force **restricted=true**. Therefore the **complete static function**, with the known on-watch values, rejects Poodle regardless of the unknown capability outcome; no direct dynamic Poodle method call or unlock was performed. Fixed the offline script that printed ~51,891 lines: it now emits only the relevant 29 instructions under LLVM or otool. [V24 full analysis](RO23-V24-Poodle-Full-Gate.md).


## V25 — ObjC selector and ClockKit return independently verified (2026-11-11)

Analyzed **the actual uploaded 23U95 Zeus and ClockKit Mach-O binaries**, not a name guess. Zeus stub `0x469C0` → `__objc_selrefs[0x4F0A8]` → `__objc_methname[0x40445]` = **`supportsPDRCapability:`**. Matching `-[CLKDevice supportsPDRCapability:]` at `0x49C6E724` consists solely of `mov w0,#1; ret`, so this specific Poodle capability check always succeeds on this ClockKit build. my category 4 / collection 9 / hardware-face false still produce **Poodle restricted=true**. A read-only SHA-checked Python verifier was executed successfully on both original binaries and added to the repository. No native face activation. [V25 report](RO23-V25-Poodle-Selector-ClockKit.md).


## V26 — watchOS sandbox-escape feasibility and version/signing mismatch (2026-11-11)

Reviewed upstream `forcequitOS/worse_query` and the newer watchOS `LogicSense1/WatchRegion`. The latter **claims** a successful MobileGestalt sales-region edit on Ultra 4/watchOS 27.3 beta and actually targets watchOS 27.0 or later with a dedicated App Group entitlement. my Ultra 1 remains on **26.6.1/23U95** and the public RO23 watch entitlement plist is empty. Historical 23U95 protected writes returned `EPERM`. The upstream iOS-only PoC does not prove 23U95 watchOS compatibility. **Research this nonstandard access primitive by offline capability/signing inspection; do not install WatchRegion unchanged or write live MG.** No watch app source changes or unlock. [V26 compatibility audit](RO23-V26-WatchOS-Sandbox-Feasibility.md).


## V27 — offline tracing of FaceBundleManager's separate restricted-face exception (2026-11-11, Beijing Time)

Instead of retesting the fully mapped normal Poodle gate, added a bounded, read-only `ipsw` shared-cache tracer at `scripts/ro23-v27-exception-stub-trace.sh` for the distinct 23U95 NanoTimeKit stubs `0x55CE73DC` (restricted bundle lookup exception) and `0x55CE731C` (internal-build related). It checks containing function, cache offset and 12 instructions at each address; output capped at 80 lines per command. This was not run on my Mac and is not an unlock. [V27 report](RO23-V27-Exception-Stub-Trace.md).
