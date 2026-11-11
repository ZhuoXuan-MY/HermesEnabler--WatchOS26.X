# Attribution, provenance, and modification notice

## Original project and author

This work is derived from [HermesEnabler / HermesEnabler 2](https://github.com/pookjw/HermesEnabler), **originally created by Jinwoo Kim (GitHub: [@pookjw](https://github.com/pookjw))**.

The original work is MIT-licensed. **Copyright (c) 2026 Jinwoo Kim.** The accompanying `LICENSE` text is copied from the upstream project without changing its original copyright line. The upstream project also incorporates work from [Gester](https://github.com/sasobhabha/Gester), for which the existing `HermesEnabler2/Gester-LICENSE.txt` must remain intact when its code is redistributed.

## RO23 derivative investigation and local changes

This independent research project documents experiments performed by **[@ZhuoXuan-MY](https://github.com/ZhuoXuan-MY)** on an Apple Watch Ultra (first generation), `Watch6,18` / `n199ap`, watchOS `26.6.1`, build `23U95`.

The original software was locally modified to conduct experimental on-device diagnostics, including MobileGestalt cache structure analysis, backup validation, MCM flag and SystemGroup entitlement checks, sandbox permission probing, Mach service discovery, read-only XPC requests, and direct-versus-helper comparisons. The study additionally involved host-only static analysis of native 23U95 Apple binaries, including MobileGestaltHelper, libMobileGestalt, the Hermès 2025 FaceBundle, NanoTimeKit, and ClockKit.

Technical proposals, scripts, some code and research reports were developed with AI assistance; the on-device tests were run by the device owner. These experimental changes do not replace, imply authorship of, or imply endorsement by the upstream project's author.

## Research limitations

- Neither the original author nor Apple/Hermès is affiliated with or endorses this derivative research.
- No successful native Hermès activation was demonstrated on the tested watchOS 26.6.1 device.
- The local snapshot contains a previously superseded `23U95` write-offset hypothesis (`0x670` and `0x16B6`). This experimental branch is unsafe to distribute as a working unlock until disabled/removed.
- Research output should distinguish on-device logs, native watchOS binary inspection, third-party references, and hypotheses.

## Intellectual property boundaries

The upstream software's MIT License does **not** grant redistribution rights to Apple's watchOS firmware, extracted private dynamic libraries, face assets, other system binaries, or the Hermès name and logos as product branding. Do not include or publish extracted proprietary binaries in this GitHub repository merely because they were used in the investigation.

## Further reading

- [Original HermesEnabler](https://github.com/pookjw/HermesEnabler)
- [HermesEnabler Issue #17 — Ultra 1 investigation](https://github.com/pookjw/HermesEnabler/issues/17)
- [Other researchers' Issue #7](https://github.com/pookjw/HermesEnabler/issues/7)
- [Gester](https://github.com/sasobhabha/Gester)

A contribution to this derivative should preserve appropriate upstream attribution and license notices for all code reused.


RO23 addition: HermesEnabler 2 original developer Jinwoo Kim (@pookjw); RO23 watchOS 26.6.1 research and device logs by ZhuoXuan-MY with AI-assisted analysis. Non-official. Preserve upstream MIT and Gester notices. No stock Ultra 1 unlock is claimed.
