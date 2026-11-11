#!/usr/bin/env bash
# RO23 V27.3 — read-only ClockKit snapshot-service initializer and
# NanoTimeKit face-add gate mapping on Watch6,18 / watchOS 26.6.1 / 23U95.
# DOES NOT change a watch, jailbreak, write system caches, or install faces.
set -uo pipefail

DSC="$HOME/Downloads/RO23-23U95-Static/DSC/23U95__Watch6,18/System/Library/Caches/com.apple.dyld/dyld_shared_cache_arm64_32"
if (( $# > 1 )); then
  printf 'Usage: %s [matching 23U95 Watch6,18 main dyld cache]\n' "$0" >&2
  exit 2
fi
if (( $# == 1 )); then DSC="$1"; fi
if [[ ! -f "$DSC" ]]; then
  printf 'ERROR: matching cache not found: %s\n' "$DSC" >&2
  exit 2
fi
if [[ "$(basename "$DSC")" != dyld_shared_cache_arm64_32 || "$DSC" != *23U95__Watch6,18* ]]; then
  echo "ERROR: requires the matching Watch6,18 / 23U95 arm64_32 main cache." >&2
  exit 2
fi
if ! command -v ipsw >/dev/null 2>&1; then
  echo "ERROR: ipsw CLI unavailable." >&2
  exit 127
fi

failures=0
bounded() {
  local label="$1"
  shift
  printf '\n===== %s =====\n' "$label"
  if "$@" 2>&1 | awk 'NR <= 110 { print } END { if (NR > 110) print "[first 110 lines only]" }'; then
    :
  else
    local code=$?
    printf 'NOTE: %s failed (exit %s). Do not infer its result.\n' "$label" "$code" >&2
    failures=$((failures+1))
  fi
}

echo "RO23 V27.3 — Snapshot Service initializer and separate face-add gates"
printf 'Firmware: Watch6,18 / 23U95; source DSC: %s\n' "$DSC"
echo "Verified in V27.2: _CLKIsFaceSnapshotService @ 0x49C76990, end 0x49C769C0."
echo "Verified in V27.2: _CLKInternalBuild @ 0x49C2ED64, end 0x49C2ED94."
echo "IMPORTANT: preceding V27.2 --count 48 extended into unrelated adjacent functions."
echo "This run follows the snapshot-service initialization call at 0x49C99CFC."
echo "It also samples distinct _NTKCanAddWatchFace validation stages."

bounded 'CLK snapshot-service initializer: symbol' ipsw dyld a2s "$DSC" 0x49C99CFC --image --mapping
bounded 'CLK snapshot-service initializer: function bounds' ipsw dyld a2f "$DSC" 0x49C99CFC
bounded 'CLK snapshot-service initializer: first 48 instructions' ipsw dyld disass "$DSC" --vaddr 0x49C99CFC --count 48 --quiet

bounded 'NanoTimeKit add-to-library function entry: symbol' ipsw dyld a2s "$DSC" 0x54602E48 --image --mapping
bounded 'NanoTimeKit add-to-library entry window' ipsw dyld disass "$DSC" --vaddr 0x54602E48 --count 28 --quiet
bounded 'NanoTimeKit availability window' ipsw dyld disass "$DSC" --vaddr 0x54602FC0 --count 24 --quiet
bounded 'NanoTimeKit restricted-face window' ipsw dyld disass "$DSC" --vaddr 0x54602FFC --count 24 --quiet

printf '\nCompleted: %s failed command(s).\n' "$failures"
echo "This only maps static decision points. No ordinary import success or unlock is implied."
if (( failures > 0 )); then exit 1; fi
