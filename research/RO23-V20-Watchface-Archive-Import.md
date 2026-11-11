# HermesEnabler · watchOS 26.x — V20 — .watchface descriptors versus native FaceBundle eligibility

**Date:** 2026-11-11 · **Target:** Apple Watch Ultra 1 (Watch6,18), watchOS 26.6.1 / 23U95.
**Outcome:** Prepared read-only offline archive inspector. **No sample .watchface bytes were supplied**; Hermes bundle identity is **not yet known**. No native Hermès face has been installed or unlocked.

## Verified archive and API behavior

my earlier Filza screenshots showed ~250 KB files named `Hermès Circulaire.watchface` (plus numbered copies) under iPhone `Watch [com.apple.Bridge] → Documents → Inbox` and ordinary `Modular Ultra.watchface` under the app's temporary `com.apple.watchface` directory. These are **filenames and size observations only**; a filename alone cannot prove a file represents an actual supported Hermès FaceBundle.

Third-party open-source `forcequitOS/FaceRead` (`script.js`) reads .watchface as a ZIP archive and parses:
- `face.json`: `bundle id`, `analytics id`, `face type`, and optional `customization`.
- `metadata.json`: `complications_names` and other layout metadata.
- `snapshot.png`: thumbnail used only for preview.

Code: https://github.com/forcequitOS/FaceRead/blob/main/script.js

Apple describes the .watchface file as including face configuration, styles, color, pictures and complication information:
https://developer.apple.com/documentation/clockkit/sharing-an-apple-watch-face

**Limits:** The exact files from my Filza are not yet available to the researcher. I have not validated their JSON schemas or authenticity. The `face type` JSON field is **not automatically equivalent** to the internal NanoTimeKit `NTKFaceStyle` integer such as `0x2C`; an explicit mapping is required before joining them to the V17 path.

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

The above is a **conceptual correlation**, not an observed one-to-one synchronous iPhone-to-watch call trace. The Watch's 23U95 eligibility branches were statically analyzed in V17. my V13/V14/V16 logs independently confirm: `deviceCategory=4`, `collectionType=9`, `deviceBrand=0`, `NTKInternalBuild=false`. The Hermès2025 face category whitelist `{2,3,5}` excludes category 4. This remains a major independent incompatibility.

## Distinguish file-format failure from hardware eligibility

Apple's public `CLKWatchFaceLibrary.ErrorCode` includes:
- `invalidFile`: specified file is not a valid watchface.
- `permissionDenied`: caller could not read file.
- `faceNotAvailable`: requested face is not available on this device.
- `notFileURL` / `noURL`: missing/invalid URL as applicable.

Documentation:
https://developer.apple.com/documentation/clockkit/clkwatchfacelibrary/errorcode

A `faceNotAvailable` result would support **incompatibility at the public import layer**, but would NOT prove exactly which private branch rejected the face. An `invalidFile` cannot by itself prove device-category rejection. Apple expressly limits Hermès face additions to Hermès hardware. https://developer.apple.com/documentation/clockkit/clkwatchfacelibrary/addwatchface(at:completionhandler:)

I do **not** need to modify, repackage or re-sign the .watchface to read its JSON metadata. In fact, repackaging can break a file and confound testing.

## New repository script — safe local offline analyzer

`scripts/ro23-inspect-watchface.py` (Python 3 standard library, no third-party packages) accepts one or more files, shows their SHA-256, ZIP presence, safe top-level JSON key names, `bundle id`, `analytics id`, `face type`, and an optional complication *count*. It does NOT extract photos, print personal complication data, alter archives, send network requests, install faces or touch the watch.

It limits JSON reads to 2 MiB and archive entries to 1024 to avoid accidental memory blowups. File hashes let me distinguish numbered duplicates with same-size names.

Example **only after copying two existing files to Mac via AirDrop/Files**:

```bash
cd "$HOME/Downloads/HermesEnabler-RO23-Live"
python3 scripts/ro23-inspect-watchface.py \
  "$HOME/Downloads/Hermès Circulaire.watchface" \
  "$HOME/Downloads/Modular Ultra.watchface"
```

If those paths don't match the actual files, drag the real files onto Terminal; don't create duplicate clones or copy into source. Filza source archives and iPhone app paths need not be altered. I can alternatively upload a **single authentic .watchface** to the chat for direct offline analysis. Treat face files as potentially containing personal photos and complication/userInfo; explicitly check privacy before sharing.

## What to do next based on real evidence

1. Inspect one genuine existing Hermès Circulaire and one ordinary Modular Ultra archive. This gives precise identifiers and whether both archives have the same basic schema.
2. Map an observed Hermès bundle identifier to the **matching 23U95 FaceBundle** from earlier static extraction (rather than guessing by the display name).
3. Optionally record an already-observed import error and classify it using documented `CLKWatchFaceLibrary.ErrorCode`. Do not repeatedly import unsupported faces, force migration, edit pairing DB, or overwrite system files just for an error.
4. If sample is absent, STOP: cannot derive a truthful concrete Bundle ID or style from a screenshot of a filename.

**No on-watch code change, no new UI, no privileges or jailbreak, no system writes and no native unlock.**

[RO23 V17 native gate analysis](RO23-V17-FaceBundle-Loading-Chain.md) · [RO23 V19.4 Filza file observations](RO23-V19.1-Filza-Source-And-Bridge-Verification.md) · [Original HermesEnabler](https://github.com/pookjw/HermesEnabler)


## V20.1 — Real Hermès Circulaire archive successfully parsed (2026-11-11)

**Original user-supplied attachment read directly**: `Hermès Circulaire(1).watchface` (Unicode filename normalized only in display; underlying bytes untouched). I had already uploaded this file in chat. Earlier requests for me to export/share it again were unnecessary.

- **Actual size:** 249,760 bytes.
- **SHA-256:** `d8364f574fbfcbf16a46d7ae07fbdf74267621a7f6ec2e7525e8018d2659fb03`
- **Container:** valid ZIP. Python standard-library `zipfile.is_zipfile` succeeded, 7 entries listed, and `ZipFile.testzip() == None` (all entries' CRC passed).
- **Entries:** `complicationData/`, `complicationData/bottom-left/`, `complicationData/top-left/`, `snapshot.png`, `metadata.json`, `face.json`, `no_borders_snapshot.png`.
- **Manifests:** both `face.json` (584 bytes uncompressed) and `metadata.json` (1093 bytes uncompressed) successfully decoded as JSON. Their full private contents and the images are **not** copied to this public repo.

**Verified minimal `face.json` fields** (only non-sensitive identifiers):

```json
{
  "analytics id": "poodle",
  "face type": "bundle",
  "bundle id": "com.apple.NTKPoodleFaceBundle",
  "forMigration": false,
  "customization": {"color": "white"},
  "version": 4
}
```

**Other metadata** (only aggregate values): `metadata.json` has `version=2` and `device_size=2`, with five named complication positions. The interpretation of `device_size=2` is not established here. The source manifests may contain personalized complication configurations, so the public report deliberately omits their contents.

### What this proves and does NOT prove

1. my actual **Hermès Circulaire** archive names the *legacy Poodle* bundle `com.apple.NTKPoodleFaceBundle`, not the separate Hermes2025 face bundle. The display label and the native bundle name are not interchangeable.
2. **Filza's “Could not decompress this file” was a viewer failure for this intact uploaded copy**, not proof the ZIP was damaged. I have not identified the exact cause inside Filza's viewer.
3. The `forMigration: false` JSON property is a file field; **do not assume** it is passed unchanged to the separate Objective-C `faceBundleForBundleIdentifier:onDevice:forMigration:` parameter. The import pipeline hasn't been dynamically traced.
4. The 23U95 Zeus Poodle restriction analysis recorded in V16 includes a later `collectionType == 5` acceptance branch or a fallback `NTKShowHardwareSpecificFaces()` condition, conditional on earlier category tests. On my real Ultra 1, `collectionType=9` and `NTKShowHardwareSpecificFaces=false`, so the *observed properties fail those previously mapped Poodle conditions*. This is a static-plus-real-property conclusion, not a captured real face-install attempt. Independent restrictions may also apply.
5. ZIP validity and a valid Bundle ID do **not** establish that the native face is eligible or installable on this watch. No Apple Watch face was installed, no system settings altered and no bypass verified.

### Next research step

Compare this **specific** `com.apple.NTKPoodleFaceBundle` against the actual 23U95 Zeus Poodle class restriction and the FaceBundleManager lookup predicate, using already-extracted firmware. Do not ask me to upload the same attachment again, change serial numbers or modify pairing files. If an already-observed import error exists, classify it separately from the viewer ZIP error.

**Source:** the uploaded watchface archive, not a screenshot or an assumed description.
