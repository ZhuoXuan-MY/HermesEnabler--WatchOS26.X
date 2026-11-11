# RO23 V20 — .watchface descriptors versus native FaceBundle eligibility

**Date:** 2026-11-11 · **Target:** Apple Watch Ultra 1 (Watch6,18), watchOS 26.6.1 / 23U95.
**Outcome:** Prepared read-only offline archive inspector. **No sample .watchface bytes were supplied**; Hermes bundle identity is **not yet known**. No native Hermès face has been installed or unlocked.

## Verified archive and API behavior

The user's earlier Filza screenshots showed ~250 KB files named `Hermès Circulaire.watchface` (plus numbered copies) under iPhone `Watch [com.apple.Bridge] → Documents → Inbox` and ordinary `Modular Ultra.watchface` under the app's temporary `com.apple.watchface` directory. These are **filenames and size observations only**; a filename alone cannot prove a file represents an actual supported Hermès FaceBundle.

Third-party open-source `forcequitOS/FaceRead` (`script.js`) reads .watchface as a ZIP archive and parses:
- `face.json`: `bundle id`, `analytics id`, `face type`, and optional `customization`.
- `metadata.json`: `complications_names` and other layout metadata.
- `snapshot.png`: thumbnail used only for preview.

Code: https://github.com/forcequitOS/FaceRead/blob/main/script.js

Apple describes the .watchface file as including face configuration, styles, color, pictures and complication information:
https://developer.apple.com/documentation/clockkit/sharing-an-apple-watch-face

**Limits:** The exact files from the owner's Filza are not yet available to the researcher. We have not validated their JSON schemas or authenticity. The `face type` JSON field is **not automatically equivalent** to the internal NanoTimeKit `NTKFaceStyle` integer such as `0x2C`; an explicit mapping is required before joining them to the V17 path.

## How file descriptors meet the V17 system checks

```text
.watchface archive on iPhone (configuration + identifiers)
  |
  |  file format / entitlement / source URI validation
  v
CLKWatchFaceLibrary.addWatchFace(at:) (documented API)
  |
  |  may report invalidFile / permissionDenied / faceNotAvailable
  v
Watch application pairing / normal face import request
  |
  |  actual route/call sequence not dynamically traced on 23U95
  v
NanoTimeKit on watch: FaceBundleManager lookup
  +--- by Bundle ID --------> faceBundleForBundleIdentifier:onDevice:forMigration:
  |                           calls isRestrictedForDevice: in normal path
  +--- by legacy style -----> faceBundleForFaceStyle:onDevice:
  |                           also calls isRestrictedForDevice:
  v
_NTKCanAddWatchFace (configuration + descriptor availability + category restrictions)
  v
Only if all relevant conditions pass: eligible native face
```

The above is a **conceptual correlation**, not an observed one-to-one synchronous iPhone-to-watch call trace. The Watch's 23U95 eligibility branches were statically analyzed in V17. User's V13/V14/V16 logs independently confirm: `deviceCategory=4`, `collectionType=9`, `deviceBrand=0`, `NTKInternalBuild=false`. The Hermès2025 face category whitelist `{2,3,5}` excludes category 4. This remains a major independent incompatibility.

## Distinguish file-format failure from hardware eligibility

Apple's public `CLKWatchFaceLibrary.ErrorCode` includes:
- `invalidFile`: specified file is not a valid watchface.
- `permissionDenied`: caller could not read file.
- `faceNotAvailable`: requested face is not available on this device.
- `notFileURL` / `noURL`: missing/invalid URL as applicable.

Documentation:
https://developer.apple.com/documentation/clockkit/clkwatchfacelibrary/errorcode

A `faceNotAvailable` result would support **incompatibility at the public import layer**, but would NOT prove exactly which private branch rejected the face. An `invalidFile` cannot by itself prove device-category rejection. Apple expressly limits Hermès face additions to Hermès hardware. https://developer.apple.com/documentation/clockkit/clkwatchfacelibrary/addwatchface(at:completionhandler:)

We do **not** need to modify, repackage or re-sign the .watchface to read its JSON metadata. In fact, repackaging can break a file and confound testing.

## New repository script — safe local offline analyzer

`scripts/ro23-inspect-watchface.py` (Python 3 standard library, no third-party packages) accepts one or more files, shows their SHA-256, ZIP presence, safe top-level JSON key names, `bundle id`, `analytics id`, `face type`, and an optional complication *count*. It does NOT extract photos, print personal complication data, alter archives, send network requests, install faces or touch the watch.

It limits JSON reads to 2 MiB and archive entries to 1024 to avoid accidental memory blowups. File hashes let the owner distinguish numbered duplicates with same-size names.

Example **only after copying two existing files to Mac via AirDrop/Files**:

```bash
cd "$HOME/Downloads/HermesEnabler-RO23-Live"
python3 scripts/ro23-inspect-watchface.py \
  "$HOME/Downloads/Hermès Circulaire.watchface" \
  "$HOME/Downloads/Modular Ultra.watchface"
```

If those paths don't match the actual files, drag the real files onto Terminal; don't create duplicate clones or copy into source. Filza source archives and iPhone app paths need not be altered. The user can alternatively upload a **single authentic .watchface** to the chat for direct offline analysis. Treat face files as potentially containing personal photos and complication/userInfo; explicitly check privacy before sharing.

## What to do next based on real evidence

1. Inspect one genuine existing Hermès Circulaire and one ordinary Modular Ultra archive. This gives precise identifiers and whether both archives have the same basic schema.
2. Map an observed Hermès bundle identifier to the **matching 23U95 FaceBundle** from earlier static extraction (rather than guessing by the display name).
3. Optionally record an already-observed import error and classify it using documented `CLKWatchFaceLibrary.ErrorCode`. Do not repeatedly import unsupported faces, force migration, edit pairing DB, or overwrite system files just for an error.
4. If sample is absent, STOP: cannot derive a truthful concrete Bundle ID or style from a screenshot of a filename.

**No on-watch code change, no new UI, no privileges or jailbreak, no system writes and no native unlock.**

[RO23 V17 native gate analysis](RO23-V17-FaceBundle-Loading-Chain.md) · [RO23 V19.4 Filza file observations](RO23-V19.1-Filza-Source-And-Bridge-Verification.md) · [Original HermesEnabler](https://github.com/pookjw/HermesEnabler)
