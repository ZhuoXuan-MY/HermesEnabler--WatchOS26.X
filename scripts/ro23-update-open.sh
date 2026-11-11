#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if ! git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then echo "Clone the GitHub repository first." >&2; exit 1; fi
if [[ -n "$(git -C "$ROOT" status --porcelain)" ]]; then echo "Uncommitted changes; commit or stash first." >&2; exit 1; fi
if [[ "$(git -C "$ROOT" branch --show-current)" != "main" ]]; then echo "Switch to main first." >&2; exit 1; fi
git -C "$ROOT" pull --ff-only origin main
open "$ROOT/HermesEnabler2.xcodeproj"
echo "Select HermesEnabler2 Watch scheme, then Command+B and Command+R."
