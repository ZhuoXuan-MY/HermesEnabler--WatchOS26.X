#!/bin/bash
# RO23 V24: read-only exact Poodle restriction disassembly, matching 23U95.
# Usage: bash scripts/ro23-v21-poodle-disasm.sh "/path/to/NTKZeusFaceBundle"
# No downloads, modifications, clones or watch/phone communication.
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
  echo "ERROR: firmware hash mismatch; aborting cross-build analysis." >&2
  exit 1
fi

# llvm-objdump's Mach-O mode may ignore --start-address and --stop-address.
# In either backend, ALWAYS filter instruction lines by the actual hex PC.
filter_poodle() {
  perl -ne '
    if (/^\s*(?:0x)?([0-9A-Fa-f]{4,16})(?::|\s)/) {
      $pc = hex($1);
      if ($pc >= 0x13b4 && $pc < 0x1428) {
        print;
        $count++;
      }
    }
    END {
      if (!$count) {
        print STDERR "ERROR: no instruction lines found in Poodle range 0x13B4–0x1424.\n";
        exit 1;
      }
    }
  '
}

OBJ=""
if command -v llvm-objdump >/dev/null 2>&1; then
  OBJ="$(command -v llvm-objdump)"
elif [ -x /opt/homebrew/opt/llvm/bin/llvm-objdump ]; then
  OBJ=/opt/homebrew/opt/llvm/bin/llvm-objdump
elif [ -x /usr/local/opt/llvm/bin/llvm-objdump ]; then
  OBJ=/usr/local/opt/llvm/bin/llvm-objdump
elif command -v xcrun >/dev/null 2>&1 && xcrun --find llvm-objdump >/dev/null 2>&1; then
  OBJ="$(xcrun --find llvm-objdump)"
fi

echo "=== NTKPoodleFace +isRestrictedForDevice: 0x13B4–0x1424 (29 instructions) ==="
if [ -n "$OBJ" ]; then
  echo "Using LLVM: $OBJ"
  "$OBJ" --macho --disassemble \
    --start-address=0x13b4 --stop-address=0x1428 "$BINARY" | filter_poodle
else
  OTOOL=""
  if command -v xcrun >/dev/null 2>&1 && xcrun --find otool >/dev/null 2>&1; then
    OTOOL="$(xcrun --find otool)"
  elif command -v otool >/dev/null 2>&1; then
    OTOOL="$(command -v otool)"
  fi
  if [ -z "$OTOOL" ]; then
    echo "ERROR: neither llvm-objdump nor Xcode otool is available." >&2
    exit 127
  fi
  echo "Using Xcode otool: $OTOOL"
  "$OTOOL" -arch arm64_32 -tvV "$BINARY" | filter_poodle
fi
echo "=== END: no binary changes and no watch/iPhone access ==="
