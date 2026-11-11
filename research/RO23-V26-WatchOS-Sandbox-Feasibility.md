# RO23 V26 — Watch sandbox-escape feasibility: worse_query vs 23U95

**Research date:** 2026-11-11 (北京时间 UTC+08:00).  
**Target:** my Apple Watch Ultra 1 (Watch6,18 / n199ap), watchOS 26.6.1 build 23U95.  
**Status:** **No verified sandbox escape / protected cache write / Hermès activation on 23U95**.

## Why this branch is worth investigating

I requested research beyond the already proven Poodle normal eligibility gate and asked whether a newly discussed *sandbox escape* should be tested.

Two independently reviewed public repositories now matter:

1. [forcequitOS/worse_query](https://github.com/forcequitOS/worse_query) (GPL-3.0). Official README claims **iOS 26.0–26.7.2 / 27.2**; an App Group is necessary; the author explicitly says it is **not a jailbreak** and lists privileged `SystemGroup` access only for **iOS 27**. This is an **iOS** PoC, not proof of watchOS 26 compatibility.
2. [LogicSense1/WatchRegion](https://github.com/LogicSense1/WatchRegion) (GPL-3.0-or-later). Unlike the iOS-only upstream project, its source has **`SDKROOT = watchos`**, **`TARGETED_DEVICE_FAMILY = 4`** and **`WATCHOS_DEPLOYMENT_TARGET = 27.0`**. Its author reports a test on an **Apple Watch Ultra 4, watchOS 27.3 beta, build 24S5284h**. This statement is from the maintainer, not an independent Watch6,18 / 23U95 test.

## Verified compatibility matrix

| Question | WatchRegion/worse_query observed source | RO23 Ultra 1 / 23U95 | Conclusion |
|---|---|---|---|
| OS and device | watchOS 27.0 minimum; author reported Ultra 4 / 27.3 beta | Ultra 1 / 26.6.1 / 23U95 | **Not the same build or hardware**; WatchRegion cannot be installed unmodified on 26.6.1 |
| Signing | WatchRegion `com.apple.security.application-groups` key uses `$(WATCH_REGION_APP_GROUP)` | Checked `HermesEnabler2/HermesEnabler2.entitlements`: empty `<dict/>` | RO23 does **not** carry the dedicated App Group entitlement required for this primitive |
| Sandbox behavior | Upstream `worse_query` returns/consumes container sandbox extensions; requires an App Group and uses its `Library/Caches` directory | Previous Class-13 sandbox extension was obtained/consumed | Extensions being consumed **did not** previously supply protected write permission |
| Real writes | WatchRegion `RegionCache.swift` calls `worse_query` then opens MobileGestalt plist `O_RDWR` and uses `pwrite`; it can roll back on errors | Historical protected MG `O_RDWR` attempt returned `EPERM` | The code demonstrates an intended *write attempt*, **not** a successful write on this watch |
| Targeted MG properties | WatchRegion modifies *sales region* metadata, not Poodle's observed `deviceCategory=4`, `collectionType=9`, `NTKShowHardwareSpecificFaces=false` | Poodle function is completely decoded in V25 | Even a successful region edit would **not** by itself unlock Hermès Circulaire |
| License / integration | `worse_query` and WatchRegion sources are GPL-3.0 | RO23 derives from MIT-licensed HermesEnabler | Do **not** paste GPL implementation into the existing repo without deliberate license/compliance review |

### Actual code evidence and risk

**WatchRegion** `WatchRegion/RegionCache.swift` has `withRegionCache(group:)` which calls `worse_query(directory, group, false, false)`. Its implementation later performs `open(target.path, O_RDWR | O_CLOEXEC | O_NOFOLLOW)` and `pwrite`. The upstream **worse_query** code uses a symlink-based technique and may remove/recreate the dedicated App Group's `Library/Caches` directory even when used to obtain read access. Thus, **executing its PoC is not a guaranteed read-only operation**, and it must not be run against the existing RO23 app group or live system files without an isolated test and recovery plan.

Both `worse_query` and `WatchRegion` are third-party demonstrations. The only proven 23U95 MobileGestalt write outcome remains `EPERM`. Do not claim that a newer watchOS 27 test invalidates this measured 26.6.1 result.

## Decision on trying it

**GO**: continue a **source-only/offline** compatibility audit in the existing repository, checking library availability and selector/symbol presence in the already extracted 23U95 firmware, plus entitlement/signing feasibility. The focus is **sandbox primitive portability**, *not* normal Poodle eligibility reruns.

**NO-GO for now**: install the WatchRegion release IPA unchanged on the main Ultra 1 (its minimum watchOS is 27.0); grant unsafe or incorrect entitlements; run automatic modifications; replace the MobileGestalt file, alter Poodle category/collection values, or force respring based only on another model's test.

**Conditions for any future device-side experiment:** a verified watchOS 26-specific build and signing route with an isolated test App Group, test that does not write protected files, complete backup and recovery, and explicit separation from the primary RO23 watch app. No such verified build or result is available yet.

## Other independent research path

The already known `NanoTimeKit` `0x55CE73DC` restricted-face exception is **still unresolved**, but it belongs to a separate FaceBundleManager branch. It cannot be assumed to be affected by an iOS sandbox escape. Continue researching it through the matching 23U95 shared cache, not by repeating V13–V25 status buttons.

**No watch App code has been changed in V26. No exploit ran on my watch. No protected file was written or face installed.**

References: [worse_query](https://github.com/forcequitOS/worse_query) · [WatchRegion](https://github.com/LogicSense1/WatchRegion) · [V17 manager](RO23-V17-FaceBundle-Loading-Chain.md) · [V25 Poodle gate](RO23-V25-Poodle-Selector-ClockKit.md).
