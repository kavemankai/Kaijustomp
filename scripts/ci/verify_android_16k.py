#!/usr/bin/env python3
"""Fail CI if an Android APK bundles ARM64 libraries incompatible with 16 KiB pages.

Only stdlib is required. Check all ELF PT_LOAD p_align values >= 16384.
Godot 4.3 Android templates use 4096-byte alignment; Godot 4.5 fixes this.
"""
import struct
import sys
import zipfile

REQUIRED = 16384


def check_elf(name: str, data: bytes) -> list[str]:
    if len(data) < 64 or data[:4] != b"\x7fELF":
        return [f"{name}: invalid ELF header"]
    if data[4] != 2 or data[5] != 1:
        return [f"{name}: expected 64-bit little-endian ELF"]
    phoff = struct.unpack_from("<Q", data, 32)[0]
    phentsize = struct.unpack_from("<H", data, 54)[0]
    phnum = struct.unpack_from("<H", data, 56)[0]
    if phentsize < 56 or phnum == 0 or phoff + phentsize * phnum > len(data):
        return [f"{name}: invalid program-header table"]
    errors: list[str] = []
    loads = 0
    for index in range(phnum):
        entry = phoff + index * phentsize
        if struct.unpack_from("<I", data, entry)[0] != 1:
            continue
        loads += 1
        alignment = struct.unpack_from("<Q", data, entry + 48)[0]
        if alignment < REQUIRED:
            errors.append(
                f"{name}: PT_LOAD[{index}] aligned at {alignment} bytes,"
                f" requires at least {REQUIRED}"
            )
    if loads == 0:
        errors.append(f"{name}: no PT_LOAD segments found")
    if not errors:
        print(f"PASS: {name} ({loads} load segments, 16 KiB compatible)")
    return errors


def main(path: str) -> int:
    with zipfile.ZipFile(path) as apk:
        names = [n for n in apk.namelist() if n.startswith("lib/arm64-v8a/") and n.endswith(".so")]
        if not names:
            print("FAIL: No ARM64 native libraries in APK", file=sys.stderr)
            return 1
        errors: list[str] = []
        for name in names:
            errors.extend(check_elf(name, apk.read(name)))
        for problem in errors:
            print("FAIL:", problem, file=sys.stderr)
        return 1 if errors else 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("Usage: verify_android_16k.py path/to/app.apk")
    sys.exit(main(sys.argv[1]))
