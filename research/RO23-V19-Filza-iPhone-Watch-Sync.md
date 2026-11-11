> **V19.1 correction (2026-11-11):** I had already uploaded the precise Filza v27.2.2 source ZIP, which has now been verified and audited offline. The V19 statement that exact source could not be accessed is obsolete. See [V19.1 source and device audit](RO23-V19.1-Filza-Source-And-Bridge-Verification.md).

# RO23 V19 — iPhone Filza 27.2.2 / Apple Watch identity and face-sync boundary

**Date / 日期:** 2026-11-11
**Target / 目标设备:** Apple Watch Ultra 1 (Watch6,18 / n199ap), watchOS 26.6.1 (23U95), plus its *paired iPhone* (iOS version not verified).
**State / 状态:** Research complete for capability boundaries; **no jailbreak, no protected write, no native Hermès unlock**.

Original HermesEnabler work © Jinwoo Kim (@pookjw); RO23 research @ZhuoXuan-MY. This report is **read-only** and was produced without installing Filza, touching pairing databases, or changing watch code.

## 1. What was directly provided and what was actually verified / 证据边界

**USER-SUPPLIED RELEASE SCREENSHOT:** `Filza 27.2.2 — App Manager names, sizes, faster discovery`, a stable release with `filza_public.ipa`, `filza_develop.ipa` and `SHA256SUMS`. The screenshot claims LaunchServices CSStore-based app-name lookup, per-container sizes, iOS 26 alternative `worse_query` flags for app/extension/daemon containers, and faster discovery.

**NOT VERIFIED:** source code for **this exact** `git.jbjflab.top/admin/filza27.2` release. Its Gitea release and source archive are not accessible through the available web reader. Similar GitHub projects named Filza-27 are separate forks and must **not** be misrepresented as this project's v27.2.2 source. This also means I cannot certify IPA contents, entitlements, signature, precise write scopes, or trusted checksums from this evidence alone.

**INDEPENDENT VERIFIED UPSTREAM:** `forcequitOS/worse_query` explicitly claims iOS 26 app data containers, plugin/extension, internal daemon and App Group containers, but reserves `/var/containers/Data/System` and `/var/containers/Shared/SystemGroup/*` for **iOS 27**; author says this technique is not a jailbreak. Source:
https://github.com/forcequitOS/worse_query

**APPLE OFFICIAL:** `CLKWatchFaceLibrary.addWatchFace(at:completionHandler:)` supports normal `.watchface` importing but explicitly restricts Hermès faces to Hermès hardware. Even successful copying of a face file is not evidence of bypassing eligibility. Source:
https://developer.apple.com/documentation/clockkit/sharing-an-apple-watch-face

## 2. Where an iPhone actually keeps watch-related information / iPhone 数据分类

Historical digital-forensic studies and 2026 artifact research locate **pairing state** and **watch configuration/face backups** outside ordinary app containers:

| Data or path on paired iPhone | Function | Evidence | Does iOS 26 worse_query document it as reachable? |
|---|---|---|---|
| `/private/var/mobile/Library/DeviceRegistry.state/` | NanoRegistry pairing state; active/history plists | forensic artifact guides | **No** — outside advertised app/group container roots |
| `/private/var/mobile/Library/DeviceRegistry/<GUID>/` | Apple Watch sync metadata and backup/snapshot data | 2026 iLEAPP issue and forensic studies | **No** — outside advertised roots |
| `…/DeviceRegistry/<GUID>/NanoPreferencesSync/Backup/Files/` | Historical Apple Watch faces in backup/sync data | research examples of Face.json and resource ZIPs | **No** — outside advertised roots |
| `/var/mobile/Containers/Data/Application/<UUID>/` | iOS app-specific data, possibly including Apple Watch iPhone companion app | Apple app container architecture + worse_query README | **Potentially** reachable; *contents and authenticity unverified* |
| `/var/mobile/Containers/Shared/AppGroup/<UUID>/` | App Group shared data | worse_query README | **Potentially** reachable; not necessarily authoritative for pairing |
| `/var/containers/Shared/SystemGroup/<UUID>/` | iOS protected system-group state | worse_query README | **No advertised iOS 26 access**, iOS 27 only |

Historical forensic paths should be treated as **research leads**, not guaranteed exact paths on my current iPhone iOS build. Do not automatically open/modify sensitive pairing, Health, wallet or credentials data.

Evidence:
- https://github.com/abrignoni/iLEAPP/issues/1876 (2026 Watch backup/sync path suggestions)
- https://blog.elcomsoft.com/2019/06/apple-watch-forensics-02-analysis/ (historical NanoPreferencesSync, Face.json ZIP format)
- https://ismyphonepwned.com/artifact-paths.html (artifact directory index)

## 3. Why modifying the paired iPhone's serial-number record is not an actual watch identity change

```text
iPhone / 配对手机
   Filza app-container visibility (possible)
      ├── Watch companion app display preferences
      ├── cached pairing metadata (if present in an accessible container)
      └── cached/shared face-file representations
                 │    pairing / sync request (not unconditional write)
                 ▼
Apple Watch Ultra 1 / 手表独立 watchOS
   ClockKit + NanoTimeKit + MobileGestalt
      ├── deviceCategory = 4
      ├── collectionType = 9
      ├── deviceBrand = 0
      ├── NTKInternalBuild = false
      ├── Hermes2025 isRestrictedForDevice: gate
      └── bundle lookup + add-to-library checks
```

The watch's real observed V13/V14.1/V16 values above come from its own process on 23U95, **not** an editable pairing record inside the iPhone Watch app. The V17 disassembly separately identifies `isRestrictedForDevice:` in gallery enumeration, Bundle-ID lookup, old style lookup and `_NTKCanAddWatchFace` validation.

**Inference:** changing an iPhone-side serial-number display field or backup archive may alter how a local UI or archive is labeled, but there is **no verified mechanism** by which it rewrites the Watch's own model, device category, device brand, internal-build predicate, or activation identity. It may corrupt pairing/sync instead.

The Apple `WCSession.watchDirectoryURL` is a per-paired-watch **app-owned** storage directory, not a privileged watch filesystem mount; deleting/unpairing removes it.
https://developer.apple.com/documentation/watchconnectivity/wcsession/watchdirectoryurl

## 4. Next discriminating test / 下一步最小检查（只读）

**Goal:** establish whether my *specific* Filza 27.2.2 build on the paired iPhone can view any watch-related **app-container** metadata without touching other users' private data. This does **not** yet request changing watch identities.

1. First independently verify the iPhone's exact iOS build and the installed Filza release/signing provenance. Do **not** assume it behaves identically to another GitHub Filza fork; only the screenshot's release-notes claims are known.
2. If Filza is already installed and me trusts its signer, open **App Manager**. Search `Watch` and (if present) `com.apple.Bridge`; record only whether the app is listed and whether the **Data Container** can be opened. The exact bundle id may vary; do not infer absence from no search hit.
3. Inside that **specific** data container, inspect **folder names only** (such as `Documents`, `Library`, `Preferences`, `Application Support`). Do not view or export arbitrary private app files, pairing tokens, serialized device IDs, account records or cryptographic data.
4. Separately check whether Filza's UI explicitly exposes a `SystemGroup` section on that exact iOS build; do not assume a visible UI item means the directory can be read or written.
5. Report `iPhone iOS version`, `Filza build`, `Watch app found? yes/no`, `container listable? yes/no`, and **redacted** top-level folder names. This can establish an access boundary without leaking serial numbers, UDIDs, device-registry UUIDs or private state.

**Do not:** edit `DeviceRegistry`, `NanoPreferencesSync`, `MobileGestalt`, pairing states, serial number, keys/tokens, Activation Lock data, or force-watchface migration. There is no demonstrated reversible benefit, and pairing data can become inconsistent or trigger unpairing/restore.

## 5. Research decision matrix / 研究结论

| Hypothesis | Current support | Decision |
|---|---|---|
| Filza 27.2.2 can list iOS 26 app/extension/daemon containers | release screenshot + upstream worse_query | **Plausible; exact fork runtime untested** |
| Filza 27.2.2 can read some iPhone Watch-app data | general app-container capability | **Possible, requires target-specific check** |
| Filza on iOS 26 can directly access `/var/mobile/Library/DeviceRegistry` | outside claimed worse_query scope | **Not demonstrated** |
| Editing an iPhone record changes the Watch serial/model/brand as seen by NanoTimeKit | no dynamic evidence, independent watch checks | **Not established; unlikely shortcut** |
| Copying a Hermès `.watchface` file bypasses Watch eligibility | Apple documentation states supported-hardware restriction | **Not supported** |
| Existing Filza build permits watchOS 23U95 SystemGroup writes | exploit runs on iOS, not watchOS | **Not established** |

## 6. What would genuinely change the research conclusion?

- A **verifiable, compatible watchOS 23U95** permission or write primitive, independently checked on the Watch (not on its paired iPhone).
- A documented synchronization path that **changes the actual watch-side device capability answer**, rather than just an iPhone cache display; no such path established.
- An observed normal face-import trace where a real Hermès FaceBundle passes the Watch-side category and add eligibility checks; none demonstrated.

**V19 is source/evidence research only. Do not change the existing Xcode app or add a V19 button. Keep the original single GitHub repository and single local project.**

[RO23 V16 real-device evidence](RO23-V16-InternalBuild-Gate.md) · [RO23 V17 FaceBundle eligibility](RO23-V17-FaceBundle-Loading-Chain.md) · [RO23 V18 unresolved exception](RO23-V18-Restricted-Face-Exception.md)
