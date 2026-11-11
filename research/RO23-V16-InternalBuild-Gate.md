# RO23 V16 — NanoTimeKit Internal-Build Gate and Legacy Zeus Review

**Date:** 2026-11-11 · **Target:** Watch6,18 / n199ap, watchOS 26.6.1, build 23U95

**Status: NATIVE HERMÈS FACES NOT UNLOCKED.** This report distinguishes static disassembly from my actual watch logs. Credit: HermesEnabler 2 © Jinwoo Kim (@pookjw); RO23 device research @ZhuoXuan-MY, AI-assisted static analysis.

## Source integrity

The matching Apple firmware's extracted `NanoTimeKit` dynamic library is ARM64_32 Mach-O, **11,395,800 bytes**, SHA-256:

`bf3f7e360fe06ab7e513807bcb3b6ac695f38c6ea8cd8428b7aed579c2b58e1c`.

The Zeus executable was extracted separately from the same build, **663,040 bytes**, SHA-256 `2b34d3d411b77ee73f3892638f419eda83b7bedc4653ecf44adf7c975bbd72e4`. Apple binaries are NOT redistributed.

## Verified static relationship: the previously unknown precondition has a named wrapper

```asm
0x54601310 <_NTKInternalBuild>:
  0x54601310   b   0x55CE731C

0x546013C4 <_NTKShowInternalFaces>:
  0x546013D0   bl  0x55CE731C
  0x546013D4   cbz w0, 0x54601404

0x546014DC <_NTKShowHardwareSpecificFaces>:
  0x546014EC   bl  0x55CE731C
  0x546014F0   cbz w0, 0x546015A4
  ...
  0x546015A4   mov w8, #0
  0x546015A8   and w0, w8, #1
```

The earlier V15 report left the target `0x55CE731C` unidentified. **V16 resolves its semantic wrapper**: the exported `_NTKInternalBuild` is itself only a tail-branch to that same implementation. This proves that both internal-face and hardware-specific-face switches share the return value of the internal-build check.

What this does NOT establish: the deeper callee's full implementation, what Apple uses to determine an “internal build,” whether a legitimate stock-device feature flag could alter that value, or the actual return value on this Ultra. **Do not claim the imported `_os_variant_has_internal_ui` is definitively that same address without the dyld shared-cache target mapping.**

The separate `ShowHardwareSpecificFaces` preference and notification strings exist, but the precondition is tested before accessing the associated preference/cached decision. Setting a preference alone therefore has **no demonstrated effect** when the precondition is false.

## Legacy Zeus Poodle/Bellona: not an easy workaround

The exact extracted Zeus restriction functions are at `0x13B4` (Poodle) and `0x21E80` (Bellona). Both first test device-category/other conditions and then:

```asm
Poodle:
  0x13F0  bl   0x43480    ; collectionType
  0x13F4  cmp  w0, #5
  0x13F8  b.ne 0x141C
  0x13FC  mov  w20, #0   ; unrestricted on this branch
  ...
  0x141C  bl   0x340AC   ; NTKShowHardwareSpecificFaces
  0x1420  eor  w20, w0, #1

Bellona:
  0x21ED4 bl   0x43480   ; collectionType
  0x21ED8 cmp  w0, #5
  0x21EDC b.ne 0x21F00
  0x21EE0 mov  w20, #0
  ...
  0x21F00 bl   0x340AC   ; NTKShowHardwareSpecificFaces
  0x21F04 eor  w20, w0, #1
```

Thus **if** a Poodle/Bellona device passes their earlier conditions, then with the actual Ultra 1 `collectionType=9` and `NTKShowHardwareSpecificFaces=false`, their fallback restriction returns true. Earlier checks may independently reject even sooner. This is a strong indication, not a dynamic load trace or proof that no conceivable alternative face exists.

## RO23 V16 on-watch diagnostic (new; NOT YET RUN)

Xcode watch app > RO23 Research > **V16 · Internal-build gate**.

The diagnostic invokes the exported private NanoTimeKit symbols read-only and records:
- `NTKInternalBuild=true/false/unavailable`
- `NTKShowHardwareSpecificFaces=true/false/unavailable`
- `NTKShowInternalFaces=true/false/unavailable`

Interpretation: if `NTKInternalBuild=false`, the assembly short-circuits the other two flags regardless of the later stored setting. If `true` but the hardware-face predicate remains false, later preferences/cached state are implicated, but the exact internal rules are not yet established. An unavailable symbol is reported rather than inventing a Boolean.

**Safety:** No cache write, preference edit, symbol hook, bundle injection, face installation, system service restart, or entitlement request. The only file change is an app-owned diagnostic log. It only runs when me taps the button.

## Remaining work

1. User validates V16 once on the **same 23U95 build**, reporting the three values. No need to repeat V13/V14.1/MG snapshots.
2. If useful, perform further offline mapping of the external `0x55CE731C` implementation in the full dyld shared cache to distinguish build-type/variant policies.
3. The demonstrated `EPERM` protected MG write restriction and Hermès2025 category mismatch remain unchanged. **There is no verified stock Ultra 1 native Hermès unlock yet.**

[Upstream](https://github.com/pookjw/HermesEnabler) · [Issue #17](https://github.com/pookjw/HermesEnabler/issues/17).


## V16.1 actual on-device result — 2026-11-11

me has now built and run V16 on the same **Watch6,18 / watchOS 26.6.1 / 23U95** device. Exact app-owned log values:

```text
[bqtool] RO23 RO23 V16 — NanoTimeKit internal-build gate (read only)
Build=23U95
NTKInternalBuild=false
Static inference: internal-build early return prevents the hardware-face setting check.
NTKShowHardwareSpecificFaces=false
NTKShowInternalFaces=false
No preferences changed; no face loaded; no protected writes.
RO23 V16 END systemWrites=NO
```

**Evidence level: device observation.** The internal-build predicate was dynamically called and returned `false`; both downstream visibility predicates returned `false`. Coupled with the previously verified `cbz` branch, this confirms the *specific* short-circuit applies to the running watch build. It is more than a guess about the existence of a setting, but it does **not** prove that every Hermès face relies on this same flag.

**Research impact:** simply adding a user preference named `ShowHardwareSpecificFaces` is not a demonstrated way to enable Zeus on this device, because the internal-build check short-circuits the logic. No more watch-side repeats of V13/V14/V16 are needed. Future analysis should focus on the independent, publicly reachable NanoTimeKit FaceBundle eligibility/registration path and any *supported* device capability APIs. The earlier system-group `EPERM` and Hermès2025 `deviceCategory=4` mismatch remain independent blockers.

No native Hermès face has been installed or enabled; no protected modifications were performed by the diagnostic.
