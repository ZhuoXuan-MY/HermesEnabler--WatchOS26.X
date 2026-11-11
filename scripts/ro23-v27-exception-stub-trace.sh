#!/usr/bin/env bash
# RO23 V27 — bounded, read-only symbol-stub triage on the owner's existing
# Watch6,18 / 23U95 dyld shared cache. Does NOT run exploits or contact devices.
# ipsw may create its own local lookup index; the input cache is not modified.
set -uo pipefail

DSC="$HOME/Downloads/RO23-23U95-Static/DSC/23U95__Watch6,18/System/Library/Caches/com.apple.dyld/dyld_shared_cache_arm64_32"
if [ "$#" -gt 0 ]; then DSC="$1"; fi
if [ ! -f "$DSC" ]; then
  echo "ERROR: 23U95 dyld cache not found: $DSC" >&2
  exit 2
fi
if ! command -v ipsw >/dev/null 2>&1; then
  echo "ERROR: ipsw CLI is unavailable." >&2
  exit 127
fi

echo "RO23 V27 — NanoTimeKit restricted-face exception stub triage"
printf 'Input DSC: %s\n' "$DSC"
echo "Two separate cache stubs; neither is a confirmed entitlement or unlock."

failures=0
limited_run() {
  local label="$1"
  shift
  printf '\n===== %s =====\n' "$label"
  if "$@" 2>&1 | awk 'NR <= 80 { print } END { if (NR > 80) print "[output limited to 80 lines]" }'; then
    :
  else
    local code=$?
    printf 'NOTE: operation failed (%s). No symbol identity inferred.\n' "$code" >&2
    failures=$((failures + 1))
  fi
}

for addr in 0x55CE73DC 0x55CE731C; do
  printf '\n######## target %s ########\n' "$addr"
  limited_run "a2f: containing function" ipsw dyld a2f "$DSC" "$addr"
  limited_run "a2o: offset and mapping" ipsw dyld a2o "$DSC" "$addr"
  limited_run "disass: first 12 instructions" ipsw dyld disass "$DSC" --vaddr "$addr" --count 12 --quiet
done

echo
printf 'Completed triage: %s command(s) failed.\n' "$failures"
echo "A __TEXT_STUBS ? result means unresolved; do not infer a private API name."
echo "No Apple Watch, iPhone, protected cache, or original firmware files changed."
if [ "$failures" -ne 0 ]; then exit 1; fi
