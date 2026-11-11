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
