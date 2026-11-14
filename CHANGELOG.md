# HermesEnabler · watchOS 26.x — Research changelog

## 2026-11-14 17:58 CST — GestaltX v1.1.1 device self-pairing and file-path source audit

- I reviewed the original [GestaltX v1.1.1 release](https://github.com/huamidev/GestaltX/releases/tag/v1.1.1) (build `11140102`, published **2026-11-14 00:46 CST**) and the **tagged** Swift/Rust source. The release adds **Pairing & Device Connection** and **App Audio Library**, with fixes to pairing in side-loaded builds and pairing-file migration.
- The UI explicitly says **“Pair this iPhone once”**. The native device-console implementation uses **iPhone self-pairing**, RSD/Lockdown, LocalDevVPN and `com.apple.syslog_relay` to discover notification-audio file paths. Its Rust source calls this **a connection path, not an Airlift exploit**. The console needs `GXDeviceConsole` + the `GXDEVICECONSOLE` build condition; source presence alone does not prove a particular signed IPA can connect.
- The upstream README lists **iPhone/iPad iOS 27.x** for direct MobileGestalt access and explicitly says **iOS/iPadOS 26.x is unsupported** for that feature. I found **no watchOS 26.6.1 / `23U95` protected SystemGroup write mechanism** in the new connection modules. Pairing and learning a path do not overcome the target's real `open(O_RDWR) → EPERM`, nor the separate Hermès eligibility restrictions.
- This was **GitHub release + static-source analysis only**. **I did not install GestaltX, compile/run it in Xcode, connect/pair my physical Watch, write protected caches, or enable a native Hermès face**. No application code was merged or replaced; **status remains BLOCKED / NOT UNLOCKED**. [Bilingual full audit](research/2026-11-14-GestaltX-v1.1.1-Device-Pairing-Compatibility.md).

## 2026-11-12 — Started a separate hourly watchOS 26 research-update monitor

- I enabled a **separate, recurring hourly alert task** focused on the first-generation Apple Watch Ultra (`Watch6,18 / n199ap`) and watchOS 26.6.1 (`23U95`). It is distinct from any other recurring tasks.
- The monitor covers upstream HermesEnabler and Issue #17, WatchRegion, WorstGestalt, `bad_query` / `worse_query`, WQFiles, EscapeOS, Filza, Erosion, MobileGestalt editors, jailbreaks, non-jailbreak access methods, SystemGroup sandbox escape/path traversal, newly disclosed CVEs, security advisories, and newly found projects, commits, releases, PRs, issues, PoCs, or actual physical-Watch results.
- It sends **Chinese notifications only for newly observed relevant changes**, citing dated primary sources. Every alert must distinguish **the target `23U95` device** from other watchOS hardware, iOS-only results, static research, and unverified claims. It must assess the existing `open(O_RDWR) → EPERM` privilege barrier and native Hermès face eligibility separately.
- The schedule monitors public information; **this is not a continuous live background process, a GitHub Actions workflow, or an automatic source-code merge**. No exploitation, physical-Watch access, system-cache writes, or unlock were performed or promised. **Project status remains BLOCKED**.

## 2026-11-12 17:09 CST — Independently validated WorstGestalt and WatchRegion source paths

- I inspected the latest source blobs for WorstGestalt `BQCore.swift`, my watchOS 26 `BQCore.m`, WatchRegion `RegionCache.swift`, and WQFiles documentation and ran **10 source checks: 8 YES, 2 NO**. The two NO results mean (1) my current fork does **not** have the same file-targeted `bad_query` strategy, and (2) no successful `Watch6,18/23U95` runtime write has been established. Neither is a claim that the new strategy was executed on my watch.
- The WorstGestalt method is materially different from my existing generic Class-13 call: it probes a specific MobileGestalt file and checks a writable file descriptor after acquiring a token. My previous Class-13 token success / `EPERM` write failure does not constitute a runtime test of that new variant.
- I also read public WatchRegion Issues: [#4](https://github.com/LogicSense1/WatchRegion/issues/4) reports **Ultra 2 / watchOS 27.2 `24S118`** region modification, adding to the prior Ultra 4 / watchOS 27.3 beta evidence. [#1](https://github.com/LogicSense1/WatchRegion/issues/1) asks about Ultra 1 but currently has no successful report. **None verifies watchOS 26.6.1 `23U95`.**
- **No physical Watch session, sandbox-escape runtime, protected-file modification, or native Hermès activation.** Remain `BLOCKED`. [Full source validation and evidence table](research/2026-11-12-WorstGestalt-WatchRegion-Static-Validation.md).

## 2026-11-12 16:22 CST — Recent watchOS vulnerabilities and Filza / MobileGestalt tool audit

- I reviewed the official **Filza 5.0.1 beta build 3** (November 9), GitHub **WorstGestalt v1.0.0**, **WQFiles v0.9.3**, **EscapeOS v0.3.2**, **WatchRegion v0.4.0**, Erosion, `worse_query`, and upstream **HermesEnabler v1.5.1** (November 12), scoped strictly to **Watch6,18 / watchOS 26.6.1 / 23U95**.
- **Only unverified technical lead:** WorstGestalt documents a `bad_query` **file-targeted Class-13** mechanism used for **iOS 26 MobileGestalt editing**. Its `Sources/WorseGestalt/BQCore.swift` contains a file-form attempt and slightly different query setup from the existing Watch research `HermesEnabler2/BQCore.m`. This does **not** establish watchOS compatibility, and earlier Watch tests already demonstrated that a consumed Class-13 token can still lack file-write permission.
- **Other tools are not 23U95 writers:** WQFiles expressly says its iOS-26 `worse_query` implementation cannot access SystemGroup; Filza is an iPhone/iPad/iPod touch file manager; EscapeOS is iPhoneOS; WatchRegion's packaged v0.4.0 targets watchOS 27+, and HermesEnabler 1.5.1 remains watchOS 27 only.
- Apple's [watchOS 26.6 advisory](https://support.apple.com/en-us/128068) contains root/sandbox/kernel issues **fixed in 26.6** (e.g. MediaRemote `CVE-2026-43723`, AVEVideoEncoder `CVE-2026-64747`, libc `CVE-2026-28973`). The [November 9 watchOS 26.6.1 advisory](https://support.apple.com/en-us/149723) describes additional fixed pairing/Bluetooth/network issues. These are **not verified exploits against the already-updated 23U95**.
- **Evidence level: public release and code review only.** No Watch connection, exploit execution, protected-cache write, or native Hermès unlock attempted. **Status remains `BLOCKED`.** [Full dated audit](research/2026-11-12-watchOS26-Filza-Gestalt-Security-Audit.md).

## 2026-11-12 — Original upstream HermesEnabler 1.5 Simulator test and isolated UI patch

- I ran the **original author's HermesEnabler 1.5**, not this fork, in Xcode's **Apple Watch Ultra 3 / watchOS 27.0 Simulator**. The app presented a MobileGestalt access error; the debug console showed `[bqtool] escape: all strategies failed (last=-5)` targeting the watchOS protected MobileGestalt SystemGroup. This **does not establish failure on a supported physical watch**.
- I initially applied Simulator-specific changes to this fork's `HermesEnabler2/ContentModel.swift` and `ContentView.swift` by mistake. These were **fully reverted** in [`0cb47be`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/0cb47be30332ae8d4c9e15ae4dbd6bfa121e9f88) and [`314ff4d`](https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X/commit/314ff4d8c57398bea77d254ac2da4ef623b29cf4); the original Ultra 1 research source remains intact.
- I then prepared and uploaded a version-specific [upstream 1.5 one-file patch](patches/HermesEnabler-1.5-watchOS-Simulator-UI-Preview.patch) and [complete patched `ContentView.swift`](patches/upstream-1.5/ContentView.swift). They add a **Simulator-only preview** with browsable UI and disabled controls, with no protected MobileGestalt operations; the physical-watch code remains in the compile-time `#else` branch.
- The patch input was verified against upstream **tag `1.5`** `ContentView.swift` Git blob `951eb9aeb56f4860a0e52b5221770a2763f6d0a9`; patch line counts and conditional compilation guards were checked. **No Xcode compilation or Simulator execution of the patch has yet been observed.** The user's original Simulator failure, the patch creation, and a working Simulator result are **three distinct pieces of evidence**, not interchangeable.
- Full first-person development and reproducibility record: [Upstream HermesEnabler 1.5 Simulator report](research/Upstream-HermesEnabler-v1.5-Simulator-Preview.md). This does **not** change the project's `Watch6,18/23U95` **BLOCKED / NOT UNLOCKED** status.

## 2026-11-12 — Upstream HermesEnabler v1.5 evaluated (no 23U95 unlock)

- Reviewed the official [HermesEnabler 1.5](https://github.com/pookjw/HermesEnabler/releases/tag/1.5) release (published 2026-11-12 09:38 Beijing Time) and its changes: watchOS 27.2 beta 1 (`24S5112a`), Ultra face layout choices, backup library and Watch/iPhone transfer, byte-level post-write verification/rollback, and interface translations.
- The upstream `MGOffsets.plist` does **not** include `23U95`. Its `BQCore.m` still calls `open(O_RDWR | O_CLOEXEC | O_NOFOLLOW)` to write the protected plist; the new readback/rollback checks **do not grant write access**. [Upstream PR #51](https://github.com/pookjw/HermesEnabler/pull/51) explicitly says the MobileGestalt modification mechanism was **not changed**.
- [PR #52](https://github.com/pookjw/HermesEnabler/pull/52) reports Hermès activation on a **Series 10 (Watch7,9), 24S5112a**, not the target Ultra 1 `Watch6,18 / 23U95`. The upstream README still says **watchOS 27.0–27.3 beta 1 only**.
- Decision: preserve this watchOS 26 research fork and its safety guards; **do not automatically merge** upstream v1.5's unrelated watchOS 27 code. No install, firmware write, privilege escalation, or native Hermès activation was attempted. **Status remains BLOCKED**.
- Full [version-specific source and compatibility audit](research/Upstream-HermesEnabler-v1.5-Compatibility.md).

## 2026-11-11 — Project status changed to BLOCKED (not permanently abandoned)

**Scope:** First-generation Apple Watch Ultra (`Watch6,18 / n199ap`), watchOS 26.6.1 build `23U95`. **Native Hermès unlock remains unsuccessful.**

- Historical Watch testing could read the protected MobileGestalt cache, but opening it with `O_RDWR` returned `EPERM`; the Class-13 token did not grant write access. Geod-MCM and tested Class-7 flag routes also did not produce a working protected write.
- The matching 23U95 binaries and real watch observations establish **separate native face-eligibility gates** (Hermes2025 category and Circulaire/Poodle restrictions). A working write alone would not automatically prove native Hermès activation.
- The upstream `worse_query` project advertises SystemGroup access for **iOS 27**, not iOS 26. No reproducible Watch6,18 / 23U95 privileged write path was established; this does not prove every hypothetical watchOS 26 approach is impossible.
- **Decision:** pause new speculative unlock versions and repeated unproductive tests. Retain V0–V30 research, historical logs, source and branches as an explicitly **blocked research project**. Do not publish the repository as an enabled/working Hermès watchface solution.
- **Reopen only on evidence:** (1) independently reproducible privileged write or equivalent system-authorized route **on Watch6,18 / 23U95**, (2) verified readback and persistence without damaging the watch, and (3) normal system face eligibility, addition and visible native Hermès face. All three milestones remain unachieved.
- **This commit changes documentation only.** It does not archive/delete the repository, revert the code, remove prior findings, claim a jailbreak, or alter any my Apple Watch.

## 2026-11-11 — Initial sanitized source package

Based on my uploaded `HermesEnabler(1).zip`, with upstream attribution preserved.

- Retained the `HermesEnabler2` Watch App Xcode project, core code, and RO23 diagnostic implementations.
- **Removed** the historical Geod writable-file experiment `BQGeodOpen23U95` and incorrect `BQWriteHermes23U95` forced writer (`0x670`/`0x16B6`).
- Replaced `BQSaveGestalt`, `BQRestoreGestalt`, `BQEnableHermes`, and capability-override writer with fail-closed methods. Direct protected-cache writing helper removed.
- Removed UI controls for Hermès enabling, AOD overrides, cache restoration, Class 7 flag mutation, and respring.
- Disabled automatic start of RO23 V1–V7 diagnostics; added an explicit button to run them.
- Retained direct cache reads, compatibility reports, and app-local backup diagnostics.
- Removed embedded Git history, old backups, duplicated sources, personal signing identifiers, and unrelated legacy assets/targets.
- Added upstream MIT `LICENSE`, third-party `Gester-LICENSE.txt`, bilingual READMEs, and attribution documentation.

### Verification level

- Source ZIP manifest, critical string checks, and privacy-sensitive identifier checks were verified offline.
- **No Xcode/watchOS SDK is available in this build environment**: no clean compilation, signing, installation, or runtime safety claim is made.
- Original private Apple firmware binaries, face resources, and AEA files are **not** included.

### Historic findings

- Correct `DeviceBrand`: descriptor index 103, integer type 5, cache value offset `0x338`, presence byte `0x164F`.
- Old index 206 and `0x670` belong to a different descriptor; never reuse them for writing.
- SystemGroup writes returned `EPERM`; genuine Hermès face activation remains unverified.
- See [Issue #17](https://github.com/pookjw/HermesEnabler/issues/17) and README for the V1–V12 evidence trail.


## RO23 V14.2 · 2026-11-11
- Integrated upstream UI, localizations, iPhone Companion and Xcode project.
- Added isolated RO23 V13/V14.1/cache read-only probes and 23U95 UI write controls hide.
- Corrected deviceBrand object return type and preserved upstream credits.
- Native Hermès unlock is not achieved; Xcode physical build not yet verified.


### RO23 V14.2.1 — Xcode build repair
- Rename RO23Diagnostics C helper Boolean to RO23ReadBool to avoid CoreFoundation Boolean typedef collision.
- Remove placeholder App Group entitlement from the read-only research signing profile; free/personal development teams may not have App Groups provisioning.
- No changes to protected MG cache or watchface installation. Real Xcode build still needs user-side verification.


### RO23 V15 — read-only evidence update (2026-11-11)
- Device owner confirmed the merged Xcode project runs V13, V14.1 and MG snapshot diagnostics on Watch6,18 / 23U95.
- Added offline NanoTimeKit analysis of NTKShowHardwareSpecificFaces precondition, cached setting and notification.
- No new watch-side probes or protected system writes; native Hermès faces are not unlocked.


### RO23 V16 — identify and measure the internal-build gate (2026-11-11)
- Matched the private NanoTimeKit `_NTKInternalBuild` thunk at `0x54601310` to the exact external target called by `_NTKShowHardwareSpecificFaces`.
- Reviewed the Zeus Poodle/Bellona restrictions: under the observed Ultra collectionType=9 and hardware-face flag=false, neither supplies a demonstrated unrestricted path.
- Added a single on-demand, read-only V16 button to measure exported internal-build gate and control predicates. Real watch output not yet obtained. No unlock or protected writes.


### RO23 V16.1 — expose V16 on watch main screen (2026-11-11)
- Put the V16 read-only test directly on the main screen with a visible V16.1 marker and inline result.
- Preserve other diagnostics in a secondary screen; no system writes or face installation.
- Requires pull + fresh Xcode watch installation to appear on the device.


### RO23 V16.1 — on-device result confirmed (2026-11-11)
- Confirmed real Watch6,18 / 23U95: NTKInternalBuild=false, NTKShowHardwareSpecificFaces=false, NTKShowInternalFaces=false; no writes or face installation.
- Identified that internal-build precondition short-circuits a preference-only hardware-face display attempt; no additional executable changes in this documentation update.


### RO23 V17 — static FaceBundle loading-path audit (2026-11-11)
- Traced actual NanoTimeKit FaceBundle enumeration, bundle-ID and legacy-style lookups, and _NTKCanAddWatchFace checks, with function/branch addresses.
- Identified additional unresolved restricted-face exception predicate at 0x55CE73DC (distinct from the V16 internal-build target 0x55CE731C).
- Distinguished migration-only special path from supported normal face addition. Documents only; no new Xcode code, device tests, or unlock.


### RO23 V18 — restricted-face predicate symbol investigation (2026-11-11)
- Verified two call sites to 0x55CE73DC in matching 23U95 NanoTimeKit; function identity not yet established.
- Documented safe, read-only address-to-symbol lookup in the already-extracted dyld shared cache. No new Xcode UI, installation, jailbreak or system writes.


### RO23 V19 — Filza 27.2.2 / iPhone-Watch sync capability boundary (2026-11-11)
- Correlated release screenshot against worse_query's iOS 26 container scope, paired Watch DeviceRegistry/NanoPreferencesSync forensic paths, and Apple's hardware eligibility on importing faces.
- Gitea source release could not be independently fetched; did not attribute unrelated Filza forks' source to this one.
- Defined read-only, metadata-only on-device verification; no source code change, system mutation, or new project copy.


### RO23 V19.1 — exact uploaded Filza source and on-iPhone Bridge container proof (2026-11-11)
- Corrected prior inaccessible-source claim: verified v27.2.2 ZIP and source paths (WQFilzaIntegration, WQLSStore, WQWebDAVServer, WQSSHServer, Tweak).
- Confirmed iPhone Filza `Watch [com.apple.Bridge]` data-container root listed; no system-group/watchOS access demonstrated.
- Flagged WebDAV autostart/open-network bind/no-username-auth and optional SSH fixed `alpine` credentials. No watch code changes.


### RO23 V19.2 — owner-supplied Bridge Library listings (2026-11-11)
- Recorded observed iPhone Watch application Library folders and candidate ClockKit.plist (80 B), pbbridge.plist (68 B) from Filza screenshots.
- Identified E2E KVS change-token path as potentially sensitive; no token content inspection or pairing database edits.
- No proof of watchOS native face entitlement or filesystem writes. No code or UI changes.


### RO23 V19.3 — ClockKit preference single-key evidence (2026-11-11)
- Actual Filza screenshot: com.apple.ClockKit.plist Dictionary[1], String HandFactoryCachedBuild=24B5089g.
- Correlated cache build string with iOS 27.2 beta 2 (2026-09-21). Does not establish current iPhone build or watch Hermès authorization.
- No system write or Xcode source changes; next test is only listing CreateWatchFace component app-container top level.


### RO23 V19.4 — CreateWatchFace component preference metadata (2026-11-11)
- Owner confirms listing two preference plists in com.apple.NanoTimeKit.CreateWatchFace container; observed cached builds 20F66, 21C66 and UltraFaceWasAddedToLibrary=YES.
- File-to-key mapping inferred from byte sizes only because editing screenshots omit filename.
- No verified Hermes authorization, category mutation or watchOS system write. No executable changes or new Xcode/UI artifacts.


### RO23 V20 — .watchface archive parser and import error research (2026-11-11)
- Verified FaceRead's actual standard ZIP face.json fields: bundle id, analytics id, face type; metadata complication count; preview filename.
- Added safe read-only Python 3 inspector for one/many existing .watchface archives: SHA-256, root JSON identifiers, no extraction/writes/network/face-installation.
- Classified Apple public faceNotAvailable vs invalidFile vs permissionDenied; no real Hermès sample bytes, no inferred Bundle ID or unlock.


### RO23 V20.1 — decoded actual uploaded Hermès Circulaire watchface (2026-11-11)
- Verified original 249,760-byte watchface has valid ZIP central directory, 7 entries, all CRC passes, and readable JSON.
- Confirmed actual legacy bundle com.apple.NTKPoodleFaceBundle, analytics id poodle, face type bundle, forMigration=false. Do not conflate face.json migration flag with the NanoTimeKit method argument.
- Compared with V16 Poodle static conditions and actual Ultra1 collectionType=9/hardware-face predicate=false. No native face installation or unlock. Kept personalized manifest data out of public GitHub.


### RO23 V21 — Poodle-specific firmware decision path (2026-11-11)
- Joined validated my Hermès Circulaire bundle ID to Poodle's secondary FaceBundle registration in 23U95 NTKZeusFaceBundle.
- Distinguished Poodle's documented category=1 exclusion from Hermes2025's different {2,3,5} whitelist; do not claim category=4 alone rejects Poodle.
- Evaluated the known conditional Poodle fallback with real Ultra values: collectionType=9, NTKShowHardwareSpecificFaces=false -> restricted on that reached branch; earlier branches unresolved.
- Added optional read-only offline, SHA-256-verified llvm-objdump script for Poodle's full function prologue. No watch-side code changes or unlock.


### RO23 V22 — watch-side Poodle eligibility checkpoint (2026-11-11)
- Added actual source implementation `RO23V22PoodleReport()` that reads current device category/collection, NanoTimeKit internal-build/hardware-face predicate, and conditionally queries the original Poodle class if already registered in this process.
- Added **V22 · Poodle eligibility** directly to the watch home screen with clear RO23 V22 version marker, and also to secondary diagnostics.
- Reports static fallback estimates as conditional, not full-function facts. No force bundle loading, private hooks, watchface installation or protected writes. Real Watch6,18 test and Xcode build are not yet verified.


### RO23 V22.1 — make Poodle button the first Watch-home action (2026-11-11)
- Reordered ContentView so `V22 · Poodle eligibility` appears directly under a visible `RO23 V22.1 installed` marker, **before** the lengthy V16 diagnostic result.
- Fixes discoverability when prior V16 output pushes later rows below the watch viewport. No changes to signing, entitlements, protected writes, or Poodle runtime logic.
- Requires the actual open Xcode checkout and watch target to be synchronized and redeployed; a GitHub commit does not remotely install a new build.


### RO23 V22.2 — first successful V22 physical-watch run (2026-11-11)
- locally provided live output: 23U95, category=4, collectionType=9, NTKInternalBuild=false, NTKShowHardwareSpecificFaces=false.
- Poodle category==1 check does not match; known later fallback evaluates restricted if reached; dynamic NTKPoodleFace class was unregistered in diagnostic process so actual restriction return remains unavailable.
- Recorded literal observed log without guessing. No new executable code, system writes, face activation, or installer modification. Next meaningful step: complete early Poodle disassembly in already-extracted 23U95 Zeus binary.


### RO23 V23 — no-LLVM Mac fallback for Zeus/Poodle disassembly (2026-11-11)
- Verified from my run that the already-extracted NTKZeusFaceBundle SHA-256 matched; analysis halted only because llvm-objdump was unavailable.
- Updated the same V21 script to auto-detect llvm-objdump including Xcode, otherwise fall back to Xcode otool (arm64_32, -tvV) filtered to the Poodle instruction address interval.
- No installations, source cloning, watch firmware modifications, or new diagnostic buttons. Await actual V23 disassembly output.


### RO23 V24 — complete real Poodle disassembly and fixed oversized LLVM output (2026-11-11)
- Analyzed owner-supplied 23U95 Zeus output, matching SHA-256, 51,891 log lines; reconstructed all 29 instructions of +[NTKPoodleFace isRestrictedForDevice:] 0x13B4–0x1424.
- Complete static decision: category==1 -> restricted; capability call 0x469C0 false -> restricted; if true, collectionType==5 -> unrestricted else !NTKShowHardwareSpecificFaces. Given actual Ultra1 category4/collection9/hardwarefalse, both capability outcomes yield restricted.
- Updated V21 script to filter actual instruction PCs for both LLVM and otool; 29 lines instead of 50k+. No app/UI changes, device writes, or native Hermès unlock.


### RO23 V25 — genuine ObjC stub-to-selector resolution in matching firmware (2026-11-11)
- Inspected real user-uploaded Zeus (663,040 bytes; sha256 2b34d3...) and ClockKit (1,425,840 bytes; sha256 5fc1784...).
- Resolved Zeus 0x469C0 via arm64_32 __objc_stubs → __objc_selrefs[0x4F0A8] → __objc_methname[0x40445] to `supportsPDRCapability:`; independently resolved category and collection getter stubs.
- Verified matching ClockKit `-[CLKDevice supportsPDRCapability:]` at VM 0x49C6E724 consists of MOV W0,#1; RET. Poodle's method rejects measured Ultra 1 values despite this predicate always returning true.
- Added a read-only standard-library Python verifier, tested successfully against actual uploaded binary files. No watch code changes, system writes, or unlock.


### RO23 V26 — audit watchOS sandbox-escape portability (2026-11-11, Beijing Time)
- Inspected forcequitOS/worse_query (iOS-only documented range) and LogicSense1/WatchRegion (watchOS target 27.0, claimed Ultra4/27.3 beta MobileGestalt region write, App Group required).
- Checked current RO23 entitlements remain empty and earlier 23U95 EPERM write failure. Upstream PoC alone does not prove a watchOS 26 privilege/write primitive.
- Isolated an offline feasibility path; did not copy GPL exploit code, run it on a device, change Apple firmware, or attempt Hermès activation.


### RO23 V27 — bounded offline exception-stub tracer (2026-11-11, Beijing Time)
- Preserved V26 watchOS sandbox feasibility analysis; no GPL source copied or unsafe watchOS 26 exploit test attempted.
- Added `scripts/ro23-v27-exception-stub-trace.sh`, checking `a2f`, `a2o`, and bounded `disass --vaddr` for two separate 23U95 NanoTimeKit stub addresses without giant logs.
- Actual cache disassembly/bind identity not yet received. No protected data writes or native Hermès unlock.
