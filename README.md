# Hunter - 68060 Performance Patch

**Version 1.0.1.** A 68060 performance patch for Hunter, with instruction-cache
support, Fast RAM data, terrain optimizations, optimized polygon filling,
a 7 × 9 terrain view with about 33% greater object depth range, and safe cache
handling before the intro picture.

## Requirements

- Python 3.9 or newer. No additional packages or assembler needed to patch a disk.
- Your own Hunter ADF matching the [supported checksum](FS-UAE.md#checksums).
- FS-UAE, Kickstart 3.1, a 68060, 2 MiB Chip RAM and 8 MiB Fast RAM.

## Usage

```sh
python3 hunterpatch.py "/path/to/Hunter.adf"
```

Creates `hunter-performance.adf` in the repository root. You can also use
`patch.py` directly; it works as a standalone file.

```sh
python3 patch.py "/path/to/Hunter.adf" --output "/path/to/hunter-performance.adf"
python3 patch.py "/path/to/Hunter.adf" --force
python3 patch.py --version
```

Use `--force` to replace an existing output. The original disk is never
overwritten. Boot the patched disk in DF0 with the [FS-UAE settings](FS-UAE.md).
Press Space or click the mouse to continue from the intro picture.

[Patch details](PATCH.md) · [Changelog](CHANGELOG.md) · [Sources](src)

Timo Heimonen <timo.heimonen@proton.me>· [MIT License](LICENSE)

The license covers the patch's own code and documentation. Original game disks
and Kickstart ROMs are not included.
