# HermesEnabler RO23 — watchOS 26.x Research

**Independent Apple Watch Ultra (1st generation) investigation | watchOS 26.6.1 (23U95) | MobileGestalt · ClockKit · NanoTimeKit · native Hermès / Zeus face eligibility**

[**English**](README.md) · [**简体中文**](README.zh-CN.md) · [Original HermesEnabler](https://github.com/pookjw/HermesEnabler) · [Upstream research discussion #17](https://github.com/pookjw/HermesEnabler/issues/17) · [Build instructions](BUILDING.md) · [Attribution](NOTICE.md)

> [!IMPORTANT]
> **RESEARCH ONLY — NOT A WORKING HERMÈS UNLOCK.** The tested Apple Watch Ultra 1 on watchOS 26.6.1 (build 23U95) has **not** enabled, installed, or used a genuine restricted Hermès watch face through this project. Protected MobileGestalt writes were denied with <code>EPERM</code>. Finding an Apple face bundle in firmware, locating eligibility code, or predicting a restriction branch is **not** the same as unlocking a face.
>
> **Repository/code distinction:** The currently published Xcode source is a sanitized research snapshot with a V1–V7 diagnostic UI. The **V13 and V14 analyses below document subsequent separately supplied research**; do **not** assume the V13/V14 watch-side buttons or bundles are already present in the public source tree. There is no verified 23U95 unlock IPA.

## Contents

1. [Purpose and provenance](#1-purpose-and-provenance)
2. [Executive summary and evidence standard](#2-executive-summary-and-evidence-standard)
3. [Device, firmware and observed results](#3-device-firmware-and-observed-results)
4. [How watch-face eligibility works](#4-how-watch-face-eligibility-works)
5. [RO23 V1–V12: technical investigation](#5-ro23-v1v12-technical-investigation)
6. [RO23 V13: Hermès 2025 category restriction](#6-ro23-v13-hermès-2025-category-restriction)
7. [RO23 V14: Zeus/Hermès legacy face restrictions](#7-ro23-v14-zeushermès-legacy-face-restrictions)
8. [Read-only V13/V14 results and interpretation](#8-read-only-v13v14-results-and-interpretation)
9. [What is actually in this GitHub repository](#9-what-is-actually-in-this-github-repository)
10. [Build, run and collect diagnostics](#10-build-run-and-collect-diagnostics)
11. [Research artifacts and reproducibility](#11-research-artifacts-and-reproducibility)
12. [Common misconceptions and troubleshooting](#12-common-misconceptions-and-troubleshooting)
13. [Current status and research roadmap](#13-current-status-and-research-roadmap)
14. [Credits, licensing and responsibility](#14-credits-licensing-and-responsibility)

## 1. Purpose and provenance

RO23 is my independent research fork of **[HermesEnabler / HermesEnabler 2](https://github.com/pookjw/HermesEnabler)**, originally developed by **[Jinwoo Kim (@pookjw)](https://github.com/pookjw)**. I am **[@ZhuoXuan-MY](https://github.com/ZhuoXuan-MY)**; my work concerns a first-generation Apple Watch Ultra on a specific watchOS 26.x build. The original project's code, design, MobileGestalt infrastructure, backup/restore foundation and upstream credit remain the original author's work. Parts of that project also derive from [Gester](https://github.com/sasobhabha/Gester).

The question is narrower than "can a watch face be copied?": **Why does a native Hermès face remain unavailable on a non-Hermès Apple Watch Ultra even when relevant Apple binaries are present in the matching firmware?** To investigate this, I recorded on-device MobileGestalt and sandbox results, checked private framework behavior in matching watchOS firmware, and compared the face-specific restriction functions with read-only device properties.

Research progressed from MobileGestalt cache layout and permissions (V1–V9), through NanoTimeKit and ClockKit (V10–V12), to **Hermès 2025 category analysis (V13)** and **legacy Zeus/Hermès FaceBundle analysis (V14)**.

The upstream project's **current README describes watchOS 27.0–27.3 beta 1 support**. That statement is about the upstream application, **not a compatibility claim for this watchOS 26.6.1 fork**. This work is not affiliated with or endorsed by Apple, Hermès, or the original HermesEnabler maintainer. AI tools assisted with some experimental code and written analysis; recorded watch observations are identified separately from static analysis.

## 2. Executive summary and evidence standard

### Key outcomes

| Question | Finding | Evidence |
| --- | --- | --- |
| Can the tested app read MobileGestalt on 23U95? | **Yes**, and it created a matching app-local backup | Historical on-watch tests |
| Can it open the protected MobileGestalt cache for writing? | **No — EPERM**; no protected cache write occurred | Historical on-watch tests |
| Does receiving an MCM sandbox extension grant target write permission? | **No** in the tested Class-13 case | Historical on-watch tests |
| Does MobileGestaltHelper answer tested queries? | XPC connection worked; queries returned **error 9** | Historical on-watch tests |
| Is the 2025 Hermès face bundle in matching firmware? | **Yes** | Host-side binary inspection |
| Is Hermès 2025 limited by device category? | **Yes; V13 identified {2, 3, 5}** as the allowed values for a specific branch | Static reverse engineering |
| Is an Ultra-classified ClockKit device accepted by that check? | Categories **4 and 6** classify as Ultra; they are outside {2, 3, 5} | Static analysis, supported by device observations |
| Are older Zeus/Hermès faces unrestricted? | **No**; V14 finds several distinct restrictions | Static reverse engineering |
| Did the read-only V14 watch diagnostic report the Zeus gates as passing? | **No; reported RESTRICTED** | Owner-provided watch log |
| Has native Hermès activation succeeded? | **No** | Project status |

### Three evidence levels

- **[DEVICE]** A real log or observable result from the owner's tested watch and local experimental build.
- **[STATIC]** A finding made by inspecting a specific Apple-supplied binary offline. It establishes code/data presence, not that the whole branch ran on the device.
- **[INFERENCE / OPEN]** An interpretation, predicted branch outcome, or question awaiting a controlled device test.

These labels are deliberately conservative. **"Restriction function located" ≠ "eligibility bypass discovered" ≠ "face installed" ≠ "face functional."** Values, addresses and assumptions are specific to their originating 23U95 binaries and must not be extrapolated to other watchOS releases.

## 3. Device, firmware and observed results

| Item | Research configuration |
| --- | --- |
| Device | Apple Watch Ultra (1st generation) |
| Product identifier | <code>Watch6,18</code> |
| Board | <code>n199ap</code> |
| Operating system | watchOS **26.6.1** |
| Build | **23U95** |
| Executable architecture | Mach-O <code>arm64_32</code> / ILP32 |
| App | Locally modified HermesEnabler2 and later read-only diagnostic experiments |
| Deployment context | Mac, Xcode development signing, user-configured App Group |
| Scope | Native Hermès 2025 and legacy Zeus/Hermès availability |
| Final unlock result | **Not achieved** |

A snapshot of the historical 23U95 MobileGestalt read was:

~~~text
MobileGestalt plist:     13,328 bytes
CacheUUID:               3BE19A76-F253-4CE4-AAC1-DF6D801CAAB1
CacheData:               6,309 bytes (0x18A5)
Cache records:           701 × 9-byte layout
CacheExtra:              72 entries
MGCopyAnswer DeviceBrand: CFNumber(0)
~~~

The prior watchOS 26.5 backup had a different UUID and size. It was **not** restored onto 23U95. An independently validated build-specific app-local backup was retained instead. Never interpret an app-local backup as proof that changing the live protected cache is possible.

## 4. How watch-face eligibility works

This is a **research model**, not a traced diagram of every production call on this watch:

~~~text
Matching watchOS firmware includes a native FaceBundle
                 |
                 v
Face style / descriptor discovery and registration
                 |
                 v
NanoTimeKit face-availability and migration checks
                 |
                 v
Face subclass +isRestrictedForDevice: checks
                 |
                 +--> CLKDevice deviceCategory
                 +--> CLKDevice collectionType
                 +--> CLKDevice deviceBrand / isUltra / isZeusBlack
                 +--> capability and hardware-specific-face gates
                 |
                 v
Face becomes discoverable / selectable / usable (NOT demonstrated)
~~~

These stages are **not interchangeable**:

1. **Bundle presence**: the Apple binary and assets exist in firmware.
2. **Bundle loading**: the relevant class/category actually registers in a process.
3. **Eligibility**: all relevant catalog, descriptor, subclass and capability checks accept the specific device.
4. **Installation/selection**: the face is actually offered and can be added.
5. **Operational success**: the selected native face renders and remains functional after normal system transitions.

A MobileGestalt key is just one potential input. ClockKit has distinct fields, and a face's own method can reject the hardware before a later collection or capability gate matters.

## 5. RO23 V1–V12: technical investigation

The previous [README2.md](README2.md) records the longer historical V1–V12 narrative. The summary below preserves both successful observations and failed experiments, with the later correction to an incorrect DeviceBrand offset.

### V1–V3 — locating the correct DeviceBrand cache descriptor

The lookup key was:

~~~text
DeviceBrand = fuKL2rMywRgQF1wowOA/cg
~~~

An early descriptor scan **incorrectly** treated index 206, value offset <code>0x670</code>, and validity offset <code>0x16B6</code> as DeviceBrand. Follow-up analysis of the <code>arm64_32</code> descriptor layout corrected the record:

| Field | Correct 23U95 research value |
| --- | --- |
| Descriptor stride | 100 bytes / <code>0x64</code> |
| Flags | 12 / <code>0x0C</code> |
| DeviceBrand descriptor index | **103** |
| Internal descriptor type | **5** |
| Value offset | **<code>0x338</code>** (= 103 × 8) |
| Validity offset | **<code>0x164F</code>** (= 701 × 8 + 103) |
| Read value / validity | 0 / 1 |

The earlier values were **not** validated DeviceBrand write offsets and must not be reused. The number reported by <code>MGCopyAnswer</code> is a Core Foundation number; its CF type must not be confused with the internal MobileGestalt descriptor type.

### Historical write attempt — permission failure before modification

After verifying a matching backup, an old local test attempted to obtain a writable descriptor to the protected system plist:

~~~text
MG FORCE: entering 23U95 write path
MG FORCE: 23U95 backup verified
MG FORCE: WRITE DENIED errno=1 (Operation not permitted)
~~~

The open operation failed with **EPERM** before <code>pwrite</code> could execute. **No DeviceBrand bytes were changed.** The unsafe old experimental writer, including its mistaken offset hypothesis, was removed from the sanitized public source. The correct offset calculation does **not** confer permission to write.

### V4 — MCM Class 13 token versus actual permissions

A Class-13 request with flags <code>0x0800000000</code> produced a sandbox extension; it was consumed successfully in a historical test. Actual permission checks remained:

| Target permission | Before | After |
| --- | --- | --- |
| Read protected MobileGestalt file | Allowed | Allowed |
| Open file for writing | Denied | Denied |
| Create file in protected directory | Denied | Denied |

The app's own App Group entitlement did not provide private Apple system-group write rights. A token being returned or consumed is **not equivalent** to permission on the desired target.

### V5–V7 — MobileGestaltHelper communication

Mach/bootstrap lookup reached <code>com.apple.mobilegestalt.xpc</code>, and NSXPC communication completed, but read-only Helper questions all returned <code>{"error":9}</code>:

| Query | Local <code>MGCopyAnswer</code> | Helper XPC |
| --- | --- | --- |
| <code>DeviceBrand</code> | CFNumber(0) | error 9 |
| Hashed DeviceBrand key | CFNumber(0) | error 9 |
| <code>BuildVersion</code> | Returned a string | error 9 |
| <code>ProductType</code> | Returned a string | error 9 |

Here, **error 9 is a MobileGestalt server result**, not POSIX <code>EPERM</code>, an NSXPC connection failure, or a Mach lookup error. No cache rebuild or protected write was performed.

### V8–V9 — matching Helper and libMobileGestalt inspection

From the matching 23U95 firmware, the analysis located:

| Binary / routine | Address in inspected binary |
| --- | --- |
| MobileGestaltHelper <code>getServerAnswerForQuestion:reply:</code> | <code>0x5110</code> |
| MobileGestaltHelper <code>rebuildCache:</code> | <code>0x55F0</code> |
| MobileGestaltHelper call into <code>_MGServerCopyAnswerWithError</code> | <code>0x51C4</code> |
| libMobileGestalt <code>_MGServerCopyAnswerWithError</code> | <code>0x215B42A8</code> |
| libMobileGestalt server access-check logic | <code>0x215B4BF4</code> |

These findings provide a plausible static explanation for why local reads worked but Helper queries were rejected. They are **not a per-query dynamic trace** and do not establish a working Helper-mediated setter. In particular, the existence of <code>rebuildCache:</code> is **not** a recommendation to invoke it.

### V10–V12 — firmware FaceBundles, NanoTimeKit and ClockKit

The matching OTA included <code>NTKHermes2025FaceBundle</code>, <code>Carousel</code>, <code>ClockFace</code>, <code>nanotimekitd</code>, NanoTimeKit and ClockKit. In the inspected binaries:

| Symbol / getter | Address |
| --- | --- |
| NanoTimeKit <code>_NTKFaceStyleIsAvailable</code> | <code>0x544392B0</code> |
| <code>-[NTKFaceDescriptor isAvailableForDevice:]</code> | <code>0x543D998C</code> |
| <code>-[NTKFaceBundleManager faceBundleForBundleIdentifier:onDevice:forMigration:]</code> | <code>0x544B0DDC</code> |
| Hermès 2025 <code>+[Hermes2025Face isRestrictedForDevice:]</code> | <code>0x3B2C</code> |
| <code>-[CLKDevice deviceCategory]</code> | <code>0x49C30EB4</code> |
| <code>-[CLKDevice collectionType]</code> | <code>0x49C354F0</code> |
| <code>-[CLKDevice deviceBrand]</code> | <code>0x49C6F144</code> |
| <code>-[CLKDevice isUltra]</code> | <code>0x49C6F11C</code> |

V12 established that ClockKit's **deviceCategory**, **collectionType**, **deviceBrand**, and **isUltra** are distinct properties. This made a simple "change DeviceBrand and everything will pass" explanation untenable. V13 then clarified exactly how one important face checks those properties.

### Other tested routes — unsuccessful

- Historical Class-7 MCM flags <code>0x0800000000</code>, <code>0x8000000000</code>, and <code>0x8100000000</code> did not yield usable sandbox tokens in the tested configuration.
- A historical Geod-MCM Class-12 experiment did not produce the requested container object.
- Neither outcome proves that all conceivable methods are impossible; it proves only that the tested paths did not work on this device.

## 6. RO23 V13: Hermès 2025 category restriction

**Source:** owner-supplied *RO23 V13 — Hermès 2025 FaceBundle / ClockKit cross-binary eligibility analysis*, dated **2026-11-11**, based on the matching 23U95 Hermès FaceBundle, NanoTimeKit and ClockKit. V13's main findings are **static binary findings**. Its source snapshot separately proposed a read-only watch-side diagnostic; the uploaded report did not itself document an Xcode build or watch execution.

### 6.1 Allowed categories are {2, 3, 5}

In the Hermès 2025 FaceBundle:

- <code>+[Hermes2025Face isRestrictedForDevice:]</code> starts at **<code>0x3B2C</code>**.
- It delegates to a local helper at **<code>0x46B8</code>**.
- The helper obtains <code>deviceCategory</code> at **<code>0x46EC</code>** and checks set membership around **<code>0x46F4</code>**.
- The static Swift collection literal at **<code>0xCCC4C</code>**, with its members at **<code>0xCCC5C / 0xCCC60 / 0xCCC64</code>**, contains **2, 3 and 5**.
- A failed membership test follows the restricted path at approximately **<code>0x4770</code>**.

**This compares internal <code>CLKDevice.deviceCategory</code> numbers, not the marketing product identifier or a string such as "Ultra".**

### 6.2 ClockKit size-class mapping

The matching ClockKit contains a ten-entry size-class → category mapping at **<code>0x49CA5E70</code>**:

| sizeClass | deviceCategory | sizeClass | deviceCategory |
| ---: | ---: | ---: | ---: |
| 0 | 1 | 5 | 3 |
| 1 | 1 | 6 | **4** |
| 2 | **2** | 7 | **5** |
| 3 | **2** | 8 | **5** |
| 4 | **3** | 9 | **6** |

The Ultra classification logic around **<code>0x49C6E26C–0x49C6E27C</code>** uses the expression **<code>(deviceCategory &amp; ~2) == 4</code>**; within this specific implementation, categories **4 and 6** yield <code>isUltra=true</code>. Both are outside the Hermès 2025 whitelist **{2,3,5}**.

**V13 implication:** for a device classified as Ultra under this ClockKit implementation, this particular face's category check is already restrictive, **before** later collection/capability checks. Changing only <code>DeviceBrand</code> has **not** been demonstrated to make Hermès 2025 available.

### 6.3 Fall 2025 capability is not a universal bypass

V13 found <code>supportsFall2025FacesCapability</code> not in the inspected base ClockKit class implementation but in an Objective-C **category on CLKDevice supplied by the Hermès 2025 bundle**. Its implementation at **<code>0x37C4</code>** is simply:

~~~asm
0x37C4: mov w0, #1
0x37C8: ret
~~~

**When that category is loaded**, the method returns true. An unregistered method in an unrelated process says nothing conclusive about the value after the FaceBundle loads. More importantly, returning true from one capability method does **not** cancel the earlier device-category rejection.

### 6.4 DeviceBrand, collectionType and category are different fields

In the matching ClockKit <code>_loadDeviceInfo</code> logic around **<code>0x49C6DE20–0x49C6DE44</code>**, some branches map numerical <code>deviceBrand=1</code> to <code>collectionType=5</code> and <code>deviceBrand=2</code> to <code>collectionType=6</code>. The category itself is loaded separately from the size-class table. The Hermès restriction helper also checks <code>collectionType==5</code> at about **<code>0x4744</code>**, but only after earlier checks allow that path.

**Conclusion: category rejection is a real independent blocker.** A DeviceBrand-only cache edit is neither shown to be permitted nor shown to be sufficient.

## 7. RO23 V14: Zeus/Hermès legacy face restrictions

**Source:** owner-supplied *RO23 V14 — Zeus/Hermès legacy face eligibility (23U95)*, dated **2026-11-11**. The owner inspected **RO23-V14-Zeus.zip** against the same 23U95 ClockKit/NanoTimeKit context. The research analyzes Apple's **legacy Zeus-family** FaceBundle separately from the Hermès 2025 class in V13.

### 7.1 Inspected bundle and provenance

| Property | Value |
| --- | --- |
| Binary | <code>NTKZeusFaceBundle</code> |
| Executable size | **663,040 bytes** |
| Architecture | Mach-O <code>arm64_32</code> |
| SHA-256 | <code>2b34d3d411b77ee73f3892638f419eda83b7bedc4653ecf44adf7c975bbd72e4</code> |
| Bundle ID | <code>com.apple.NTKZeusFaceBundle</code> |
| Reported MinimumOSVersion | **26.6** |
| LegacyStyles | <code>SpectrumZeus</code>, <code>ZeusAnalog</code> |
| Other identified families | Hades, Poodle, Secretariat, Bellona, variants |
| Distribution | Original Apple binaries and art **not included** |

The binary's Objective-C relative method lists were decoded to associate <code>isRestrictedForDevice:</code> implementations with their **actual owning classes** rather than relying on loose string matches.

### 7.2 Six class implementations and checks

| Face class | Method IMP (inspected VM address) | V14 static finding |
| --- | ---: | --- |
| <code>NTKZeusAnalogFace</code> | <code>0x169C</code> | collectionType == 5 passes this restriction; otherwise consults <code>NTKShowHardwareSpecificFaces()</code> |
| <code>NTKSpectrumZeusFace</code> | <code>0x1648</code> | Restriction includes <code>isZeusBlack</code>, deviceCategory and/or hardware-specific-face gate |
| <code>NTKHadesFace</code> | <code>0x12FC</code> | Rejects device categories 1, 4 and 6 before later tests |
| <code>NTKSecretariatFace</code> | <code>0x5C08</code> | Rejects categories 1, 4 and 6 before later tests |
| <code>NTKPoodleFace</code> | <code>0x13B4</code> | Rejects category 1, followed by additional tests |
| <code>NTKBellonaFace</code> | <code>0x21E80</code> | Category-1 and other specific checks; branch not yet fully interpreted |

These are **per-face restrictions**. No single blanket "all Hermès faces unlocked" predicate has been demonstrated.

### 7.3 Zeus Analog: the relevant branch

~~~asm
0x16A8  bl   0x43480    ; objc_msgSend$collectionType
0x16AC  cmp  w0, #5
0x16B0  b.ne 0x16BC
0x16B4  mov  w0, #0      ; unrestricted for this check
0x16BC  bl   0x340AC    ; _NTKShowHardwareSpecificFaces
0x16C0  eor  w0, w0, #1 ; invert result => restricted
~~~

The owner's earlier observed Ultra <code>collectionType=9</code> does **not** take the <code>collectionType==5</code> direct-pass path. It reaches the hardware-specific-face setting instead. A missing Hermès-2025 whitelist in this **different** class does not imply that Zeus Analog is accepted.

V14 identified NanoTimeKit's exported <code>_NTKShowHardwareSpecificFaces</code> at **<code>0x546014DC</code>**. That routine checks runtime prerequisites and an internal face-display setting. **Its presence does not establish a reliable stock-device unlock path.** Matching ClockKit also exposes <code>-[CLKDevice isZeusBlack]</code> at **<code>0x49C6F0EC</code>**. Another inspected method, <code>-[CLKDevice supportsPDRCapability:]</code> at **<code>0x49C6E724</code>**, returns true in this binary; other gates remain in force.

### 7.4 Do not conflate V13 and V14

| | Hermès 2025 (V13) | Legacy Zeus family (V14) |
| --- | --- | --- |
| Face implementation | <code>Hermes2025Face</code> | Multiple subclasses such as <code>NTKZeusAnalogFace</code> |
| Key early restriction | Category whitelist **{2,3,5}** | Face-specific paths, including collectionType and hardware gate |
| Ultra category 4 | Rejected by V13's analyzed category branch | Some legacy classes reject 4; Zeus Analog takes another branch |
| Status | Static restriction identified | Six methods mapped; several branches investigated |
| Proven activation | **No** | **No** |

## 8. Read-only V13/V14 results and interpretation

The research reports must be read with the owner's subsequent **actual watch output** in mind. Earlier notes recorded a V13 reading of **<code>deviceCategory=4</code>, <code>collectionType=9</code>, <code>isUltra=true</code>** and a DeviceBrand-related value of **0**. A later V14 watch run reported:

~~~text
[bqtool] RO23 V14 — Zeus native face eligibility (read-only)
Build=23U95
deviceCategory=4
collectionType=9
deviceBrand=399803152
isZeusBlack=false
NTKShowHardwareSpecificFaces=false
ZeusAnalog gate (0x169C): RESTRICTED
SpectrumZeus gate (0x1648): RESTRICTED
Hades/Secretariat category gate: RESTRICTED
No face bundle loaded. No face installed.
No protected writes, overrides, or restarts.
RO23 V14 END systemWrites=NO
~~~

**Interpretation:** this observed combination is consistent with V13's Ultra category finding and V14's branch predictions. The V14 report's original static inspection was not itself a watch execution; the log above is a **separate, owner-provided device result**. It is a diagnostic assessment of gates, **not** proof that the full system face-selection pipeline was exercised.

**Important value discrepancy:** the earlier <code>MGCopyAnswer(DeviceBrand)=0</code> / V13-reported value and the later V14 <code>CLKDevice deviceBrand=399803152</code> are **not the same observed number**. They come from different reported reads/contexts. Without an instrumented comparison of APIs, objects and builds, we cannot conclude whether this reflects a representation difference, a source difference or another cause. **Do not silently replace one with the other, and do not treat them as interchangeable.**

V14's local experimental diagnostic was designed to call only read-only <code>CLKDevice</code> getters and the original exported <code>_NTKShowHardwareSpecificFaces</code> when available, then evaluate restrictions without loading the FaceBundle. It writes only an app-owned <code>Documents/bqtool.log</code>. **That description is of the separately supplied V14 research snapshot; the present public GitHub UI does not yet expose this button.**

## 9. What is actually in this GitHub repository

This is a **source and research repository**, not a prebuilt watchOS 26.x unlock distribution. The current public tree includes:

~~~text
HermesEnabler2.xcodeproj/
  project.pbxproj
HermesEnabler2/
  BQCore.h
  BQCore.m
  ContentView.swift
  HermesEnabler2App.swift
  HermesEnabler2.entitlements
  Gester-LICENSE.txt
  Assets.xcassets/
BUILDING.md
CHANGELOG.md
LICENSE
NOTICE.md
PUBLICATION_CHECKLIST.md
PUBLISH_ON_GITHUB.zh-CN.md
README.md
README.zh-CN.md
README2.md                       (legacy V1–V12 English research record)
~~~

The sanitized source deliberately:

- Removes the historical direct 23U95 writer with incorrect offsets and the Geod writable-file experiment.
- Has fail-closed MobileGestalt save/restore, Hermès enable and capability-override operations.
- Removes enable, AOD, restoration, respring and mutation controls from the public UI.
- Keeps explicit diagnostic actions such as **Check Compatibility**, **Direct Read Probe**, **Test MG Access**, **Create Local MG Backup**, and **Run RO23 V1–V7 Diagnostics**.
- May create **logs/backups in the app's own sandbox**. Some historical MCM probes may manipulate temporary **app-owned** paths; review them before testing.
- Has **not** been independently clean-built or verified as a complete on-device application from this published snapshot.

**V13/V14 firmware analysis belongs in the documentation now, not in a claim about source functionality.** A future source update needs its own code audit, build test, and clear release notes before those diagnostic buttons can be advertised as shipped.

## 10. Build, run and collect diagnostics

### Requirements

- A Mac with Xcode and an appropriate **watchOS SDK**.
- An Apple Watch you own and can select as a development run destination.
- Development-signing credentials/team that your Xcode setup can use.
- Familiarity with Swift, Objective-C, private API instability and Xcode logs.
- Sufficient care not to install unreviewed experimental changes on a device containing important data.

### Local build procedure

1. Clone the source:

   ~~~bash
   git clone https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X.git
   cd HermesEnabler--WatchOS26.X
   open HermesEnabler2.xcodeproj
   ~~~

2. In **Targets → HermesEnabler2 → Signing & Capabilities**, select **your own development team**. The repository intentionally does not include a personal signing team.
3. Replace the example Bundle Identifier <code>com.example.HermesEnablerRO23</code> with your own unique identifier.
4. Replace <code>group.com.example.HermesEnablerRO23</code> in the entitlements file with an App Group you actually provisioned, and keep Signing & Capabilities consistent. An App Group does **not** add Apple-private system-group entitlements.
5. Select an appropriate Apple Watch destination and build/run if your SDK and signing environment support it.
6. Use **only the buttons present in the public source**; read the results and app-owned <code>Documents/bqtool.log</code> before drawing conclusions.

See [BUILDING.md](BUILDING.md) for the source-snapshot procedure. The Xcode project sets a **watchOS 26.0 deployment target**, which is a compile-time setting, **not a promise that every 26.x OS works**. This repository does **not** offer a verified 23U95 unlock IPA.

### How to report a useful result

Include **device model/identifier, exact watchOS build, commit SHA, diagnostic button, verbatim redacted log, whether the FaceBundle was loaded, and what was physically visible on the watch**. Separate successful read-only output from a real installed face. Redact serial numbers, personal App Group IDs, container UUIDs, backup contents and other private identifiers.

## 11. Research artifacts and reproducibility

The investigation relied on **matching-binary analysis**, not offsets borrowed from different OS builds.

| Research input | Reported SHA-256 |
| --- | --- |
| Original downloaded full watchOS OTA | <code>8c04028c94a26eafc96e2dc50cf5c5296834ca30e0401b90fcf16d24d976c18b</code> |
| V8 MobileGestaltHelper | <code>0e0c05244a3d35753e948783372f18e615ae2032cf7b750dd7a9cc57cfb3626e</code> |
| V9 libMobileGestalt.dylib | <code>383dfd64b790ba505760bb4af7a08ed2df185cbf6fffca64a13608f9bdcc2baf</code> |
| V11 NanoTimeKit | <code>bf3f7e360fe06ab7e513807bcb3b6ac695f38c6ea8cd8428b7aed579c2b58e1c</code> |
| V12 ClockKit | <code>5fc1784de78830eb83808a5663c87bf2be39bca08453b5d11ddef4dcad56cce0</code> |
| V14 NTKZeusFaceBundle | <code>2b34d3d411b77ee73f3892638f419eda83b7bedc4653ecf44adf7c975bbd72e4</code> |

These are **owner-reported artifact hashes**, not a promise that Apple publishes those digests. Research materials included historical V10 FaceBundle/Carousel/ClockFace, V11 NanoTimeKit, V12 ClockKit, the V13 combined binary report, and V14 Zeus analysis. Relevant tooling included Xcode, LLVM disassembly, Mach-O metadata inspection, firmware extraction tools and owner-provided device diagnostics.

**No proprietary firmware, private Apple executable, native FaceBundle, Assets.car or watch-face artwork is distributed here.** Readable offsets are documentation for the specific researched binaries. Binary size, hash and OS build are part of provenance, not a universal exploit recipe.

## 12. Common misconceptions and troubleshooting

**"The FaceBundle exists. Why is the face still absent?"** Firmware packaging and face eligibility are different. NanoTimeKit/ClockKit and per-face restrictions can exclude a model even with the executable present.

**"If I set DeviceBrand to a Hermès value, will it work?"** Not demonstrated. On 23U95 the protected cache could not be opened for writing; V13 additionally shows an independent category rejection. Changing one input would not automatically satisfy every gate.

**"The V13 method returns true. Doesn't that mean eligibility?"** No. The <code>supportsFall2025FacesCapability</code> category method returning true only describes that method when the category is registered. The earlier whitelist can still reject the watch.

**"Zeus Analog is different, so is it unlocked?"** No. For observed <code>collectionType=9</code>, its analyzed branch consults the hardware-specific-face gate, and the supplied V14 log reported this gate false.

**"The MCM query returned a token. Why did writing fail?"** A consumed extension does not imply all target permissions. Actual before/after filesystem access remained denied.

**"Helper returned error 9. Is that EPERM?"** No. The read-only Helper returned a MobileGestalt server error value. A separate protected-file open failed with POSIX <code>EPERM=1</code>.

**"Can I install the upstream IPA on watchOS 26.6.1?"** Do not assume upstream's newer watchOS-27 support implies 23U95 compatibility. This fork provides no verified 26.x unlock IPA.

**"Where is the RO23 V14 Check Zeus Faces button?"** It belongs to the separately tested/reported V14 diagnostic snapshot. The public repository's current <code>ContentView.swift</code> does **not** contain that button; documentation of V14 findings is not an automatic source-code update.

**"Is a green read-only gate enough to claim success?"** No. It would establish only one calculated condition. Complete device eligibility, catalog exposure, face installation, rendering and persistence remain distinct questions.

## 13. Current status and research roadmap

| Milestone | Status |
| --- | --- |
| Read/parse current 23U95 MobileGestalt | **Observed** |
| Verify a matching app-owned backup | **Observed** |
| Correct DeviceBrand index and offsets | **Analyzed/corrected** |
| Test protected cache write access | **Denied (EPERM)** |
| Test Class 7, Class 13 and Geod-MCM paths | **Tested without obtaining write permission** |
| Compare Helper XPC against local MG reads | **Observed: error 9** |
| Locate Hermès 2025 / NanoTimeKit / ClockKit routines | **Static evidence** |
| Decode V13 Hermès 2025 category whitelist | **Static evidence: {2,3,5}** |
| Map V14 six Zeus-family restriction methods | **Static evidence** |
| Obtain V14 read-only Zeus eligibility report | **Owner-supplied: restrictions reported** |
| Integrate and independently build/test V13–V14 buttons in this public repository | **Not established** |
| Establish a supported, durable native face discovery/installation route | **Open** |
| Enable a genuine native Hermès watch face on this Ultra/23U95 | **NOT ACHIEVED** |

Next useful work is **non-destructive and evidence-driven**: independently reproduce matching-binary observations, reconcile the different DeviceBrand read contexts, document a clean build and on-device run of any published read-only diagnostic code, test catalog/discovery behavior through supported interfaces if possible, and publish exact results with appropriate limitations.

No protected-cache write entitlement, stock-device native face-installation method, or stable bypass has been established. **Do not convert unverified hypotheses into "unlock successful" release notes.**

## 14. Credits, licensing and responsibility

**Original project:** [HermesEnabler / HermesEnabler 2](https://github.com/pookjw/HermesEnabler) by **Jinwoo Kim (@pookjw)**, **MIT License, Copyright (c) 2026 Jinwoo Kim**. Retain [LICENSE](LICENSE).

**Third-party source:** [Gester](https://github.com/sasobhabha/Gester), with its relevant license retained at [HermesEnabler2/Gester-LICENSE.txt](HermesEnabler2/Gester-LICENSE.txt).

**Independent RO23 research:** [@ZhuoXuan-MY](https://github.com/ZhuoXuan-MY), including the first-generation Ultra observations, local experiments, firmware inspection, V13/V14 analyses and this write-up. Technical scripts and documentation were assisted by AI; this does not change upstream authorship.

**Related context:** [upstream Issue #17](https://github.com/pookjw/HermesEnabler/issues/17), [Issue #7](https://github.com/pookjw/HermesEnabler/issues/7), [worse_query](https://github.com/forcequitOS/worse_query), [bad_query](https://github.com/forcequitOS/bad_query), [Geod-MCM-PoC](https://github.com/0xjohnnydev/Geod-MCM-PoC). Research from other devices is background, **not** evidence from this Ultra.

See [NOTICE.md](NOTICE.md) for detailed attribution and the [publication checklist](PUBLICATION_CHECKLIST.md) for source and privacy boundaries. The MIT license for the open-source app **does not license Apple's firmware, private frameworks, watch-face assets or Hermès trademarks**.

**Use research code at your own risk.** Test only on equipment you control, inspect changes before running them, keep private data private and avoid manipulating protected system caches. This project is neither an Apple/Hermès product nor an official upstream HermesEnabler release.

---

**Research status (2026-11-11): eligibility mechanisms substantially better understood through RO23 V14; genuine Hermès face unlocking on Apple Watch Ultra 1 / watchOS 26.6.1 (23U95) remains unproven and unachieved.**
