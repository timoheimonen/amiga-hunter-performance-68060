# Patch details - 1.1.0

- 68060 instruction-cache support.
- Safe cache handling through Exec's `CacheControl` before the intro picture and original intros; the data cache stays disabled.
- Replacement of the renderer's self-modifying calls.
- A 104,960-byte Fast RAM area for object, terrain and trigonometric data and the expanded view module.
- An 80 KiB Exec allocation for the loader, resident patches and CPU buffers, using Blizzard 1260 memory with a bounded Chip RAM fallback. Disk DMA stays in Chip RAM.
- A 512-byte terrain delta table, exact constant divisions and perspective-result reuse.
- Polygon span-loop selection and removal of per-row calls in two trapezoid fill operations.

The terrain window grows from 7 × 7 to 7 × 9 cells. The depth limit for
already active objects, including buildings, increases from 3,072 to 4,096
world units (about 33%). View width and object activation area remain unchanged.
The renderer uses bounded terrain reads and enlarged, capacity-checked object
queues. If Fast RAM allocation fails, the complete original 7 × 7 view remains.

The loader allocation replaces the bootstrap's fixed RAM probes. Unsuitable
allocations are freed; if neither Fast RAM nor a safe Chip RAM area is available,
startup takes the original DOS error path before the intros. All 21 resource
files fit the packed-input buffer. The original resource preload area is unchanged.

Version 1.1.0 was checked in FS-UAE with exact Chip RAM and blitter timing:
startup, new-game movement, all 21 resource contents, allocation boundary cases
and a cold boot through the Chip RAM fallback. Original intro mouse waits were
skipped through the debugger in these checks. No speed improvement was measured
for this version; save/load and long-session validation remain incomplete.

`src/patches.json` records the release identifiers and source hashes.
The original compressed intro and game streams are preserved. Both ADFs are
901,120 bytes.
