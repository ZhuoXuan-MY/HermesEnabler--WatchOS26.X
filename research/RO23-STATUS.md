# RO23 investigation: current evidence on Watch6,18 / 23U95

**NOT UNLOCKED.** Native Hermès faces are not activated on the user's stock Ultra 1.

Original app: [Jinwoo Kim / @pookjw](https://github.com/pookjw/HermesEnabler), MIT license. Field research and issue logs: [@ZhuoXuan-MY](https://github.com/pookjw/HermesEnabler/issues/17), with AI-assisted analysis.

| Stage | Confirmed observation |
|---|---|
| V1–V4 | Protected MobileGestalt cache readable; direct write-open denied EPERM. Correct DeviceBrand descriptor index 103, value offset 0x338, valid offset 0x164F. Prior 206/0x670 was wrong. |
| V5–V7 | Class-13 sandbox token did not grant protected writes. MobileGestaltHelper XPC queries returned error 9; do not equate this alone with entitlement denial. |
| V8–V9 | Matching 23U95 OTA, arm64_32 MobileGestaltHelper and libMobileGestalt analyzed offline. Do not call live MGRebuildCache. |
| V10–V12 | Native Hermes2025FaceBundle, NanoTimeKit, ClockKit found; bundle's category restriction studied. |
| V13 | Real Ultra 1 log: sizeClass 6, deviceCategory 4, collectionType 9, deviceBrand 0, isUltra true; Hermes2025 category whitelist {2,3,5} FAIL. |
| V14 | Real Ultra 1 log: isZeusBlack false and NTKShowHardwareSpecificFaces false; Zeus Analog/Spectrum and Hades/Secretariat studied gates RESTRICTED. |
| V14.1 | Fixed false number 399803152: deviceBrand was an ObjC object pointer, not an integer. |

All current active RO23 UI probes are **read-only**, manually invoked, and report to app-owned logs. No native face bundle was loaded or installed by these diagnostics. This is not a tested unlock.

**Current merged Xcode design:** the latest upstream code is the functional base; a separate RO23Diagnostics.m/.h and RO23ResearchView.swift hold the probes. On 23U95 the landing UI hides upstream feature-changing controls and allows the research screen without requiring MG backup. Older V1–V7 code is archived as text (not compiled).

Sources: [Issue #17](https://github.com/pookjw/HermesEnabler/issues/17), [Issue #7](https://github.com/pookjw/HermesEnabler/issues/7), V8/V9 reports and other notes in this folder.
