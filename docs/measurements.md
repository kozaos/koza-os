# Measurements

Setup: QEMU, 4 GB RAM, 2 cores, `free -m` one minute after the desktop appears.
Only values that were actually measured go here.

| Date | Flavor | Mode (BIOS/UEFI) | RAM (MB, used) | `systemd-analyze` | Note |
|---|---|---|---|---|---|
| 2026-11-26 | XFCE | UEFI | 588 | 1.928s kernel + 16.802s userspace = 18.731s | Live ISO, Phase 1 (no zram/tuning yet), KVM `-cpu host` |
| 2026-11-26 | XFCE | BIOS | – | – | Desktop appeared, not measured |
| 2026-11-26 | XFCE | BIOS, 2 GB RAM | 506 (1451 available) | 1.588s + 15.894s = 17.483s | Desktop usable |
| 2026-11-26 | XFCE | UEFI, `-cpu core2duo` (TCG) | – | – | Desktop + Firefox OK; Firefox `crashreporter` SIGILL (SSE4.1 `pextrq` in aho_corasick) |
