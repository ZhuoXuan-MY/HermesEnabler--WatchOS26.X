# HermesEnabler RO23 — Public research snapshot changelog

## 2026-11-11 — Initial sanitized source package

Based on the device owner's uploaded `HermesEnabler(1).zip`, with upstream attribution preserved.

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
- Joined validated owner's Hermès Circulaire bundle ID to Poodle's secondary FaceBundle registration in 23U95 NTKZeusFaceBundle.
- Distinguished Poodle's documented category=1 exclusion from Hermes2025's different {2,3,5} whitelist; do not claim category=4 alone rejects Poodle.
- Evaluated the known conditional Poodle fallback with real Ultra values: collectionType=9, NTKShowHardwareSpecificFaces=false -> restricted on that reached branch; earlier branches unresolved.
- Added optional read-only offline, SHA-256-verified llvm-objdump script for Poodle's full function prologue. No watch-side code changes or unlock.


### RO23 V22 — watch-side Poodle eligibility checkpoint (2026-11-11)
- Added actual source implementation `RO23V22PoodleReport()` that reads current device category/collection, NanoTimeKit internal-build/hardware-face predicate, and conditionally queries the original Poodle class if already registered in this process.
- Added **V22 · Poodle eligibility** directly to the watch home screen with clear RO23 V22 version marker, and also to secondary diagnostics.
- Reports static fallback estimates as conditional, not full-function facts. No force bundle loading, private hooks, watchface installation or protected writes. Real Watch6,18 test and Xcode build are not yet verified.
