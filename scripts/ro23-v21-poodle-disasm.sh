#!/bin/bash
# RO23 V23: read-only offline Poodle disassembly for the verified 23U95 Zeus.
# Usage: bash scripts/ro23-v21-poodle-disasm.sh "/path/to/NTKZeusFaceBundle"
# First try llvm-objdump. When unavailable, use the macOS/Xcode otool.
# No install, download, extraction, directory creation or writes.
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo 'Usage: bash scripts/ro23-v21-poodle-disasm.sh "/path/to/NTKZeusFaceBundle"' >&2
  exit 2
fi
BINARY="$1"
if [ ! -f "$BINARY" ]; then
  echo "ERROR: no file at supplied path." >&2
  exit 2
fi

EXPECTED="2b34d3d411b77ee73f3892638f419eda83b7bedc4653ecf44adf7c975bbd72e4"
ACTUAL="$(shasum -a 256 "$BINARY" | awk '{print $1}')"
echo "File: $(basename "$BINARY")"
echo "SHA-256: $ACTUAL"
if [ "$ACTUAL" != "$EXPECTED" ]; then
  echo "ERROR: mismatched 23U95 NTKZeusFaceBundle; no cross-version analysis." >&2
  exit 1
fi

OBJ=""
if command -v llvm-objdump >/dev/null 2>&1; then
  OBJ="$(command -v llvm-objdump)"
elif [ -x /opt/homebrew/opt/llvm/bin/llvm-objdump ]; then
  OBJ="/opt/homebrew/opt/llvm/bin/llvm-objdump"
elif [ -x /usr/local/opt/llvm/bin/llvm-objdump ]; then
  OBJ="/usr/local/opt/llvm/bin/llvm-objdump"
elif command -v xcrun >/dev/null 2>&1 && xcrun --find llvm-objdump >/dev/null 2>&1; then
  OBJ="$(xcrun --find llvm-objdump)"
fi

echo "=== NTKPoodleFace +isRestrictedForDevice: 0x13B4–0x1470 (read-only) ==="
if [ -n "$OBJ" ]; then
  echo "Using LLVM: $OBJ"
  "$OBJ" --macho --disassemble \
    --start-address=0x13b4 --stop-address=0x1470 "$BINARY"
else
  # Apple otool ships with Xcode / Command Line Tools.
  # The already-verified input is a *thin arm64_32 Mach-O*.
  OTOOL=""
  if command -v xcrun >/dev/null 2>&1 && xcrun --find otool >/dev/null 2>&1; then
    OTOOL="$(xcrun --find otool)"
  elif command -v otool >/dev/null 2>&1; then
    OTOOL="$(command -v otool)"
  fi
  if [ -z "$OTOOL" ]; then
    echo "ERROR: neither llvm-objdump nor Xcode otool is available." >&2
    echo "Check xcode-select -p and xcrun --find otool; no install attempted." >&2
    exit 127
  fi

  echo "Using Xcode otool: $OTOOL (arm64_32)"
  # Filter disassembled instruction-address lines, not raw byte offsets.
  # Perl hex() works with macOS' built-in Perl. Print only the Poodle range.
  "$OTOOL" -arch arm64_32 -tvV "$BINARY" |
    perl -ne '
      if (/^\s*(?:0x)?([0-9A-Fa-f]{8,16})\s+/) {
        $addr = hex($1);
        if ($addr >= 0x13b4 && $addr < 0x1470) {
          print;
          $seen++;
        }
      }
      END {
        unless ($seen) {
          print STDERR "ERROR: otool produced no instructions in 0x13B4–0x1470. Verify tool architecture and section VM addresses.\n";
          exit 1;
        }
      }
    '
fi
echo "=== END: input binary untouched; no Watch/iPhone access ==="
