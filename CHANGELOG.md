# Changelog

## 1.1.0 - 2026-09-11

- Add a Blizzard 1260 configuration using the accelerator's default memory without separate Fast RAM settings.
- Allocate 80 KiB through Exec for the loader, resident patches and CPU buffers, replacing fixed bootstrap RAM probes.
- Fall back to a bounded Chip RAM allocation if Fast RAM is unavailable or unsuitable; keep disk DMA in Chip RAM.

## 1.0.1 - 2026-09-11

- Disable the data cache through Exec's CacheControl service before opening the intro picture.
- Replace direct bootstrap cache disabling with CacheControl so pending writes are handled before disabling caches, including direct game startup.
- Check for Exec V39 or newer before the intro picture uses OS services.

## 1.0.0 - 2026-09-10

- Initial release of the Hunter 68060 performance patch.
- Instruction-cache support, Fast RAM data, terrain and polygon-fill optimizations.
- Expanded 7 × 9 terrain view and approximately 33% greater depth range for active objects, including buildings.
- Bounded terrain reads and enlarged object queues, with a complete 7 × 7 fallback if Fast RAM allocation fails.
- Standalone Python patcher and patch sources.
