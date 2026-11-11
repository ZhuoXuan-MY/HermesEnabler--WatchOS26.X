# HermesEnabler · watchOS 26.x — V18 — Verifying the unresolved restricted-face exception call

Date: 2026-11-11. Target: first-gen Apple Watch Ultra (Watch6,18 / n199ap), watchOS 26.6.1 (23U95).

**STATUS: NATIVE HERMÈS WATCH FACES NOT UNLOCKED.**

This research is performed on the matching offline ARM64_32 NanoTimeKit dynamic library; it does **not** perform jailbreak, privilege escalation, system writes, watchface installation, or cache rebuild. Device owner @ZhuoXuan-MY has expressly authorized further assessment of system-level methods on their own hardware, but permission does not supply Apple-private entitlements or a verified exploit. Any destructive step must depend on an independently established compatible write primitive and a recovery plan.

## Verified binary identity

`NanoTimeKit`: 11,395,800 bytes, SHA-256
`bf3f7e360fe06ab7e513807bcb3b6ac695f38c6ea8cd8428b7aed579c2b58e1c`.

Offline `llvm-objdump --macho --disassemble` confirmed exactly **two direct calls** to `0x55CE73DC` in this extracted NanoTimeKit text. Both occur after a face class has been reported restricted for the device:

```asm
; Bundle-ID lookup (faceBundleForBundleIdentifier:onDevice:forMigration:)
0x544B0F94  bl  _objc_msgSend$isRestrictedForDevice:
0x544B0F98  cbz w0, 0x544B0FA4
0x544B0F9C  bl  0x55CE73DC
0x544B0FA0  tbz w0, #0, 0x544B0FF0

; Legacy-style lookup (faceBundleForFaceStyle:onDevice:)
0x544B1164  bl  _objc_msgSend$isRestrictedForDevice:
0x544B1168  mov x21, x0
0x544B1170  cbz w21, 0x544B117C
0x544B1174  bl  0x55CE73DC
0x544B1178  cbz w0, 0x544B1188
0x544B1188  mov x19, #0x0 ; nil result on rejected branch
```

**Interpretation:** `0x55CE73DC` is an additional predicate that can affect restricted-face lookup. It **does not** show that ordinary production watches can make that predicate return true or that face addition would then succeed. The application still has separate availability, category, library-configuration and protected MobileGestalt restrictions.

## Distinguished from the V16 internal-build check

```asm
0x54601310 <_NTKInternalBuild>:
    b 0x55CE731C

0x546014EC <_NTKShowHardwareSpecificFaces>:
    bl 0x55CE731C
0x546014F0:
    cbz w0, 0x546015A4
```

`0x55CE731C` and `0x55CE73DC` differ by `0xC0` bytes, but their **relative address is not proof of shared semantics or identity**. `_os_variant_has_internal_ui` appears as an undefined external symbol in the extracted NanoTimeKit symbol table; the standalone extraction does **not** prove it corresponds to either particular branch destination. my V16 log measured `NTKInternalBuild=false`, `NTKShowHardwareSpecificFaces=false`, `NTKShowInternalFaces=false`. No write-based unlock follows from those values.

## Decisive next step — resolve BOTH addresses using the *already extracted* full shared cache

The shared cache remains on my Mac and was **not uploaded** with the small NanoTimeKit ZIP, so I cannot conclusively map the two addresses locally. No new OTA download or extraction is needed. Run read-only symbol lookups against the existing Watch6,18 / 23U95 cache:

```bash
ROOT="$HOME/Downloads/RO23-23U95-Static"
DSC="$ROOT/DSC/23U95__Watch6,18/System/Library/Caches/com.apple.dyld/dyld_shared_cache_arm64_32"

test -f "$DSC" || { echo "Matching shared cache not found"; exit 1; }

ipsw dyld a2s "$DSC" 0x55CE73DC -i
ipsw dyld a2s "$DSC" 0x55CE731C -i
```

Official `ipsw dyld a2s` usage: https://blacktop.github.io/ipsw/docs/cli/ipsw/dyld/a2s/

If symbol lookup cannot identify the function, request the same command's `-m` mapping, `ipsw dyld a2f`, or the matching cache image list to establish which cache binary owns it; do not label it speculatively.

## Research priorities once target is identified

1. Determine whether `0x55CE73DC` is a production-supported platform predicate, internal-only policy, or another special-case gate.
2. Determine whether any *legitimate ordinary* FaceBundle registration/add API satisfies its preconditions for 23U95; do not mistake the `forMigration:` exception for ordinary usage.
3. Keep evaluating reported watchOS 26 file-write primitives against real SystemGroup sandbox/entitlement behavior; `EPERM` was previously observed despite a consumed class-13 system-group token. Do not blindly write or rebuild the protected live cache.

**Neither a jailbreak nor an operational system write route has been demonstrated for this watch.**

[Upstream HermesEnabler](https://github.com/pookjw/HermesEnabler) · [Issue #17](https://github.com/pookjw/HermesEnabler/issues/17) · [V17 analysis](RO23-V17-FaceBundle-Loading-Chain.md).
