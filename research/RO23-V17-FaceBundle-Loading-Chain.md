# HermesEnabler · watchOS 26.x — V17 — Native FaceBundle Registration, Lookup and Add-to-Library Checks

**Date:** 2026-11-11. **Target:** first-generation Apple Watch Ultra (Watch6,18 / n199ap), watchOS 26.6.1, build 23U95.

**STATUS: NATIVE HERMÈS FACES ARE NOT UNLOCKED.** This is independent **offline static disassembly** of Apple's matching NanoTimeKit binary, cross-referenced against my V13, V14.1 and V16 read-only watch logs. No new system write, face injection, jailbreak, altered signing entitlements, or on-watch face load was performed.

**Original project:** Jinwoo Kim (@pookjw), [HermesEnabler](https://github.com/pookjw/HermesEnabler). **RO23 device research:** @ZhuoXuan-MY; AI-assisted analysis and documentation.

## 1. Analyzed artifact

Extracted private framework: `/System/Library/PrivateFrameworks/NanoTimeKit.framework/NanoTimeKit`, Mach-O **arm64_32**.

- File length: **11,395,800 bytes**
- SHA-256: `bf3f7e360fe06ab7e513807bcb3b6ac695f38c6ea8cd8428b7aed579c2b58e1c`
- Analysis performed with LLVM Mach-O symbol listing and ARM64_32 disassembly.
- The addresses below are the **original binary's VM addresses**, not file offsets, and are not portable to other watchOS builds.

### Evidence categories

- **STATIC:** branch condition and selector are visible in the extracted binary.
- **DEVICE:** values reported by me from the running Watch6,18 / 23U95.
- **INFERENCE:** combined interpretation of these observations. No execution trace of a Hermès bundle was captured.

## 2. Registry construction is not a permission grant

`-[NTKFaceBundleManager _generateLookupsIfNecessary]` at **0x544B0AA0** calls the loader's selector `enumerateFaceBundleClassesIgnoringCache:withBlock:` at **0x544B0B8C**.

It builds a class lookup, but this does **not** establish that each discovered bundle can be enumerated, looked up for a particular device or added to my face library. The three subsequent filters below are independently implemented.

## 3. Listing stage — restricted faces skipped

`-[NTKFaceBundleManager enumerateFaceBundlesOnDevice:includingLegacy:withBlock:]` at **0x544B0C4C** has the following branch:

```asm
0x544B0D2C   bl   _objc_msgSend$faceClass
0x544B0D34   bl   _objc_msgSend$isRestrictedForDevice:
0x544B0D38   tbnz w0, #0, 0x544B0D4C
0x544B0D48   blr  x8
```

If the class reports `isRestrictedForDevice:=true`, execution skips the enumerator's callback `blr x8` for that bundle. The `includingLegacy` argument also controls a separate legacy-style inclusion check at **0x544B0D08–0x544B0D28**. This is a gallery/listing filter, not proof that a forbidden face could be used by skipping a visual list.

## 4. Bundle-ID lookup — restriction rechecked after loading

`-[NTKFaceBundleManager faceBundleForBundleIdentifier:onDevice:forMigration:]` starts at **0x544B0DDC**.

- The bundle object may be obtained from cache or by `loadFaceBundleWithIdentifier:` at **0x544B0E64**.
- A normal lookup tests `faceClass isRestrictedForDevice:`:

```asm
0x544B0F88   tbnz w22, #0, 0x544B0FA4  ; migration-specific branch
0x544B0F94   bl   _objc_msgSend$isRestrictedForDevice:
0x544B0F98   cbz  w0, 0x544B0FA4        ; unrestricted -> continue
0x544B0F9C   bl   0x55CE73DC           ; additional predicate
0x544B0FA0   tbz  w0, #0, 0x544B0FF0  ; reject if predicate is false
...
0x544B1050   mov  x22, #0               ; nil result
```

**Important qualification:** the method is explicitly parameterized `forMigration:`. Its migration-specific branch skips the indicated normal restriction check, but this **is not a demonstrated ordinary add-to-library route**, and separate add validations still exist. I do not propose invoking private migration methods to alter the watch.

**Unresolved:** the implementation/name behind the distinct external call `0x55CE73DC` is not established from the stand-alone extracted dylib. It must **not** be conflated with the prior V16 call `0x55CE731C` associated with `NTKInternalBuild`; those are different addresses. The extracted dylib's standalone Mach-O bind/lazy-bind tables provided no direct symbol mapping for this call.

## 5. Legacy face-style lookup has the same restriction pattern

`-[NTKFaceBundleManager faceBundleForFaceStyle:onDevice:]` starts at **0x544B106C** and may use `loadLegacyFaceBundleForStyle:` at **0x544B10F8**.

```asm
0x544B115C   bl   _objc_msgSend$faceClass
0x544B1164   bl   _objc_msgSend$isRestrictedForDevice:
0x544B1170   cbz  w21, 0x544B117C     ; unrestricted
0x544B1174   bl   0x55CE73DC
0x544B1178   cbz  w0, 0x544B1188     ; restricted + failed predicate -> nil
0x544B1188   mov  x19, #0
```

Therefore changing from a bundle ID to an old Zeus face-style number is **not** a demonstrated way around the device restriction; both lookup paths consult the face class restriction and the same unresolved predicate.

## 6. Add-to-library checks are a separate gate

The exported `_NTKCanAddWatchFace` begins at **0x54602E48**. Key paths:

1. **Configuration validation**: `isValidConfigurationToAddToLibrary` at **0x54602E94**; failure branches to the rejection path at **0x54602F44**.
2. **Descriptor resolution**: a face style of `0x2C` (44) uses the face **bundle identifier**; other styles are handled through the style descriptor constructor at **0x54602FA0–0x54602FB0**.
3. **Device availability**: `isAvailableForDevice:` at **0x54602FD4**, conditional rejection at **0x54602FE0**.
4. **Face-class restriction**: `isRestrictedForDevice:` at **0x5460300C**, conditional rejection handling starting **0x54603018–0x5460301C**.
5. Further checks involve loaded state, style collections and complication slots. Their presence shows that merely constructing a face object is not enough; the full success predicate is more complex than these four checks.

The descriptor method `-[NTKFaceDescriptor isAvailableForDevice:]` at **0x543D998C** explicitly checks `faceStyle == 0x2C` (**0x543D99B0**), calls `faceBundleForBundleIdentifier:onDevice:` (**0x543D99EC**), then returns availability based on the existence of the resulting bundle (**0x543D9A00–0x543D9A04**). For other styles it calls `_NTKFaceStyleIsAvailable` (**0x543D9A18**).

This **explains the interaction of the individual gates**: a bundle-based face may fail its device availability check because the manager refuses to return the restricted bundle, before the additional add-to-library restriction check is reached.

## 7. Applying real Ultra 1 values without overstating them

**DEVICE**, Watch6,18 / 23U95, owner-supplied logs:

| Value | Result |
|---|---|
| `deviceCategory` | `4` |
| `collectionType` | `9` |
| `deviceBrand` | `0` (`__NSCFNumber`) |
| `isZeusBlack` | `false` |
| `NTKInternalBuild` | `false` |
| `NTKShowHardwareSpecificFaces` | `false` |
| `NTKShowInternalFaces` | `false` |

**STATIC:** Hermès 2025 class rejects category `4` against `{2,3,5}`; several legacy Zeus classes have other restrictive conditions. Coupled with the manager gates above, these are independent layers of **reasoned incompatibility**, but they are not an instrumented trace of the system attempting to load a face on this watch.

**Separate unresolved blocker:** direct writes to the protected MobileGestalt cache returned `EPERM`, even after consuming a tested Class-13 extension. The correct DeviceBrand cache mapping (index 103, 0x338) **does not grant authorization**.

## 8. Next work that would materially change the answer

1. Offline resolve the function at `0x55CE73DC` using **matching full dyld shared-cache mapping/symbol data**, rather than guessing from neighboring address `0x55CE731C`. This may identify the system's privileged exception used during restricted lookups.
2. Inspect the `NTKFaceBundleLoader` and `NTKFaceBundleManager` *supported* callers to identify whether any ordinary, non-migration API can **legitimately** satisfy the device predicates. None is demonstrated yet.
3. Maintain the source/project as one existing GitHub repo; do not create or install a redundant watch app or repeat V13/V14/V16 diagnostics without a new hypothesis.

**RO23 V17 contains no new on-device test button, no executable-code modifications, and no native Hermès unlock.**

[Issue #17](https://github.com/pookjw/HermesEnabler/issues/17) · [Original upstream](https://github.com/pookjw/HermesEnabler) · [V16 evidence](RO23-V16-InternalBuild-Gate.md).
