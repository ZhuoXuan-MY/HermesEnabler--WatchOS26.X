> **Update for accompanying public package:** The obsolete 23U95 direct writer has been removed and the protected-cache write APIs disabled. Historical warning sections below describe the **original user-supplied archive**, not the sanitized package. Xcode build and on-device verification are **still required**.

# Publishing the HermesEnabler RO23 research fork safely

This checklist is for the owner of the **user-supplied local `HermesEnabler(1).zip` snapshot**. It is **not** a claim that the uploaded app is ready for public installation.

## STOP — critical correctness issue

The uploaded `HermesEnabler2/BQCore.m` still contains the experiment `BQWriteHermes23U95`, which sets `valueOffset=0x670` and `presentOffset=0x16B6`. The later Ultra 1 research shows DeviceBrand is at index 103, not 206. **Disable/remove the 23U95 forced-write path before publishing or testing an IPA**, and do not assume replacing the offsets will unlock Hermès faces. There is still no protected SystemGroup write permission or verified face eligibility.

## What to keep

- `README.md` (English repository home)
- `README.zh-CN.md` (complete Chinese edition)
- `LICENSE` (original MIT license with **Copyright (c) 2026 Jinwoo Kim**)
- `NOTICE.md` (original and RO23 contributions separated)
- `PUBLICATION_CHECKLIST.md` (this file)
- Audited, necessary original `HermesEnabler2` Xcode project and source files only
- `HermesEnabler2/Gester-LICENSE.txt` wherever Gester-derived code is included
- Optional: redacted research findings as Markdown, with links to Issue #17 and hashes, not proprietary binary copies

## What to remove from the ZIP before uploading

- Embedded `.git/` directory and its reflogs, remote metadata, object history, and private iteration files (use GitHub's **Fork** feature or create a new clean Git repository).
- Historical `_历史备份` folders; `.class7-flag-probe-source-backup/`; `BQCore.m.before-*` and similar duplicate snapshots; backup ZIPs.
- Personal `.xcuserdata`, `DerivedData`, old developer signing profiles and certificates.
- Personal signing/Bundle ID/App Group identifiers in `*.pbxproj`, entitlements, or source; configure a publicly documented example and have new users provide their own IDs.
- System files or caches, including `OriginalGestalt*.plist`, the owner's logs that include file paths or system identifiers, AEA OTA archives, Apple-owned extracted binaries, dyld caches, and `Assets.car` taken from Apple firmware.
- Sensitive logs, user home paths, personally identifying metadata, and unlicensed imagery. Review the large `image.png` and other images before republishing.

## Safety review

- [ ] Disable the incorrect experimental 23U95 writer and audit every other write/restore path.
- [ ] Review startup `__attribute__((constructor))` functions and make diagnostics opt-in where possible.
- [ ] Clearly label the project **research-only / unsupported on watchOS 26.6.1 / not an unlock**.
- [ ] Restore proper MIT + third-party attribution, and do not remove the original author's name.
- [ ] Perform a clean Xcode build of the sanitized sources and disclose any remaining limitations.
- [ ] Do **not** publish an IPA claiming successful face activation without a real on-device result.
- [ ] Do **not** redistribute proprietary Apple watchOS images, binaries, or Hermès artwork.

## GitHub project setup (manual)

**Recommended repository name:** `HermesEnabler-RO23` (suggestion only; this repository does not exist automatically).

**Preferred route A — GitHub Fork:** Open [pookjw/HermesEnabler](https://github.com/pookjw/HermesEnabler), click **Fork**, and use your own fork as the starting point. This preserves the clearest upstream provenance; add the RO23 research documentation and separately reviewed code changes.

**Route B — independent repository:** In GitHub, create a new repository, explicitly write `Based on pookjw/HermesEnabler by Jinwoo Kim` in its description, and upload **only a sanitized clean source tree**. Keep the upstream MIT `LICENSE` with its original copyright notice; retain Gester-related license text. Use the README and NOTICE documents in this pack.

**Suggested GitHub About description:** `Unofficial HermesEnabler-derived research fork: Apple Watch Ultra 1 / watchOS 26.6.1 (23U95), MobileGestalt, NanoTimeKit and Hermès face availability. Research-only; not an unlock.`

**Suggested topics:** `apple-watch`, `watchos`, `mobilegestalt`, `nanotimekit`, `clockkit`, `reverse-engineering`, `research`, `hermesenabler`.

**Suggested first release:** none yet. Prefer an initial **source-only research commit**. If a buildable research snapshot is published later, state exactly what diagnostics it runs and whether any state-changing functions are disabled.

## Research documentation links

- Main findings: https://github.com/pookjw/HermesEnabler/issues/17
- Read-only V5–V7 XPC comparison: https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6777128180
- Matching firmware V8: https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6777949079
- Matching libMobileGestalt V9: https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6778385658

V10–V12 should be described as local static research results until the corresponding reports are deliberately published.
