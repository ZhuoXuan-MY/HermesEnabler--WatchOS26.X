# RO23 V30 — EscapeOS v0.3.2 compatibility with Ultra 1 / watchOS 26.6.1

**Objective:** Evaluate whether [pwnapplehat/EscapeOS v0.3.2](https://github.com/pwnapplehat/EscapeOS/releases/tag/v0.3.2) can modify the target's protected MobileGestalt plist and thereby remove the native Hermès face block on Apple Watch Ultra 1 (`Watch6,18/n199ap`, build `23U95`).

**Date assessed:** 2026-11-11, Beijing Time (UTC+08:00).  
**Method:** source/release audit via connected GitHub repository content at **tag `v0.3.2`**, not merely search previews of older README versions. No IPA installation, watch-side test, write or privilege elevation attempted.  
**Result:** **NOT A WORKING WATCH SYSTEM WRITER**. No native Hermès activation.

## What the v0.3.2 release actually adds

The official tag published 2026-11-11 at 14:19:37 UTC (22:19 Beijing Time) specifies:

- App Groups: listing app-owned groups when `installation_proxy` supplies group identifiers and folders; browsing those groups when a usable folder path is present.
- Import Backup: recognizes and imports the app's own exported backup ZIPs.
- Search Whole App: selecting a file now navigates to its parent folder and highlights the file.
- **MinimumOSVersion iOS 26.0** (confirmed in `Resources/Info.plist`, `CFBundleSupportedPlatforms=iPhoneOS`).

The advertised ranges for the bundled `worse_query` are **iOS 26.0–26.7.2 and iOS 27.2**; the reported real hardware checks concern **iPhone 17 on iOS 26**, *not any Apple Watch*.

## Why this does not grant protected watchOS MobileGestalt access

| Question | Exact v0.3.2 evidence | Consequence for `Watch6,18/23U95` |
|---|---|---|
| Can the IPA run directly as a Watch app? | `Resources/Info.plist` lists `CFBundleSupportedPlatforms = iPhoneOS`, `LSRequiresIPhoneOS`, `MinimumOSVersion = 26.0`; no watchOS target shown | **No supported watchOS app install** |
| Does its App Group browse target Apple's system group? | `EscapeOS/Engine/AppGroupListing.swift` accepts keys beginning `group.` from an iPhone app install record. `systemgroup.com.apple.mobilegestaltcache` is a distinct, protected **SystemGroup** not an ordinary app group, and cannot be inferred from installation_proxy's app group map | **No access demonstrated to this watch SystemGroup** |
| Does it have private SystemGroup entitlements? | `EscapeOS.entitlements` only declares `com.apple.security.application-groups` with `group.com.ipaside.escapeos` plus `get-task-allow` | **No Apple SystemGroup write authorization** |
| What sandbox extension does it ask for? | `EscapeOS/Engine/SandboxEscape.swift` and `worse_query.m` call a class-7 app-group-oriented primitive; `query_set_class(query,7)` | The owner's prior 23U95 **Class 7** tests yielded no usable token. Running the iPhone code does not override that watchOS result |
| Can it see Watch files via pairing? | It uses iPhone-side LocalDevVPN / iPhone `installation_proxy` and iPhone app data paths, not the paired Watch's protected filesystem | Browsing the **iPhone Watch/Bridge app** is not editing the Watch itself |
| Does it fix the actual block? | Existing Watch-side `BQSaveGestalt` attempted `open(O_RDWR)` on live `systemgroup.com.apple.mobilegestaltcache` plist and obtained `EPERM` | **No new validated writable fd, no patch, no unlock** |

**Nuance:** EscapeOS does offer real **iPhone app data and certain app-group browsing**; saying “cannot modify any plist” would be wrong. The negative conclusion is specifically about **cross-device watchOS protected SystemGroup writes**. Its app-group feature is not automatically a SystemGroup bypass.

**Source evidence (tagged, version-specific):**
- [v0.3.2 release](https://github.com/pwnapplehat/EscapeOS/releases/tag/v0.3.2)
- [v0.3.2 README](https://github.com/pwnapplehat/EscapeOS/blob/v0.3.2/README.md)
- [v0.3.2 Changelog](https://github.com/pwnapplehat/EscapeOS/blob/v0.3.2/CHANGELOG.md)
- [Platform in Info.plist](https://github.com/pwnapplehat/EscapeOS/blob/v0.3.2/Resources/Info.plist)
- [AppGroupListing.swift](https://github.com/pwnapplehat/EscapeOS/blob/v0.3.2/EscapeOS/Engine/AppGroupListing.swift)
- [SandboxEscape.swift](https://github.com/pwnapplehat/EscapeOS/blob/v0.3.2/EscapeOS/Engine/SandboxEscape.swift)
- [worse_query.m](https://github.com/pwnapplehat/EscapeOS/blob/v0.3.2/EscapeOS/Engine/worse_query.m)
- [App entitlements](https://github.com/pwnapplehat/EscapeOS/blob/v0.3.2/EscapeOS.entitlements)

**No new user action required.** Installing the iPhone IPA or changing pairing files is not a meaningful next step for enabling native Hermès on Ultra 1/23U95. The remaining requirement is a genuinely verified Watch-side privileged writer; current status remains **NOT UNLOCKED**.
