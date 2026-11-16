#!/usr/bin/env bash
# RO23 V27.2 — inspect confirmed BR destinations for the two different
# NanoTimeKit cache stub island entries on Watch6,18/watchOS 26.6.1/23U95.
# Offline only: no Apple Watch connection, privilege escalation, or file edits.
set -uo pipefail

DSC="$HOME/Downloads/RO23-23U95-Static/DSC/23U95__Watch6,18/System/Library/Caches/com.apple.dyld/dyld_shared_cache_arm64_32"
if (( $# > 1 )); then
  echo "Usage: $0 [path/to/23U95__Watch6,18/.../dyld_shared_cache_arm64_32]" >&2
  exit 2
fi
if (( $# == 1 )); then DSC="$1"; fi
if [[ ! -f "$DSC" ]]; then echo "ERROR: cache not found: $DSC" >&2; exit 2; fi
if [[ "$(basename "$DSC")" != dyld_shared_cache_arm64_32 || "$DSC" != *23U95__Watch6,18* ]]; then
  echo 'ERROR: only the matching Watch6,18/23U95 main arm64_32 cache is supported' >&2
  exit 2
fi
if ! command -v ipsw >/dev/null 2>&1; then
  echo 'ERROR: ipsw CLI unavailable' >&2; exit 127
fi

failures=0
run_bounded() {
  local label="$1"
  shift
  printf '\n===== %s =====\n' "$label"
  if "$@" 2>&1 | awk 'NR<=100 {print} END {if (NR>100) print "[output limited to first 100 lines]"}'; then
    :
  else
    local code=$?
    printf 'NOTE: %s failed (exit %s); no identity inferred.\n' "$label" "$code" >&2
    failures=$((failures+1))
  fi
}

echo 'RO23 V27.2 — identify actual BR target functions, not dyld stub islands'
echo 'Target: Watch6,18, watchOS 26.6.1, 23U95, arm64_32'
printf 'Source cache: %s\n' "$DSC"
echo 'The original V27.1 stub 0x55CE73DC branched to 0x49C76990.'
echo 'The independent 0x55CE731C stub branched to 0x49C2ED64.'
echo 'The two destinations are *not yet* established as names or authorizations.'

for addr in 0x49C76990 0x49C2ED64; do
  printf '\n######## ACTUAL BR DESTINATION %s ########\n' "$addr"
  run_bounded "a2s image and mapping [$addr]" ipsw dyld a2s "$DSC" "$addr" --image --mapping
  run_bounded "a2f containing function [$addr]" ipsw dyld a2f "$DSC" "$addr"
  run_bounded "a2o image-relative [$addr]" ipsw dyld a2o "$DSC" "$addr" --image-rel
  run_bounded "disass first 48 instructions [$addr]" ipsw dyld disass "$DSC" --vaddr "$addr" --count 48 --quiet
done

printf '\nCompleted: %s command(s) failed.\n' "$failures"
echo 'Read-only, offline source triage. No native Hermès face unlock claimed.'
if (( failures != 0 )); then exit 1; fi
