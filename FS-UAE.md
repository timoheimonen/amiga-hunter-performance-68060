# FS-UAE settings

Use a PAL A1200 / 68060 configuration with Kickstart 3.1,
2 MiB Chip RAM and 8 MiB Fast RAM. Replace the disk and ROM paths:

```ini
[fs-uae]
amiga_model = A1200
cpu = 68060
fpu = 0
mmu = 0
accuracy = 1
jit_compiler = 0
uae_cpu_speed = real
chip_memory = 2048
slow_memory = 0
fast_memory = 8192
ntsc_mode = 0
uae_cpu_compatible = true
uae_cpu_memory_cycle_exact = true
uae_blitter_cycle_exact = true
uae_sound_output = exact
kickstart_file = /path/to/Kickstart-A1200-3.1.rom
floppy_drive_count = 1
floppy_drive_0 = /path/to/hunter-performance.adf
```

Boot with fresh emulator state: an old save state may restore a previous game
version and its settings. Keep exact Chip RAM and blitter timing enabled,
JIT disabled and CPU speed set to `real`. Do not enable the data cache.

## Checksums

Both ADFs are 901,120 bytes. Only the original Hunter trainer version
identified below is supported.

| Disk image | SHA-256 |
| --- | --- |
| Original Hunter ADF | `913d8c7cd8bf9096000b81c02acc8d0d7d49440a2cd486c6e1b8a74d18412f21` |
| hunter-performance.adf 1.0.0 | `b7f49cabfb99b81f61b0907bf563f5db0d095c8bbc19a2378729239fac6d628c` |
