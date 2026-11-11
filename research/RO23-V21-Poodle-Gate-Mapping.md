# RO23 V21 — Confirmed Poodle target and conditional rejection path

**Date:** 2026-11-11 · **Device:** Watch6,18 / n199ap · watchOS 26.6.1 (23U95).  
**Status:** Hermès Circulaire `NTKPoodleFaceBundle` has **not** been enabled. This is a fresh cross-check of *two already-inspected primary sources*, not a live injection or a new watch run.

**Credit:** HermesEnabler by Jinwoo Kim (@pookjw), RO23 owner @ZhuoXuan-MY. See [V14 Zeus research](https://github.com/pookjw/HermesEnabler/issues/17), [V16](RO23-V16-InternalBuild-Gate.md), [V17](RO23-V17-FaceBundle-Loading-Chain.md) and [V20.1](RO23-V20-Watchface-Archive-Import.md).


> **Updated by V24 (2026-11-11):** I have now supplied the full 23U95 Zeus disassembly. The entire Poodle restriction function was reconstructed, and its outcome for observed Ultra 1 values is **RESTRICTED regardless of the unknown capability-call result**. The V21 conditional-only interpretation below is historical. See [V24 full gate analysis](RO23-V24-Poodle-Full-Gate.md).

## A. Important target-identity correction: secondary FaceBundle IDs

my **actual uploaded** `Hermès Circulaire(1).watchface` was validated in V20.1 (249,760 bytes, SHA-256 `d8364f574fbfcbf16a46d7ae07fbdf74267621a7f6ec2e7525e8018d2659fb03`). Its parsed `face.json` includes:

```json
{
  "bundle id": "com.apple.NTKPoodleFaceBundle",
  "analytics id": "poodle",
  "face type": "bundle",
  "forMigration": false
}
```

**V14 firmware evidence** on the *matching* 23U95 `NTKZeusFaceBundle` showed its `Info.plist` contains `NTKFaceBundle.LegacyStyles = [SpectrumZeus, ZeusAnalog]` **plus secondary bundle identifiers for Poodle, Hades, Secretariat, Bellona, and variants**. The observed method `+[NTKPoodleFace isRestrictedForDevice:]` is implemented **inside the shared Zeus executable**, at extracted Mach-O VM address **`0x13B4`**.

**Implication:** the file names a Poodle *face identifier*, but the relevant executable code is backed by `NTKZeusFaceBundle`. Failure to find a separate file named `NTKPoodleFaceBundle` would NOT prove Poodle is missing from the firmware. This also distinguishes it from the separately studied `NTKHermes2025FaceBundle`.

## B. Two separate category rules — do NOT conflate them

| Face family | Known category check | Consequence for my deviceCategory=4 |
|---|---|---|
| Hermès 2025 | whitelist `{2,3,5}` (V13 original firmware analysis) | **Fails known category gate** |
| Poodle / Hermès Circulaire | earlier `deviceCategory==1` exclusion is documented in V14; other early conditions not fully decoded | **Category=4 does not hit that particular category==1 rejection**; do NOT infer complete acceptance |

This is the new distinction: a **Poodle-specific** analysis must be based on `NTKPoodleFace` and Zeus code, not reuse the Hermes2025 category whitelist.

## C. Verified Poodle fallback branch (conditional)

V16 static analysis of the 663,040-byte matching `NTKZeusFaceBundle` (SHA-256 `2b34d3d411b77ee73f3892638f419eda83b7bedc4653ecf44adf7c975bbd72e4`) captured:

```asm
; +[NTKPoodleFace isRestrictedForDevice:] begins at 0x13B4
0x13F0  bl   0x43480  ; collectionType getter
0x13F4  cmp  w0, #5
0x13F8  b.ne 0x141C
0x13FC  mov  w20, #0 ; not restricted on this branch
...
0x141C  bl   0x340AC ; _NTKShowHardwareSpecificFaces
0x1420  eor  w20, w0, #1
```

On my real watch, V13/V14.1/V16 measured `collectionType=9` and `NTKShowHardwareSpecificFaces=false`:

```text
Reached comparison? (depends on earlier branches)
    YES + collectionType==5  => w20=0 on shown branch
    YES + collectionType!=5  => w20=NOT NTKShowHardwareSpecificFaces()
                               => NOT false = true = restricted

my observed properties: 9 and false => restricted ON THIS PATH.
```

**This is a definite value evaluation for the shown branch, but not a full-function proof.** The assembly between `0x13B4` and `0x13F0` and any early exits/other capability conditions still need the matching full disassembly before stating the whole function must return true. In particular, `deviceCategory=4` alone should **not** be reported as the Poodle category blocker.

## D. Registry and add-to-library are further independent gates

From V17 static NanoTimeKit disassembly:
- `enumerateFaceBundlesOnDevice:includingLegacy:withBlock:` filters `isRestrictedForDevice:`.
- `faceBundleForBundleIdentifier:onDevice:forMigration:` rechecks `isRestrictedForDevice:`, with an **unresolved exception stub at `0x55CE73DC`**; the earlier stub-symbol lookup reported `? (__TEXT_STUBS.)`. A stub's address is not the target function name.
- `_NTKCanAddWatchFace` also checks configuration, descriptor availability, and restriction.

The JSON `"forMigration": false` is **not proven** to be the value passed to the Objective-C `forMigration:` method argument. Even a registered Poodle class and syntactically valid .watchface ZIP do not prove successful installation.

## E. Read-only offline Poodle branch audit, no new watch app

A new **optional** `scripts/ro23-v21-poodle-disasm.sh` reads the **already extracted local** `NTKZeusFaceBundle` executable, checks its SHA-256, and asks LLVM to print **Poodle 0x13B4–0x1470**. This will expose the currently unresolved *earlier function branches* without touching watchOS, MobileGestalt, pairing, permissions, or Xcode. No firmware binaries are uploaded to public GitHub.

Example, with the existing real local extracted binary path (do not guess it; use the existing file):

```bash
cd "$HOME/Downloads/HermesEnabler-RO23-Live"
bash scripts/ro23-v21-poodle-disasm.sh "/actual/path/to/NTKZeusFaceBundle"
```

The script refuses an incorrect SHA-256. LLVM officially documents `--start-address` and `--stop-address` as disassembly-range filters: https://llvm.org/docs/CommandGuide/llvm-objdump.html

**Not yet verified:** this script has not run on my Mac, and the full Poodle prologue is not in the materials retrieved in this pass. Do not invent the outcomes of those branches.

## F. Decision / next material evidence

- **Verified:** uploaded Hermès Circulaire file points to Poodle; Poodle code is represented in the matching Zeus bundle; my known properties make the displayed fallback restricted if reached.
- **Not verified:** the full earlier Poodle branch, the stub `0x55CE73DC` target, the on-device `+[NTKPoodleFace isRestrictedForDevice:]` return, and successful native face installation.
- **Avoid:** changing `HandFactoryCachedBuild`, `UltraFaceWasAddedToLibrary`, iPhone serial-number replicas or protected MG caches; none has demonstrated an effect on the Poodle check.

**No new watch buttons. No new cloned Xcode directory. No protected or live system files were modified.**


## V23 — Apple otool fallback for missing llvm-objdump (owner Mac log, 2026-11-11)

I ran the V21 helper against the existing extracted **23U95 NTKZeusFaceBundle**. It **found the binary** and verified SHA-256:
\`2b34d3d411b77ee73f3892638f419eda83b7bedc4653ecf44adf7c975bbd72e4\`.
It then stopped with \`ERROR: llvm-objdump not found\`. Therefore **no Poodle disassembly output was obtained in that attempt**; this was a **missing local tool**, not a failed firmware match or a new watchOS security restriction.

The existing **same-path** \`scripts/ro23-v21-poodle-disasm.sh\` has now been upgraded to auto-detect \`llvm-objdump\` in PATH/Homebrew/Xcode, and otherwise use Apple's \`otool -arch arm64_32 -tvV\` with a Perl line filter for instruction addresses \`0x13B4 <= PC < 0x1470\`. This requires no Homebrew LLVM installation and uses my already installed Xcode tools when accessible.

**No binary modifications, watch code changes, system writes or new projects.** The new fallback is a code change reviewed in GitHub, **not yet executed on my Mac**.

To rerun without resetting the local project, pipe the current GitHub script to \`bash -s -- "$BIN"\` as already done. Once the full function body is printed, interpret the *actual early branch targets* rather than claiming in advance that a path will unlock a face.

Apple explains \`otool -tV\` disassembly in WWDC21's "Symbolication: Beyond the basics":
https://developer.apple.com/videos/play/wwdc2021/10211/
