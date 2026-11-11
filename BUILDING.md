# HermesEnabler RO23 — Xcode build and update

**NOT UNLOCKED.** The merged research app is not a working native Hermès unlock.

1. Clone https://github.com/ZhuoXuan-MY/HermesEnabler--WatchOS26.X onto your Mac once.
2. Open HermesEnabler2.xcodeproj in Xcode 27.x with watchOS 26 SDK.
3. Select **HermesEnabler2** Watch scheme and the paired Apple Watch.
4. Choose your own Team and Automatically manage signing for the watch and companion targets. Replace the placeholder COMPANION_BUNDLE_IDENTIFIER (com.example.HermesEnabler) with your own consistent identifier. Configure your legitimate App Group if required. Ordinary signing does not grant Apple-private SystemGroup entitlements.
5. Press **⌘B** to build, then **⌘R** to run on the watch.
6. Open **RO23 · Ultra 1 research → Read-only diagnostics**.

For future updates run: bash scripts/ro23-update-open.sh

The script performs git pull --ff-only origin main and opens Xcode, then you can press ⌘B / ⌘R. Xcode does not automatically download GitHub commits. A ZIP extraction is not a Git clone.

23U95: the read-only research view remains visible without MG backup; upstream write/restart controls are hidden in that UI. Historical V1–V7 experimental code remains outside the compiled target.

**Validation status:** project structure and Swift syntax inspected; actual macOS Xcode compilation and watch installation not yet verified.


Note on icons: The GitHub integration uses a simple 1024×1024 placeholder icon for both app targets. The original full-size icon images remain available in the upstream project and the downloadable merged archive; replace these placeholders with the original app icons when finalizing the app's appearance.
