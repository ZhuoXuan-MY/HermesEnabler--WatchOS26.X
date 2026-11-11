#!/usr/bin/env python3
"""RO23 V20: inspect local .watchface ZIP metadata without extraction or writes.

Usage:
    python3 scripts/ro23-inspect-watchface.py "Hermès Circulaire.watchface" \
        "Modular Ultra.watchface"

This reports only a safe subset of standard metadata, not complications'
personal content, full paths, photographs, account information or tokens.
Requires only Python 3's standard library. NEVER edits the input files.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import sys
import zipfile

MAX_JSON_BYTES = 2 * 1024 * 1024
MAX_ENTRIES = 1024


def display_value(value: object) -> str:
    """Show only short, scalar, non-private identifiers, not nested JSON."""
    if isinstance(value, (str, int, float)) and not isinstance(value, bool):
        return str(value)[:240]
    return "(not present or not a scalar)"


def read_manifest(zf: zipfile.ZipFile, name: str) -> tuple[object | None, str]:
    """Read a fixed file in memory; reject huge JSON; never extract ZIP files."""
    try:
        info = zf.getinfo(name)
    except KeyError:
        return None, f"{name}: absent"
    if info.file_size > MAX_JSON_BYTES:
        return None, f"{name}: too large to inspect safely"
    if info.is_dir():
        return None, f"{name}: unexpected directory"
    try:
        with zf.open(info, "r") as file:
            data = file.read(MAX_JSON_BYTES + 1)
        if len(data) > MAX_JSON_BYTES:
            return None, f"{name}: exceeds safe read limit"
        return json.loads(data.decode("utf-8")), f"{name}: valid JSON"
    except (json.JSONDecodeError, UnicodeDecodeError, OSError, RuntimeError, zipfile.BadZipFile) as exc:
        return None, f"{name}: cannot parse ({type(exc).__name__})"


def file_digest(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fp:
        for piece in iter(lambda: fp.read(1024 * 1024), b""):
            h.update(piece)
    return h.hexdigest()


def inspect(path: Path) -> tuple[str, str, str] | None:
    print(f"\n=== {path.name} ===")
    if not path.is_file():
        print("ERROR: file not found")
        return None
    try:
        print(f"File size: {path.stat().st_size} bytes")
        print(f"SHA-256: {file_digest(path)}")
        if not zipfile.is_zipfile(path):
            print("ERROR: not a valid ZIP-format .watchface")
            return None
        with zipfile.ZipFile(path) as zf:
            names = zf.namelist()
            if len(names) > MAX_ENTRIES:
                print("ERROR: too many archive entries")
                return None
            print(f"ZIP entries: {len(names)}")
            print(f"Has snapshot.png: {'yes' if 'snapshot.png' in names else 'no'}")
            print(f"Has Resources/: {'yes' if any(n.startswith('Resources/') for n in names) else 'no'}")
            face, face_status = read_manifest(zf, "face.json")
            meta, meta_status = read_manifest(zf, "metadata.json")
            print(face_status)
            print(meta_status)
            if not isinstance(face, dict):
                print("Cannot identify a face; no conclusion about device compatibility.")
                return None
            print("face.json top-level keys: " + ", ".join(sorted(str(x) for x in face.keys())[:30]))
            bundle = display_value(face.get("bundle id"))
            analytics = display_value(face.get("analytics id"))
            face_type = display_value(face.get("face type"))
            print("Bundle ID: " + bundle)
            print("Analytics ID: " + analytics)
            print("Face Type: " + face_type)
            # The JSON "face type" is not automatically the internal NTKFaceStyle value.
            if isinstance(meta, dict):
                print("metadata.json keys: " + ", ".join(sorted(str(x) for x in meta.keys())[:30]))
                names = meta.get("complications_names")
                if isinstance(names, dict):
                    print(f"Complication slot count: {len(names)} (details withheld)")
            print("Interpretation: file metadata only; no proof of FaceBundle loading or unlock.")
            return (bundle, analytics, face_type)
    except (OSError, RuntimeError, zipfile.BadZipFile) as exc:
        print(f"ERROR: {type(exc).__name__}: cannot read archive")
        return None


def main() -> int:
    if len(sys.argv) < 2:
        print('Usage: python3 scripts/ro23-inspect-watchface.py "file.watchface" ["control.watchface" ...]')
        print("Read-only; only filename, size, SHA-256 and selected safe identifiers appear.")
        return 2
    rows = [(Path(s).expanduser().name, inspect(Path(s).expanduser())) for s in sys.argv[1:]]
    if len(rows) > 1:
        print("\n=== COMPARISON (identifiers only) ===")
        for name, identifiers in rows:
            if identifiers is None:
                print(f"{name}: not readable")
            else:
                print(f"{name}: bundle={identifiers[0]!r}, analytics={identifiers[1]!r}, type={identifiers[2]!r}")
    print("\nNO FILES WERE MODIFIED. NO WATCH FACE WAS IMPORTED.")
    return 0 if any(result is not None for _, result in rows) else 1


if __name__ == "__main__":
    raise SystemExit(main())
