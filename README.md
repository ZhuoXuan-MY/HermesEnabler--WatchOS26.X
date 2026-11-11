# HermesEnabler RO23

*Apple Watch Ultra (1st generation) · watchOS 26.6.1 · build 23U95*

[简体中文](README.zh-CN.md) · [Original HermesEnabler](https://github.com/pookjw/HermesEnabler) · [Research discussion — Issue #17](https://github.com/pookjw/HermesEnabler/issues/17)

> **Work in progress — this does not unlock Hermès watch faces on watchOS 26.6.1.**
>
> RO23 is my independent research fork of Jinwoo Kim's HermesEnabler. I'm sharing the tests, the code I used to investigate the problem, and what I've been able to verify so far. There is **no confirmed native Hermès face activation**, no tested 23U95 unlock IPA, and no claim that the original developer supports this fork.

## Contents

1. [Why I started RO23](#1-why-i-started-ro23)
2. [Where this project comes from](#2-where-this-project-comes-from)
3. [The watch and the results so far](#3-the-watch-and-the-results-so-far)
4. [What's in this repository](#4-whats-in-this-repository)
5. [RO23 V1–V12: the investigation](#5-ro23-v1v12-the-investigation)
6. [The DeviceBrand offset mistake](#6-the-devicebrand-offset-mistake)
7. [Why MobileGestaltHelper returned error 9](#7-why-mobilegestalthelper-returned-error-9)
8. [The Hermès 2025 face is in the firmware — so what's stopping it?](#8-the-hermès-2025-face-is-in-the-firmware--so-whats-stopping-it)
9. [What V12 told us about ClockKit](#9-what-v12-told-us-about-clockkit)
10. [What we know and what we don't](#10-what-we-know-and-what-we-dont)
11. [Opening the project in Xcode](#11-opening-the-project-in-xcode)
12. [Research files and checksums](#12-research-files-and-checksums)
13. [Where I'm going next](#13-where-im-going-next)
14. [Credits and license](#14-credits-and-license)
15. [Useful links and a final note](#15-useful-links-and-a-final-note)

## 1. Why I started RO23

I wanted to find out whether a **first-generation Apple Watch Ultra** could use Apple's native Hermès watch faces on **watchOS 26.6.1 (23U95)**, and, if not, what was actually preventing it.

At first, the obvious place to look was `MobileGestalt` and its `DeviceBrand` value. That led to a much bigger question. Even if the cache could be read and its format understood, would changing one value be enough? Would the system allow the change? And would NanoTimeKit and the Hermès face bundle accept the device afterward?

I started testing those pieces one by one, first on the watch and then against binaries extracted from the **matching 23U95 firmware**. This README is a record of that work through **RO23 V12**.

I'm interested in understanding the restrictions, not passing off a partial experiment as a finished tool. If you're here looking for a one-click unlock, **this project isn't there yet**.

## 2. Where this project comes from

The original app is **[HermesEnabler / HermesEnabler 2](https://github.com/pookjw/HermesEnabler)**, created by **[Jinwoo Kim (@pookjw)](https://github.com/pookjw)**. The original application, its architecture, existing UI, MobileGestalt work, backup/restore foundation, and upstream dependencies are his work. Please credit him if you reuse it.

RO23 is the name I've used for my own modifications and research on the Ultra 1. I ran the watch tests, worked with Xcode and the firmware files, collected logs, and documented the findings in [upstream Issue #17](https://github.com/pookjw/HermesEnabler/issues/17). I also used AI tools to help with experimental code, commands, and analysis notes; the successful and failed device tests described here come from the actual watch, not a simulation.

I keep this as a separate repository because **23U95 is outside the supported scope being claimed for the upstream project**. Nothing here should be read as a statement from, or an endorsement by, the original author.

This fork is also **not** an Apple or Hermès project, a jailbreak, a verified entitlement bypass, or a working watchOS 26.6.1 unlock.

## 3. The watch and the results so far

All the on-device results below refer to **one specific setup**:

| Item | Details |
|---|---|
| Watch | Apple Watch Ultra, first generation |
| Model identifier | `Watch6,18` |
| Board | `n199ap` |
| OS | watchOS `26.6.1` |
| Build | `23U95` |
| Architecture | `arm64_32` (ILP32) |
| Test environment | Locally modified HermesEnabler2, Xcode development signing, custom App Group |
| Reading MobileGestalt | Worked |
| Backing up and parsing the cache | Worked |
| Writing to the protected cache | Blocked with `EPERM` |
| Class 13 sandbox extension | Token obtained and consumed; still no write permission |
| MobileGestaltHelper XPC | Connected and replied, but tested queries returned `error=9` |
| Native Hermès 2025 bundle | Found in the matching OTA |
| Actual native Hermès face activation | **Not achieved** |

These aren't universal results for every Apple Watch. A finding from a Series 8, another watchOS build, or an iOS binary can be useful background, but it doesn't count as a successful Ultra 1 test.

## 4. What's in this repository

There's an important distinction between **my older local experiments** and **the public research source**.

The original local archive used during the investigation included experimental paths for MCM access, a forced MobileGestalt write attempt, and diagnostics that ran automatically after launch. One of those old paths, `BQWriteHermes23U95()`, contained **incorrect DeviceBrand offsets**. That experiment is part of the history below, not something I want anyone to treat as a working method.

The public source is the **sanitized, research-only version**: the historical forced writer has been removed; MobileGestalt save/restore and face-enabling operations are blocked; and the RO23 diagnostics are started from an explicit button rather than automatically. The app also labels itself as research-only.

The code still includes useful parts of the original application and diagnostic work, including:

- Reading MobileGestalt information and making an **app-local** backup when permitted.
- Compatibility and cache-access checks.
- Read-only RO23 probes covering cache records, sandbox permissions, and MobileGestaltHelper queries.
- Logging to the app's own Documents directory.

**This public package has not been verified by a fresh on-watch build and test.** You'll need to review and sign it yourself. The historical measurements in this README are from the earlier locally modified build, not proof that this GitHub snapshot performs every old experiment unchanged.

## 5. RO23 V1–V12: the investigation

This is the path I followed, including the dead ends. I have left the unsuccessful results in because they're just as useful as the parts that worked.

### Before V1 — reading the cache and trying to open it for writing

The first local build could read the live MobileGestalt plist and create a matching backup. The data on 23U95 looked like this:

```text
Plist size:            13,328 bytes
CacheUUID:             3BE19A76-F253-4CE4-AAC1-DF6D801CAAB1
CacheData:             6,309 bytes (0x18A5)
Cache layout:          701 slots × 9 bytes
CacheExtra:            72 entries
Local DeviceBrand:     0
```

I also had a backup from watchOS 26.5, but its UUID and size were different. **I did not restore that older backup to 23U95.** Instead, I kept a verified `OriginalGestalt-23U95.plist` backup.

An early attempt used a supposed DeviceBrand record at index `206`. That later turned out to be wrong. On the watch, the write attempt stopped before any data could be written:

```text
MG FORCE: entering 23U95 write path
MG FORCE: 23U95 backup verified
MG FORCE: WRITE DENIED errno=1 (Operation not permitted)
```

The protected file could not be opened with writable access, so execution **never reached `pwrite`**. Three Class 7 flag combinations (`0x0800000000`, `0x8000000000`, `0x8100000000`) also failed to return usable sandbox tokens. The Geod-MCM Class 12 route didn't provide the required container object.

### V1 — looking for DeviceBrand inside MobileGestalt

I inspected mapped `libMobileGestalt.dylib` sections on the watch, looking for the hashed key:

```text
DeviceBrand → fuKL2rMywRgQF1wowOA/cg
```

I found relevant strings and pointer references, but I initially matched DeviceBrand to the **end of the preceding descriptor**. That mistake matters because it affected the first offset calculation.

### V2 — checking the value returned by the real API

I used the two-argument `MGCopyAnswer(CFStringRef, CFDictionaryRef)` call to query both `DeviceBrand` and its hashed form. Both gave a **CFNumber containing 0**.

One detail worth keeping straight: a Core Foundation number type isn't the same thing as MobileGestalt's internal descriptor type. Treating them as interchangeable leads to bad conclusions.

### V3 — fixing the descriptor boundary

Rechecking the `arm64_32` layout showed a descriptor stride of **100 bytes (`0x64`)**. The actual DeviceBrand record was:

```text
flags                 12 (0x0C)
index                 103
internal type         5
value offset          0x338
validity offset       0x164F
cached value          0
validity              1
```

The older `index=206` / `0x670` / `0x16B6` interpretation belonged to a different descriptor. This correction is one of the clearest concrete outcomes of RO23.

### V4 — a sandbox token didn't grant write access

A Class 13 MCM request with flags `0x0800000000` returned a sandbox extension. I consumed it successfully; one run reported `handle=2`. I then compared access before and after:

| Sandbox check | Before | After |
|---|---|---|
| MobileGestalt file read | Allow | Allow |
| MobileGestalt file write | Deny | Deny |
| MobileGestalt file creation | Deny | Deny |

The process had its ordinary application-groups entitlement, but not the Apple-private system-group entitlements being investigated. A separate metadata check returned `-1`, which is an **error**, not a reliable policy verdict.

No system-cache write happened in V4.

### V5 — finding the Mach service

`task_get_special_port` and `bootstrap_look_up` found `com.apple.mobilegestalt.xpc` (`kr=0`). That confirmed the service could be reached, **not** that it would authorize the requests I wanted to test.

### V6 — the first Helper reply

An `NSXPCConnection` to MobileGestaltHelper was established. A read-only `getServerAnswerForQuestion:reply:` request for `DeviceBrand` came back with:

```text
{ "error": 9 }
```

There was no `answer`. I did not call cache rebuilding or any cache-writing operation.

### V7 — checking whether it was only DeviceBrand

I repeated the comparison for four questions:

| Question | Local `MGCopyAnswer` | Helper XPC |
|---|---|---|
| `DeviceBrand` | `CFNumber(0)` | `error=9` |
| `fuKL2rMywRgQF1wowOA/cg` | `CFNumber(0)` | `error=9` |
| `BuildVersion` | String returned | `error=9` |
| `ProductType` | String returned | `error=9` |

Every Helper reply had only the `error` field. The number 9 here is a **MobileGestalt server result**; it shouldn't be confused with POSIX `EPERM` or a Mach/bootstrap error.

### V8 — extracting the matching MobileGestaltHelper

I downloaded the watchOS OTA matching `Watch6,18 / n199ap / 23U95`, checked its metadata and `post.bom`, then extracted `MobileGestaltHelper` from `payload.054`.

The binary was **76,112 bytes**, Mach-O `arm64_32`. Some tools struggled with its ABI or Objective-C metadata, so I used LLVM and direct Mach-O inspection to continue.

| Method | Address in the analyzed binary |
|---|---|
| `getServerAnswerForQuestion:reply:` | `0x5110` |
| `rebuildCache:` | `0x55F0` |
| `setCacheSentinel:` | `0x5714` |

At `0x51C4`, the Helper calls `_MGServerCopyAnswerWithError`. This gave me a concrete place to look for the error-9 behavior.

I **did not call `rebuildCache:`**. Finding a method is not evidence that it can set DeviceBrand, and rebuilding the live cache would be a different, potentially disruptive operation.

### V9 — checking libMobileGestalt itself

I extracted the matching `libMobileGestalt.dylib` (**991,764 bytes**) from the watchOS dyld cache. In that binary, `_MGServerCopyAnswerWithError` was located at `0x215B42A8` and a server access check at `0x215B4BF4`.

The descriptors I checked were:

| Key | Index | Internal type | Flags |
|---|---:|---:|---:|
| `DeviceBrand` | 103 | 5 | `0x0C` |
| `BuildVersion` | 62 | 9 | `0x0C` |
| `ProductType` | 530 | 9 | `0x0C` |

There are explicit error-9 paths in the server function. Together with the descriptor flags, they give a **plausible code-level explanation** for V7: a question can work through local `MGCopyAnswer` without being available through the Helper's server-facing API. I did **not** trace every V7 request dynamically through the Helper.

Another useful clue: the DeviceBrand provider in the matching library references `IODeviceTree:/chosen` and `marketing-software-behavior`. The cache isn't necessarily the whole story.

### V10 — finding Apple's own Hermès 2025 bundle

The matching firmware contains the native face bundle and related components:

| Component | Approximate size |
|---|---:|
| `NTKHermes2025FaceBundle` executable | 1.2 MB |
| Hermès bundle `Assets.car` | 32 KB |
| `Carousel` | 185 KB |
| `ClockFace` | 406 KB |
| `nanotimekitd` | 734 KB |

In `nanotimekitd` I found `com.apple.Hermes2025Face`, `_NTKFaceStyleIsAvailable` and strings associated with removing unavailable faces. A general face-availability filter appears at a static call site around `0x8260`.

The important finding was **that the bundle exists in this OTA**. That alone says nothing about whether the Ultra 1 is allowed to show it.

### V11 — finding a Hermès-specific restriction

The matching NanoTimeKit framework binary was **11,395,800 bytes**. Relevant locations included:

```text
_NTKFaceStyleIsAvailable                               0x544392B0
-[NTKFaceDescriptor isAvailableForDevice:]             0x543D998C
-[NTKFaceBundleManager faceBundleForBundleIdentifier:onDevice:forMigration:]
                                                        0x544B0DDC
```

Inside the Hermès 2025 bundle, `+[Hermes2025Face isRestrictedForDevice:]` appeared at `0x3B2C`, with related logic near `0x46B8`. The code references `deviceCategory`, `supportsFall2025FacesCapability` and `collectionType`, including a comparison against `0x5`.

That means there are **additional face-specific checks** to understand. I hadn't yet measured those selector values on the Ultra, so I couldn't conclude that changing DeviceBrand would be sufficient.

### V12 — checking ClockKit against the same build

The `RO23-V12-ClockKit.zip` material contained a **1,425,840-byte `arm64_32` ClockKit binary**. I checked the getters for several `CLKDevice` fields:

```asm
-[CLKDevice deviceBrand]      0x49C6F144: ldr  w0, [x0, #0x3c]
-[CLKDevice deviceCategory]   0x49C30EB4: ldr  w0, [x0, #0x2c]
-[CLKDevice collectionType]   0x49C354F0: ldr  w0, [x0, #0x30]
-[CLKDevice isUltra]          0x49C6F11C: ldrb w0, [x0, #0x17]
```

ClockKit also contains device-loading code and NanoRegistry/PDR capability processing. I did **not** find a direct definition of `supportsFall2025FacesCapability` in this particular ClockKit binary.

V12 clarified the shape of the problem, but it did not solve it: **these are distinct fields, and their actual runtime values and dependencies still need to be checked**.

## 6. The DeviceBrand offset mistake

Because this was an important correction, here's the final cache record in one place. It is specific to the analyzed **23U95 / arm64_32** environment:

```text
Key/hash:              DeviceBrand / fuKL2rMywRgQF1wowOA/cg
CacheData:             6309 bytes = 701 × 9
Descriptor stride:     100 bytes
Descriptor flags:      12
Descriptor index:      103
Internal type:         5
Value offset:          103 × 8 = 0x338
Validity offset:       (701 × 8) + 103 = 0x164F
Observed value:        0
Observed validity:     1
```

**The old `0x670` and `0x16B6` offsets are not DeviceBrand offsets.** They resulted from reading the wrong descriptor boundary. Both locations happened to contain zero in the earlier data, which made the mistake easier to miss.

Getting the record right doesn't grant permission to edit the protected cache. And even if it could be changed, the face-specific checks found in V11 would still need to be understood.

## 7. Why MobileGestaltHelper returned error 9

The short version:

```text
Local MGCopyAnswer(DeviceBrand)       → CFNumber(0)
MobileGestaltHelper XPC query         → { "error": 9 }
```

V8 showed that MobileGestaltHelper uses `_MGServerCopyAnswerWithError`. V9 then found error-9 handling and server access checks in the **matching watchOS library**. The local read API and the Helper's server API do not necessarily expose the same questions.

That is consistent with all four failed Helper queries in V7. It's a strong explanation, but not a claim that I dynamically traced the exact branch for each query.

Most importantly, **a successful XPC connection is not writable MobileGestalt access**. Neither the service lookup nor the Helper's existence provides a proven DeviceBrand setter.

## 8. The Hermès 2025 face is in the firmware — so what's stopping it?

The OTA contains the following native files and related resources:

```text
System/Library/NanoTimeKit/FaceBundles/
  NTKHermes2025FaceBundle.bundle/
    NTKHermes2025FaceBundle
    Info.plist
    Assets.car
    hermes-*.plist
System/Library/PrivateFrameworks/NanoTimeKit.framework/
  nanotimekitd
System/Library/CoreServices/Carousel.app/Carousel
Applications/ClockFace.app/ClockFace
```

From the static work in V10 and V11, the checks appear to involve more than one stage:

1. The face has to be available in the catalog.
2. NanoTimeKit must accept its style and descriptor for this device.
3. The Hermès bundle runs its own `isRestrictedForDevice:` logic.
4. Device category, collection type and Fall 2025 face capability may all matter.
5. Passing those checks still wouldn't, by itself, prove that the face can be added and used normally.

This is an interpretation of the inspected code, **not** a complete runtime trace on my Ultra. Apple's inclusion of a binary in the OTA doesn't mean every watch shipping that OTA is entitled to use the feature.

## 9. What V12 told us about ClockKit

Before V12, it was tempting to think of the restriction as a single DeviceBrand switch. ClockKit gave a good reason not to do that.

A `CLKDevice` has separate storage for `deviceBrand`, `deviceCategory`, `collectionType` and `isUltra`. The extracted getters establish that separation. What they don't establish is **where the values originally come from on this Ultra**, or precisely how the Hermès bundle interprets them.

That's why the next useful experiment is a **read-only measurement of the device's real capability values**, followed by more analysis of `supportsFall2025FacesCapability`. Guessing at cache edits would skip over the unanswered part.

## 10. What we know and what we don't

| Area | Status |
|---|---|
| Read and back up the live MG cache | **Verified on watch** |
| Correct DeviceBrand descriptor | **Corrected and corroborated** |
| Open the protected MG cache for writing | **Denied (`EPERM`)** |
| Class 7 / Geod-MCM alternatives | **Didn't provide usable access** |
| Obtain a Class 13 extension | **Yes, but no write permission** |
| Connect to MobileGestaltHelper | **Yes** |
| Obtain answers for tested Helper questions | **No — `error=9`** |
| Explain error 9 from matching binaries | **Supported by static analysis** |
| Find native Hermès 2025 bundle | **Yes** |
| Locate general and Hermès-specific restrictions | **Yes, statically** |
| Identify ClockKit device fields | **Yes** |
| Measure the Ultra's relevant runtime capability values | **Not yet** |
| Activate and use genuine native Hermès faces | **Not achieved** |

I don't want to blur these categories. **An on-watch observation**, **a finding in a firmware binary**, and **a hypothesis about how the pieces connect** are different types of evidence.

## 11. Opening the project in Xcode

This repository is intended for people who want to **inspect or continue the research**, not people expecting a prebuilt unlock.

You'll need a Mac, a suitable Xcode/watchOS SDK, a paired Apple Watch for any device testing, and your own development-signing setup.

1. Clone or download this repository.
2. Open `HermesEnabler2.xcodeproj`.
3. Review the source, entitlements, Bundle ID, App Group and signing settings for your own environment.
4. Build with your own signing team if your setup supports it.
5. Use the **explicitly triggered, read-only diagnostics** and inspect logs in the app's Documents directory.

The main areas involved are:

```text
HermesEnabler2.xcodeproj/
HermesEnabler2/
  BQCore.m                  Core functions and research diagnostics
  BQCore.h                  Exposed interfaces
  ContentView.swift         Watch UI and diagnostic buttons
  HermesEnabler2App.swift
  HermesEnabler2.entitlements
  Gester-LICENSE.txt
LICENSE
NOTICE.md
README.md
README.zh-CN.md
```

An ordinary development certificate or App Group does **not** supply Apple-private system-group permissions. Do not treat old local write experiments, a backup file, or upstream IPA instructions as a working 23U95 activation procedure.

**I haven't confirmed that the public research snapshot builds and runs successfully on a watch as published.** If you build it, please report the exact device/build and what you actually observed.

## 12. Research files and checksums

A lot of the later investigation depended on looking at the **correct firmware binaries**, rather than borrowing assumptions from other OS versions.

These SHA-256 hashes identify the research inputs I worked with:

| Input | SHA-256 |
|---|---|
| Downloaded full OTA `.aea` | `8c04028c94a26eafc96e2dc50cf5c5296834ca30e0401b90fcf16d24d976c18b` |
| `MobileGestaltHelper` (V8) | `0e0c05244a3d35753e948783372f18e615ae2032cf7b750dd7a9cc57cfb3626e` |
| `libMobileGestalt.dylib` (V9) | `383dfd64b790ba505760bb4af7a08ed2df185cbf6fffca64a13608f9bdcc2baf` |
| `NanoTimeKit` (V11) | `bf3f7e360fe06ab7e513807bcb3b6ac695f38c6ea8cd8428b7aed579c2b58e1c` |
| `ClockKit` (V12) | `5fc1784de78830eb83808a5663c87bf2be39bca08453b5d11ddef4dcad56cce0` |

The OTA hash is the digest of **my downloaded file**, not an independently verified Apple-published checksum. Tools used included [blacktop/ipsw](https://github.com/blacktop/ipsw), LLVM's `llvm-objdump`, Mach-O inspection, Xcode and on-device logs.

The addresses quoted throughout this README belong to the **specific binaries examined**. They aren't portable offsets for another watch or firmware.

For anyone trying to reproduce a result, please keep the evidence source clear:

- **Watch log:** something actually happened on the tested Ultra.
- **Firmware analysis:** a symbol, method, call site or data structure exists in an extracted binary.
- **External report:** another researcher observed something on another setup.
- **Inference:** an explanation that still needs a live test.

No successful protected-cache write, live cache rebuild, or native face activation was recorded in V1–V12.

## 13. Where I'm going next

Here's where the work stands after V12:

- [x] Read the matching MobileGestalt cache and keep a verified backup.
- [x] Correct the DeviceBrand descriptor and offset calculation.
- [x] Check the Class 7 and Class 13 MCM ideas against actual sandbox permissions.
- [x] Compare local MobileGestalt results with read-only Helper XPC replies.
- [x] Inspect the matching MobileGestaltHelper and libMobileGestalt binaries.
- [x] Find the Hermès 2025 FaceBundle and NanoTimeKit availability checks.
- [x] Locate the Hermès-specific restriction and the relevant ClockKit getters.
- [x] Remove the old forced-write path from the public research source and make RO23 diagnostics opt-in.
- [ ] Find where `supportsFall2025FacesCapability` is implemented and how its value is determined.
- [ ] Read the Ultra 1's real `deviceCategory`, `collectionType` and related capability values without modifying the system.
- [ ] Separate **seeing a face in the catalog**, **passing bundle checks**, **adding it**, and **actually using it**.
- [ ] Confirm a clean Xcode build and on-watch run of the published research version.
- [ ] Only change the unlock status after a genuine Hermès face has been demonstrated working on this watch.

I'll update the notes when there is another **measured result**, rather than turning each theory into a new success announcement.

## 14. Credits and license

First, thank you to **[Jinwoo Kim (@pookjw)](https://github.com/pookjw)** for writing and open-sourcing [HermesEnabler](https://github.com/pookjw/HermesEnabler). RO23 exists because that original project exists. The core application and the original engineering belong to him.

My contribution as **[@ZhuoXuan-MY](https://github.com/ZhuoXuan-MY)** is the Ultra 1 / 23U95 experimental work, local modifications, logs, firmware inspection and RO23 write-ups. The discussion began in [Issue #17](https://github.com/pookjw/HermesEnabler/issues/17).

Other projects and researchers that helped inform the investigation include [Gester](https://github.com/sasobhabha/Gester), [forcequitOS/worse_query](https://github.com/forcequitOS/worse_query), [forcequitOS/bad_query](https://github.com/forcequitOS/bad_query), [Geod-MCM-PoC](https://github.com/0xjohnnydev/Geod-MCM-PoC), [PoomSmart/MGKeys](https://github.com/PoomSmart/MGKeys), [blacktop/ipsw](https://github.com/blacktop/ipsw), [EthanArbuckle's iOS 26.1 research](https://github.com/EthanArbuckle/iPhone18-3_26.1_23B85_Restore), and the contributors to [upstream Issue #7](https://github.com/pookjw/HermesEnabler/issues/7). Their findings provided context; I don't present tests on other devices as tests on mine.

The original HermesEnabler code is released under the **MIT License**, with **Copyright (c) 2026 Jinwoo Kim**. The original copyright and license notices remain in [LICENSE](LICENSE); see [NOTICE.md](NOTICE.md) for more about this derivative. Retain applicable third-party notices, including `Gester-LICENSE.txt`, when redistributing their code.

That MIT license does **not** cover Apple's extracted firmware, private frameworks, watch-face assets, or Hermès trademarks. Those binaries and assets are not included as redistributable project resources.

## 15. Useful links and a final note

The main public discussion is **[HermesEnabler Issue #17](https://github.com/pookjw/HermesEnabler/issues/17)**. Relevant parts of the trail:

- [First watch tests and V1–V4 corrections](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6771229913)
- [V5–V7: Mach service and read-only XPC tests](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6777128180)
- [Earlier iOS 26.1 error-9 background](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6777139375)
- [V8: matching firmware and MobileGestaltHelper](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6777949079)
- [V9: matching libMobileGestalt](https://github.com/pookjw/HermesEnabler/issues/17#issuecomment-6778385658)

V10–V12 are summarized here from the local firmware analysis. I'm **not** claiming those sections were already published as separate Issue #17 comments.

Finally, please be careful with experimental system code. Incorrect assumptions about private APIs, entitlements or protected caches can cause crashes and other problems. **There is currently no verified Hermès face unlock on the tested Ultra 1 / watchOS 26.6.1 setup.** That's the starting point for the next round of research, not something I want to hide behind a download button.

---

*Original project by Jinwoo Kim (@pookjw). RO23 research by @ZhuoXuan-MY. Independent project; not affiliated with Apple, Hermès or the upstream maintainer.*
