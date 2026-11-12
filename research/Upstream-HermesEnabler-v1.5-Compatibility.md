# HermesEnabler upstream v1.5 — compatibility audit for Watch6,18 / 23U95

**Research target:** Apple Watch Ultra, first generation (`Watch6,18 / n199ap`), watchOS 26.6.1 (`23U95`).  
**Upstream release:** [pookjw/HermesEnabler v1.5](https://github.com/pookjw/HermesEnabler/releases/tag/1.5), published **2026-11-12 01:38:06 UTC / 09:38:06 Beijing Time (UTC+08:00)**. Latest inspected upstream `main` revision: [`e9e7b913`](https://github.com/pookjw/HermesEnabler/commit/e9e7b913793e47d88af3d27885db5dfbddac38a4) (2026-11-12 01:34:19 UTC).

**Assessment method:** directly inspected the public GitHub v1.5 release, upstream `README.md`, `HermesEnabler2/BQCore.m`, `MGOffsets.plist`, `MGDefaults.plist`, upstream [PR #51](https://github.com/pookjw/HermesEnabler/pull/51), [PR #52](https://github.com/pookjw/HermesEnabler/pull/52) and relevant original commit patches. Compared their supported-build scope and write primitive with the known evidence in this repository. **No system files were written, no IPA was installed, and no upstream code was merged into the `23U95` research branch.**

## 1. What's new in upstream release 1.5?

The upstream release notes list:

1. **watchOS 27.2 beta 1** layout for build **`24S5112a`**.
2. Ultra face screen-size layout choices.
3. New MobileGestalt backup library: initial, manual, automatic, imported backups.
4. Apple Watch ↔ iPhone backup transfer, including iPhone import/export.
5. Post-write byte verification, better backup integrity checks, safer restore and recovery fallbacks.
6. iPhone companion UI changes and translations.

The upstream release includes an IPA, but the [upstream README](https://github.com/pookjw/HermesEnabler/blob/main/README.md) explicitly says supported **watchOS 27.0–27.3 beta 1**. That published compatibility range must not be extrapolated to watchOS 26.6.1.

The upstream [PR #52](https://github.com/pookjw/HermesEnabler/pull/52) reports Hermès activation on **Apple Watch Series 10 `Watch7,9`**, `24S5112a`, **not** on first-generation Apple Watch Ultra `Watch6,18` or `23U95`. Upstream research also marks the build's advanced `RecoveryVerified` capability as **false**.

## 2. Does the new write verification remove the watchOS 26 EPERM blocker?

**No.** The inspected latest upstream `HermesEnabler2/BQCore.m` still uses:

```c
int fd = open(path.fileSystemRepresentation, O_RDWR | O_CLOEXEC | O_NOFOLLOW);
```

in `bq_write_data`. It then uses that primitive inside `BQSaveGestalt`. The 2026-11-12 [`e81b33c` backup/write verification change](https://github.com/pookjw/HermesEnabler/commit/e81b33c49a5ffca36b74c528541ff5f8abe484e1) adds **pre-write bytes capture, readback comparison, and rollback attempts if an apparently successful write did not persist**. Those are safety and integrity measures **after write permission is available**, not a source of new write permission.

Most decisively, the merged [PR #51](https://github.com/pookjw/HermesEnabler/pull/51) expressly says its goal is to improve backup management **without changing the existing MobileGestalt modification mechanism**.

On the actual Ultra 1 / `23U95`, the previously observed `open(O_RDWR)` failed with **`EPERM`**, so a new readback/rollback check cannot make the initial protected write succeed. Moreover, latest upstream `MGOffsets.plist` lists builds `24R359`, `24R364`, `24R365`, `24S118`, `24S132`, `24S5112a`, `24S5284h` and **does not include `23U95`**.

The 23U95 native Hermès 2025 and Circulaire/Poodle eligibility checks independently remain unresolved; a hypothetical write fix alone would not prove native face activation.

## 3. Integration decision for this fork

**Do not blindly merge upstream v1.5 into the `Watch6,18 / 23U95` research branch.** It changes the app's backup model, watch/phone navigation, and layout configuration for watchOS 27, but supplies no verified 23U95 protected SystemGroup write capability. A bulk merge could also regress the existing read-only 23U95 safety guards or bury study-specific diagnostics without addressing the stated unlock goal.

**Safe opportunities (future only):** port individually reviewed read-only/backup integrity improvements when there is a concrete need; validate them separately from write capability and avoid exposing disabled 23U95 modifications. Do not present upstream `HermesEnabler.ipa` as compatible with the target Ultra 1.

**Outcome:** `BLOCKED`, `NOT UNLOCKED` unchanged. This record is a **source/release audit only**, not a new on-device test, patch, or proof of unlocking.

## Primary sources

- [Official release v1.5](https://github.com/pookjw/HermesEnabler/releases/tag/1.5)
- [Official README: supported watchOS 27.0–27.3 beta 1](https://github.com/pookjw/HermesEnabler/blob/main/README.md)
- [PR #51: backup management, unchanged MG modification mechanism](https://github.com/pookjw/HermesEnabler/pull/51)
- [PR #52: successful `Watch7,9 / 24S5112a` report](https://github.com/pookjw/HermesEnabler/pull/52)
- [Verified write/rollback change](https://github.com/pookjw/HermesEnabler/commit/e81b33c49a5ffca36b74c528541ff5f8abe484e1)
- [Latest upstream BQCore.m](https://github.com/pookjw/HermesEnabler/blob/main/HermesEnabler2/BQCore.m)
- [Latest upstream MGOffsets.plist](https://github.com/pookjw/HermesEnabler/blob/main/HermesEnabler2/MGOffsets.plist)
