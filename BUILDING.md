# HermesEnabler RO23 — Xcode build and update

**NOT UNLOCKED.** The merged research app is not a working native Hermès unlock.

1. Clone https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X onto a Mac once.
2. Open HermesEnabler2.xcodeproj in Xcode 27.x with watchOS 26 SDK.
3. Select **HermesEnabler2** Watch scheme and the paired Apple Watch.
4. Choose an authorized Apple Developer Team and Automatically manage signing for the watch and companion targets. Replace the placeholder COMPANION_BUNDLE_IDENTIFIER (com.example.HermesEnabler) with a consistent owned identifier. Configure an authorized App Group if required. Ordinary signing does not grant Apple-private SystemGroup entitlements.
5. Press **⌘B** to build, then **⌘R** to run on the watch.
6. Open **RO23 · Ultra 1 research → Read-only diagnostics**.

For future updates run: bash scripts/ro23-update-open.sh

The script performs git pull --ff-only origin main and opens Xcode, then press ⌘B / ⌘R. Xcode does not automatically download GitHub commits. A ZIP extraction is not a Git clone.

23U95: the read-only research view remains visible without MG backup; upstream write/restart controls are hidden in that UI. Historical V1–V7 experimental code remains outside the compiled target.

**Validation status:** project structure and Swift syntax inspected; actual macOS Xcode compilation and watch installation not yet verified.


Note on icons: The GitHub integration uses a simple 1024×1024 placeholder icon for both app targets. The original full-size icon images remain available in the upstream project and the downloadable merged archive; replace these placeholders with the original app icons when finalizing the app's appearance.


## RO23 build fix — Xcode Signing / Boolean (11 Nov 2026)

The watchOS 26 research configuration does **not** need the Apple App Groups entitlement. The previous example entitlement `group.com.example.HermesEnabler` could not be provisioned for the signing account. The watch target's `HermesEnabler2.entitlements` is intentionally an empty plist, avoiding App Group provisioning errors. No elevated Apple-private entitlement is requested.

This is a **read-only research configuration**. It does not grant MobileGestalt system-group write access. Upstream watchOS 27 functionality that depends on an App Group is not guaranteed to function with this research profile. To use those separately, restore/configure a legitimately provisioned App Group with an appropriate development team, and review the original upstream requirements; do not reuse the placeholder group.

The Objective-C source was also updated to rename `Boolean(...)` to `RO23ReadBool(...)`. `Boolean` is already a CoreFoundation typedef and caused compiler errors.

### After updating the same Git clone

1. Run `git pull --ff-only origin main` (or `bash scripts/ro23-update-open.sh` when clean).
2. In Xcode set a valid Team for **both the iPhone companion and watch app** under **Signing & Capabilities**, and enable **Automatically manage signing**. A unique bundle ID owned by the team is required; ensure the companion and watch IDs match the project's expected structure. Remove any leftover manually added **App Groups** capability in the local Xcode target UI if present.
3. Xcode menu **Product → Clean Build Folder** (`Shift+⌘K`), then `⌘B` and `⌘R`.

If the next build reports a *different* error, provide the exact text; this patch is static-source verified, **not** verified via a macOS Xcode build.


### Device build verification update (2026-11-11)
The device owner subsequently supplied Xcode-run logs for V13, V14.1 and MG snapshot in the merged watch app. These three flows now have **user-reported real-watch execution evidence** on 23U95, including the corrected RO23ReadBool helper. This does not verify an unlocked watchface or successful system modifications.
