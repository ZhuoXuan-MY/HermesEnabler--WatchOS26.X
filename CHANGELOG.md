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
