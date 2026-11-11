# RO23 V22 — On-device Poodle eligibility checkpoint (read-only)

**Date:** 2026-11-11 · **Target:** Apple Watch Ultra 1 / Watch6,18 / watchOS 26.6.1 (23U95)

**Goal:** Turn earlier V16/V21 inferences into a clearly classified, one-tap, Poodle-specific watch report. Actual V22 watch measurements are **not yet received**. Native Hermès faces remain **not unlocked**.

## What changed in the existing watch app

- `RO23Diagnostics.m/.h` now implement/expose `RO23V22PoodleReport()`.
- `ContentView.swift` (watch **home screen**, not merely a hidden detail page) prominently displays **`RO23 V22 · read-only diagnostics`** and a **`V22 · Poodle eligibility`** button.
- `RO23ResearchView.swift` includes the same diagnostic inside the secondary diagnostics list.
- The new check runs **only after a tap**, **only evaluates target-specific behavior on 23U95**, never loads `NTKZeusFaceBundle`, installs a face, modifies MobileGestalt, changes preferences, or requests elevated entitlements. Normal app-owned logs are written by the existing `Done()` helper.

## Why these particular outputs matter

| Output | Evidence type | Interpretation |
|---|---|---|
| `ArchiveBundleID=com.apple.NTKPoodleFaceBundle` | **Previously verified V20.1 file** | Actual face.json bundle identifier, not proof of eligibility |
| `deviceCategory`, `collectionType` | **Live watch getters** | Rejects guessing from the iPhone's serial-number copy |
| `NTKInternalBuild`, `NTKShowHardwareSpecificFaces` | **Live NanoTimeKit exports** | Independently confirms whether V16's relevant predicates remain unchanged |
| `Poodle known category==1 exclusion` | **Conditional static model** | Poodle's category test is **not** identical to Hermes2025's {2,3,5} whitelist |
| `Poodle known fallback if reached` | **Static model combined with live values** | A true restricted result is **conditional on reaching the shown branch** in Zeus |
| `NTKPoodleFace registered in this process` | **Live runtime inspection** | Class may remain absent because its private FaceBundle is not loaded in this app |
| `NTKPoodleFace.isRestrictedForDevice(actual in-process)` | **Real class method, only if already registered** | Read the private class's original result without attempting to load the bundle |
| `...unavailable (class/method not registered)` | **Absence of measurement** | Does not establish the bundle is missing from watchOS, or that Poodle is unrestricted |

The private `isRestrictedForDevice:` is only called when `NTKPoodleFace` is **already registered** in the current process and responds to the method. It is **not injected**, and the class is never force-loaded. Its behavior on the user's watch **cannot be asserted before testing**. If it is unavailable, we still get the measured device/predicate results, and existing offline V21 disassembly remains the appropriate way to inspect earlier branches.

## Expected comparison with prior real logs (not a prediction of V22 output)

Earlier independent read-only tests found:

```text
Build=23U95
deviceCategory=4
collectionType=9
NTKInternalBuild=false
NTKShowHardwareSpecificFaces=false
```

If the new run reproduces these values, the **previously identified conditional Poodle fallback** evaluates `RESTRICTED`, but the **actual full-function result** is only known if the class was already loaded and the original private method can be invoked. The separate `forMigration:` bypass and any remaining eligibility checks are unchanged and unresolved.

## Build / test boundaries

This is an **actual source-code change**, unlike docs-only V17–V21. It requires one normal update of the **same local Git checkout** followed by Xcode watch build/install; GitHub cannot automatically install it on the watch.

No Apple Watch was available in the remote GitHub editing environment. **Compilation, signing, and runtime are unverified until the owner runs them.**

To verify the correct source is open, inspect the main Watch App `ContentView.swift` for `RO23 V22 · read-only diagnostics` and `V22 · Poodle eligibility` before building. Do not create or clone additional projects.

[Upstream HermesEnabler](https://github.com/pookjw/HermesEnabler) · [V20.1 archive](RO23-V20-Watchface-Archive-Import.md) · [V21 conditional branch](RO23-V21-Poodle-Gate-Mapping.md).
