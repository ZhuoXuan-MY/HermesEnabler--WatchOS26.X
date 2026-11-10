# Building the sanitized RO23 Watch App

1. Open `HermesEnabler2.xcodeproj` in Xcode on your Mac.
2. Under **Targets → HermesEnabler2 → Signing & Capabilities**, choose **your own** Apple development team. The included project intentionally has no hard-coded development team.
3. Replace example bundle identifier `com.example.HermesEnablerRO23` with your own unique value.
4. Replace example App Group `group.com.example.HermesEnablerRO23` in `HermesEnabler2/HermesEnabler2.entitlements` with your own properly provisioned App Group; configure the same group in Signing & Capabilities.
5. Select an Apple Watch destination, check local SDK compatibility, and build. **No compilation test has been carried out on this sanitized archive.**
6. Never deploy with the expectation of enabling genuine Hermès faces on watchOS 23U95. This snapshot explicitly blocks protected MobileGestalt writes.

## Available diagnostics

- Check Compatibility: reports build/layout configuration.
- Direct Read Probe: tests directory and file read access only.
- Test MG Access / Create Local MG Backup: may write backups/logs **inside this app's Documents**, but does not save to the protected system cache.
- Run RO23 V1–V7 Diagnostics: opt-in. Static key inspection and permissions/XPC testing; V4 sandbox-extension consumption tests are read-only with respect to system MG cache. Logs to the app's `Documents/bqtool.log`.

## Safety boundaries

- `BQSaveGestalt`, `BQRestoreGestalt`, `BQEnableHermes`, and capability override writes return failure, with explanatory logs.
- Dangerous 23U95 direct-writer/Geod write tests have been deleted from the packaged code.
- Legacy sandbox/MCM exploratory implementation remains to support historical research. It may adjust **app-owned** temporary paths; read code and test only on devices you own.
- Do not share App Group containers, signature files, on-device logs containing identifiers, or Apple/Hermès proprietary binary assets publicly.
