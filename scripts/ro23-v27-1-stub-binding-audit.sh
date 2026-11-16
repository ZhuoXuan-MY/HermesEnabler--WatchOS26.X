#!/usr/bin/env bash
# RO23 V27.1 — offline dyld stub/binding audit on Watch6,18 / 23U95.
# Never contacts a device, patches firmware, or writes protected files.
# ipsw may build local indexes; the input cache itself is read-only.
set -uo pipefail

DSC="$HOME/Downloads/RO23-23U95-Static/DSC/23U95__Watch6,18/System/Library/Caches/com.apple.dyld/dyld_shared_cache_arm64_32"
custom=0
extended=0
for arg in "$@"; do
  case "$arg" in
    --extended) extended=1 ;;
    -h|--help)
      echo 'Usage: ro23-v27-1-stub-binding-audit.sh [path/to/dyld_shared_cache_arm64_32] [--extended]'
      exit 0 ;;
    -*) echo "ERROR: unknown flag $arg" >&2; exit 2 ;;
    *) if (( custom )); then echo 'ERROR: only one cache path may be given' >&2; exit 2; fi
       DSC="$arg"; custom=1 ;;
  esac
done

if [[ ! -f "$DSC" ]]; then echo "ERROR: no shared cache at $DSC" >&2; exit 2; fi
if [[ "$(basename "$DSC")" != dyld_shared_cache_arm64_32 ]]; then
  echo 'ERROR: requires the arm64_32 main dyld shared cache' >&2; exit 2
fi
if [[ "$DSC" != *23U95* || "$DSC" != *Watch6,18* ]]; then
  echo 'ERROR: path must identify Watch6,18 / 23U95; do not apply build-specific VM addresses to another firmware.' >&2
  exit 2
fi
if ! command -v ipsw >/dev/null 2>&1; then
  echo 'ERROR: ipsw CLI unavailable' >&2; exit 127
fi

failures=0
limited_run() {
  local label="$1"
  shift
  printf '\n===== %s =====\n' "$label"
  if "$@" 2>&1 | awk 'NR<=80 { print } END { if(NR>80) print "[first 80 lines only]" }'; then
    :
  else
    local code=$?
    printf 'NOTE: %s failed (exit %s); no symbol identity inferred.\n' "$label" "$code" >&2
    failures=$((failures+1))
  fi
}

# In extended mode, list possible stub/import clues, without pretending that
# an import name alone maps to a specific stub VM address.
filtered_inventory() {
  local label="$1"
  shift
  printf '\n===== %s =====\n' "$label"
  if "$@" 2>&1 | awk '{
    s=tolower($0)
    if (s ~ /55ce73dc|55ce731c|os_variant|internal_ui|restrictedface|isrestrictedfordevice|poodle/) {
      if (++hits<=80) print
    }
  } END {
    if (hits==0) print "[no matching output; NOT evidence of absence]"
    if (hits>80) print "[first 80 matching lines only]"
  }'; then
    :
  else
    local code=$?
    printf 'NOTE: %s failed (exit %s).\n' "$label" "$code" >&2
    failures=$((failures+1))
  fi
}

echo 'RO23 V27.1: 23U95 restricted-face exception / internal-build stub audit'
printf 'Source DSC: %s\n' "$DSC"
printf 'Extended import inventory: %s\n' "$extended"
echo 'Addresses are unslid V18/V27 evidence, not portable to other builds.'
for addr in 0x55CE73DC 0x55CE731C; do
  printf '\n######## stub %s ########\n' "$addr"
  limited_run "a2s image+mapping [$addr]" ipsw dyld a2s "$DSC" "$addr" --image --mapping
  limited_run "a2f [$addr]" ipsw dyld a2f "$DSC" "$addr"
  limited_run "a2o image-relative [$addr]" ipsw dyld a2o "$DSC" "$addr" --image-rel
  limited_run "disass 16 [$addr]" ipsw dyld disass "$DSC" --vaddr "$addr" --count 16 --quiet
done

# Verify caller context independently. A stub lookup alone does not show that
# FaceBundleManager allows an ordinary import/add operation.
for caller in 0x544B0F94 0x544B1164; do
  limited_run "NanoTimeKit call site [$caller]" ipsw dyld disass "$DSC" --vaddr "$caller" --count 12 --quiet
done

if (( extended )); then
  echo 'Extended inventories may be expensive on a multi-GB shared cache.'
  filtered_inventory 'NanoTimeKit Mach-O stubs' ipsw dyld macho "$DSC" NanoTimeKit --stubs
  filtered_inventory 'NanoTimeKit imports' ipsw dyld imports "$DSC" --image NanoTimeKit
  echo 'A plausible imported name is not a proven address-to-symbol binding.'
fi

printf '\nCompleted with %s failed command(s).\n' "$failures"
echo 'No watch connection, exploit, protected cache write, or Hermès face activation was attempted.'
if (( failures > 0 )); then exit 1; fi
