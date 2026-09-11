# FS-UAE settings

Use a PAL A1200 / Blizzard 1260 configuration with Kickstart 3.1,
2 MiB Chip RAM and the accelerator's default memory. Replace the disk and ROM paths:

```ini
[fs-uae]
amiga_model = A1200
accelerator = blizzard-1260
accelerator_rom = /path/to/Blizzard-1240-1260.rom
accuracy = 1
jit_compiler = 0
uae_cpu_speed = real
chip_memory = 2048
slow_memory = 0
ntsc_mode = 0
uae_cpu_compatible = true
uae_cpu_memory_cycle_exact = true
uae_blitter_cycle_exact = true
uae_sound_output = exact
kickstart_file = /path/to/Kickstart-A1200-3.1.rom
floppy_drive_count = 1
floppy_drive_0 = /path/to/hunter-performance.adf
```

Leave `cpu`, `fpu`, `mmu`, `fast_memory` and `accelerator_memory` unset.
The tested FS-UAE 3.2.35 profile selects a 68060-NOMMU, the 68060 FPU and
32 MiB of accelerator memory, with no separate Zorro II/III Fast RAM.
The Blizzard boot ROM is required for the tested configuration; ROMs are not included.

Boot with fresh emulator state: an old save state may restore a previous game
version and its settings. Keep exact Chip RAM and blitter timing enabled,
JIT disabled and CPU speed set to `real`. Do not enable the data cache.
Check the new run's `logs/debug.uae` for these timing settings, `cachesize=0`
and the accelerator memory. Confirm the Blizzard boot ROM loaded successfully.

## Checksums

Both ADFs are 901,120 bytes. Only the original Hunter trainer version
identified below is supported.

| Disk image | SHA-256 |
| --- | --- |
| Original Hunter ADF | `913d8c7cd8bf9096000b81c02acc8d0d7d49440a2cd486c6e1b8a74d18412f21` |
| hunter-performance.adf 1.1.0 | `3e23f678192c0c73994462dadea483baec56b5a9baadd04ca1ac9db31cb896e0` |
