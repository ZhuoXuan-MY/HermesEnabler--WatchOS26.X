# RO23 V25 — Definitive Poodle capability selector and ClockKit return

**Date:** 2026-11-11 · **Target:** Watch6,18 / watchOS 26.6.1 / 23U95  
**Finding:** The previously unresolved Poodle call at **0x469C0** is exactly the Objective-C selector **\`supportsPDRCapability:\`**. The matching ClockKit implementation **always returns true**. The complete Poodle restriction method therefore evaluates **restricted=true** for my observed Ultra 1 values. This is **verified offline evidence**, not an observed live call or native Hermès unlock.

## Source provenance and exact file identity

I previously uploaded the original extracted firmware archives **RO23-V14-Zeus.zip** and **RO23-V12-ClockKit.zip**. These have now been inspected directly in the analysis runtime, not inferred from a truncated console transcript.

| Mach-O | Size | SHA-256 |
|---|---:|---|
| \`NTKZeusFaceBundle\` | 663,040 bytes | \`2b34d3d411b77ee73f3892638f419eda83b7bedc4653ecf44adf7c975bbd72e4\` |
| \`ClockKit\` | 1,425,840 bytes | \`5fc1784de78830eb83808a5663c87bf2be39bca08453b5d11ddef4dcad56cce0\` |

Both binaries are **arm64_32, 32-bit Mach-O containers**. Original firmware bytes are not committed to public GitHub.

## 1. 0x469C0 is an Objective-C stub, not an opaque native function

The Poodle method (previously verified at 0x13B4) calls the stub:

\`\`\`asm
0x13DC  mov  w2, #0xA3E7
0x13E0  movk w2, #0xD5DD, lsl #16
0x13E4  bl   0x469C0
0x13E8  cbz  w0, 0x1404
\`\`\`

Using the exact Zeus Mach-O \`__TEXT,__objc_stubs\` section:

\`\`\`asm
0x469C0  adrp x1, 0x4F000
0x469C4  ldr  w1, [x1, #0xA8]
0x469C8  adrp x16, 0x48000
0x469CC  ldr  w16, [x16, #0x448]
0x469D0  br   x16
\`\`\`

The stub reads a selector reference at **0x4F0A8**. Its on-disk value is **0x04040445**, which in this verified arm64_32 image resolves to \`__TEXT,__objc_methname\` VM **0x40445**, the null-terminated string:

\`\`\`text
supportsPDRCapability:
\`\`\`

**Independent sanity checks on the same binary:**

| Zeus stub | \`__objc_selrefs\` address | Resolved selector |
|---|---|---|
| \`0x469C0\` | \`0x4F0A8\` | \`supportsPDRCapability:\` |
| \`0x43B00\` | \`0x4EAD0\` | \`deviceCategory\` |
| \`0x43480\` | \`0x4EA00\` | \`collectionType\` |

The names come from decoded selector pointers, **not heuristic matching** against a list of nearby strings.

## 2. Independent verification in matching ClockKit

\`llvm-objdump --macho --disassemble\` prints the original named method:

\`\`\`asm
-[CLKDevice supportsPDRCapability:]:
0x49C6E724  mov w0, #1
0x49C6E728  ret
\`\`\`

For this exact ClockKit implementation, the method ignores its capability argument and **returns true for every value**, including Poodle's observed \`0xD5DDA3E7\`. This does not claim every future watchOS build behaves this way.

## 3. Complete method outcome on my Ultra 1

From my V22 actual watch log: \`deviceCategory=4\`, \`collectionType=9\`, \`NTKShowHardwareSpecificFaces=false\`. In matching 23U95 firmware:

\`\`\`c
bool PoodleIsRestricted(CLKDevice *device) {
    if (device.deviceCategory == 1) return true;
    if (![device supportsPDRCapability:0xD5DDA3E7]) return true;
    if (device.collectionType == 5) return false;
    return !NTKShowHardwareSpecificFaces();
}
\`\`\`

With verified platform method behavior and measured properties:

\`\`\`text
category=4                 => does not trigger category==1 rejection
supportsPDRCapability      => true on this matching ClockKit
collectionType=9            => not 5
NTKShowHardwareSpecificFaces=false
RETURN: restricted = true
\`\`\`

The full original **Poodle class** is still not registered in the separate diagnostics App process, so this is **static bytecode/control-flow verification combined with observed device values**, **not** dynamic invocation of the original Poodle class. Separate FaceBundleManager and library-import gates still exist, and no privileged exception path has been demonstrated.

## 4. Reproducible test, without any Apple binaries in the repository

New \`scripts/ro23-v25-verify-selectors.py\` is a Python 3 *standard-library-only*, **read-only** checker for the exact matching Zeus and ClockKit Mach-O files. It:

- verifies both hard-coded SHA-256 values,
- parses Mach-O \`LC_SEGMENT\` section VM addresses,
- decodes \`ADRP X1\` / \`LDR W1\` selector stubs,
- validates \`__objc_selrefs\` references against \`__objc_methname\` strings, and
- checks ClockKit's two known method instructions \`MOV W0,#1; RET\`.

**Tested locally against both uploaded authentic files**: all three selectors resolved; ClockKit opcode verification passed. No filesystem writes or network access in the checker.

\`\`\`bash
# With existing extracted local paths — no firmware re-download or extraction needed:
ROOT="$HOME/Downloads/RO23-23U95-Static"
ZEUS="$(find "$ROOT" -type f -name NTKZeusFaceBundle -print -quit 2>/dev/null)"
CLK="$(find "$ROOT" -type f -name ClockKit -print -quit 2>/dev/null)"
python3 scripts/ro23-v25-verify-selectors.py "$ZEUS" "$CLK"
\`\`\`

Run only if independently reproducing the result is desired; no extra watch-side button or installation is needed.

## 5. What remains unresolved

The **Poodle method gate is now fully decoded**. The separate **NanoTimeKit FaceBundleManager's restricted-face exception jump stub** at \`0x55CE73DC\` is still not resolved from the uploaded standalone NanoTimeKit extraction and is the next useful research target. A stock Ultra must not be assumed to have system write permissions merely because \`supportsPDRCapability:\` returns true.

**No code injection, firmware modification, protected filesystem write, face installation, or successful native Hermès unlock.**

[Original HermesEnabler](https://github.com/pookjw/HermesEnabler) · [V24 full Poodle gate](RO23-V24-Poodle-Full-Gate.md) · [V17 manager checks](RO23-V17-FaceBundle-Loading-Chain.md).
