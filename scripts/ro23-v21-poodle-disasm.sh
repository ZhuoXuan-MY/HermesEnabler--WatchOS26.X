#!/bin/bash
# RO23 V21: read-only offline Poodle restriction disassembly for known 23U95 Zeus.
# Usage: bash scripts/ro23-v21-poodle-disasm.sh "/path/to/NTKZeusFaceBundle"
# No downloads, new folders, writes, or watch/phone communications.
set -eu

if [ "$#" -ne 1 ]; then
  echo 'Usage: bash scripts/ro23-v21-poodle-disasm.sh "/path/to/NTKZeusFaceBundle"' >&2
  exit 2
fi
BINARY="$1"
if [ ! -f "$BINARY" ]; then
  echo "ERROR: no file at the supplied path." >&2
  exit 2
fi
EXPECTED="2b34d3d411b77ee73f3892638f419eda83b7bedc4653ecf44adf7c975bbd72e4"
ACTUAL="$(shasum -a 256 "$BINARY" | awk '{print $1}')"
echo "File: $(basename "$BINARY")"
echo "SHA-256: $ACTUAL"
if [ "$ACTUAL" != "$EXPECTED" ]; then
  echo "ERROR: not the matching 23U95 NTKZeusFaceBundle binary; refusing to mix firmware versions." >&2
  exit 1
fi
if command -v llvm-objdump >/dev/null 2>&1; then
  OBJ="$(command -v llvm-objdump)"
elif [ -x /opt/homebrew/opt/llvm/bin/llvm-objdump ]; then
  OBJ=/opt/homebrew/opt/llvm/bin/llvm-objdump
elif [ -x /usr/local/opt/llvm/bin/llvm-objdump ]; then
  OBJ=/usr/local/opt/llvm/bin/llvm-objdump
else
  echo "ERROR: llvm-objdump not found. Install an LLVM build with arm64_32 Mach-O support." >&2
  exit 127
fi
echo "Using: $OBJ"
echo "=== NTKPoodleFace +isRestrictedForDevice: 0x13B4–0x1470 (read-only) ==="
"$OBJ" --macho --disassemble --start-address=0x13b4 --stop-address=0x1470 "$BINARY"
echo "=== END: no source or system files changed ==="
