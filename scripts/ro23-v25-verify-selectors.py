#!/usr/bin/env python3
"""RO23 V25: confirm Poodle's ObjC stub selector and ClockKit's return value.

Read-only, stdlib-only, for the two exact verified watchOS 23U95 binaries.
Usage: python3 scripts/ro23-v25-verify-selectors.py ZEUS_BINARY CLOCKKIT_BINARY
"""
from __future__ import annotations

import hashlib
import struct
import sys
from pathlib import Path

ZEUS_SHA = "2b34d3d411b77ee73f3892638f419eda83b7bedc4653ecf44adf7c975bbd72e4"
CLOCK_SHA = "5fc1784de78830eb83808a5663c87bf2be39bca08453b5d11ddef4dcad56cce0"


def checked_file(path: Path, expected: str) -> bytes:
    data = path.read_bytes()
    digest = hashlib.sha256(data).hexdigest()
    print(f"{path.name}: {len(data)} bytes; SHA-256={digest}")
    if digest != expected:
        raise ValueError("SHA-256 mismatch: expected the exact verified 23U95 binary")
    return data


def sections(macho: bytes) -> dict[str, tuple[int, int, int]]:
    if struct.unpack_from("<I", macho)[0] != 0xFEEDFACE:
        raise ValueError("Expected a thin 32-bit Mach-O (arm64_32)")
    _, cpu, _, _, ncmds, _, _ = struct.unpack_from("<7I", macho)
    if cpu != 0x0200000C:
        raise ValueError(f"Not arm64_32: CPU type={hex(cpu)}")
    out: dict[str, tuple[int, int, int]] = {}
    offset = 28
    for _ in range(ncmds):
        if offset + 8 > len(macho):
            raise ValueError("Invalid Mach-O load commands")
        cmd, cmdsize = struct.unpack_from("<II", macho, offset)
        if cmdsize < 8 or offset + cmdsize > len(macho):
            raise ValueError("Malformed load command")
        if cmd == 1:  # LC_SEGMENT (32-bit section structures)
            nsects = struct.unpack_from("<I", macho, offset + 48)[0]
            if 56 + 68 * nsects > cmdsize:
                raise ValueError("Malformed section records")
            for i in range(nsects):
                rec = struct.unpack_from("<16s16s9I", macho, offset + 56 + 68 * i)
                sect = rec[0].split(b"\0")[0].decode("ascii", "replace")
                seg = rec[1].split(b"\0")[0].decode("ascii", "replace")
                addr, size, fileoff = rec[2:5]
                out[seg + "," + sect] = (addr, size, fileoff)
        offset += cmdsize
    return out


def vm_read(data: bytes, sec: dict[str, tuple[int, int, int]],
            addr: int, n: int) -> bytes:
    for vm, size, fileoff in sec.values():
        if vm <= addr and addr + n <= vm + size:
            off = fileoff + addr - vm
            if off + n > len(data):
                break
            return data[off:off + n]
    raise ValueError(f"VM address {addr:#x} not within a file-backed section")


def stub_selector(data: bytes, sec: dict[str, tuple[int, int, int]],
                  addr: int) -> str:
    first, second = struct.unpack("<II", vm_read(data, sec, addr, 8))
    if (first & 0x9F00001F) != 0x90000001:
        raise ValueError(f"Stub {addr:#x} lacks ADRP X1")
    if (second & 0xFFC003FF) != 0xB9400021:
        raise ValueError(f"Stub {addr:#x} lacks LDR W1,[X1,#imm]")
    delta = (((first >> 5) & 0x7FFFF) << 2) | ((first >> 29) & 3)
    if delta & (1 << 20):
        delta -= 1 << 21
    ref = (addr & ~0xFFF) + (delta << 12) + (((second >> 10) & 0xFFF) * 4)
    raw = struct.unpack("<I", vm_read(data, sec, ref, 4))[0]
    # Exact verified 23U95 arm64_32 image: on-disk chained pointer 0x04xxxxxx.
    # The low 24 bits resolve to the selector's VM address; validate it first.
    sel_vm = raw & 0x00FFFFFF
    meth_vm, meth_size, _ = sec["__TEXT,__objc_methname"]
    if not meth_vm <= sel_vm < meth_vm + meth_size:
        raise ValueError(f"Selector {raw:#x} not in __objc_methname")
    fragment = vm_read(data, sec, sel_vm, min(256, meth_vm + meth_size - sel_vm))
    name = fragment.split(b"\0", 1)[0].decode("utf-8")
    print(f"{addr:#x} -> selref {ref:#x} -> encoded {raw:#x} -> "
          f"{sel_vm:#x} -> {name}")
    return name


def main() -> int:
    if len(sys.argv) != 3:
        print('Usage: python3 ro23-v25-verify-selectors.py "NTKZeusFaceBundle" "ClockKit"',
              file=sys.stderr)
        return 2
    zeus = checked_file(Path(sys.argv[1]), ZEUS_SHA)
    clock = checked_file(Path(sys.argv[2]), CLOCK_SHA)
    zs, cs = sections(zeus), sections(clock)
    for addr, name in [
        (0x469C0, "supportsPDRCapability:"),
        (0x43B00, "deviceCategory"),
        (0x43480, "collectionType"),
    ]:
        if stub_selector(zeus, zs, addr) != name:
            raise ValueError(f"Unexpected selector at {addr:#x}")
    # Matching ClockKit symbol list independently maps this implementation to
    # -[CLKDevice supportsPDRCapability:] at 0x49C6E724.
    insns = vm_read(clock, cs, 0x49C6E724, 8)
    if insns != bytes.fromhex("20008052c0035fd6"):
        raise ValueError("ClockKit implementation differs from MOV W0,#1; RET")
    print("ClockKit -[CLKDevice supportsPDRCapability:] 0x49C6E724: MOV W0,#1; RET")
    print("For measured category=4, collectionType=9, hardware=false: Poodle restricted=true.")
    print("NO system, firmware or watchface files modified.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, struct.error, UnicodeError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
