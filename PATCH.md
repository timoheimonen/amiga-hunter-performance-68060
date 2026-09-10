# Patch details — 1.0.0

- 68060 instruction-cache support.
- Replacement of the renderer's self-modifying calls.
- A 104,960-byte Fast RAM area for object, terrain and trigonometric data and the expanded view module.
- A 512-byte terrain delta table, exact constant divisions and perspective-result reuse.
- Polygon span-loop selection and removal of per-row calls in two trapezoid fill operations.

The terrain window grows from 7 × 7 to 7 × 9 cells. The depth limit for
already active objects, including buildings, increases from 3,072 to 4,096
world units (about 33%). View width and object activation area remain unchanged.
The renderer uses bounded terrain reads and enlarged, capacity-checked object
queues. If Fast RAM allocation fails, the complete original 7 × 7 view remains.

`src/patches.json` records the release identifiers and source hashes.
The original compressed intro and game streams are preserved. Both ADFs are
901,120 bytes.
