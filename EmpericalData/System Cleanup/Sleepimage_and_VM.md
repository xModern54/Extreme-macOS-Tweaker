# Sleepimage & Virtual Memory Swap

## Target Files

- `/private/var/vm/sleepimage`
- `/private/var/vm/swapfile*`

## Footprint

- **Typical Size:** `2.0 GB – 16.0+ GB` (matches physical RAM or minimum baseline reservation)
- **Observed on Physical Mac:** `2.0 GB` (`/private/var/vm/sleepimage`)

## What Is Stored Here

- `sleepimage`: Full or compressed snapshot of volatile system RAM written to NVMe flash prior to sleep (Safe Sleep / Hibernation Mode 3 or 25).
- `swapfile*`: Dynamic swap partitions created by `dynamic_pager` when active memory pressure exceeds physical RAM.

## Related Subsystems

- `pmset` / Power Management subsystem
- `dynamic_pager` / XNU VM subsystem

## Safety & Verdict

- **Safety Level:** **Safe to Delete (when combined with power setting tweak)**
- **Verdict:** `purge-with-tweak`
- **Cleanup Recipe:**
  ```bash
  # 1. Disable Hibernation mode (Safe Sleep)
  sudo pmset -a hibernatemode 0
  sudo pmset -a autopoweroff 0
  sudo pmset -a standby 0

  # 2. Purge sleepimage
  sudo rm -f /private/var/vm/sleepimage

  # 3. Prevent macOS from recreating empty 0-byte reservation
  sudo touch /private/var/vm/sleepimage
  sudo chflags uchg /private/var/vm/sleepimage
  ```
- **Behavior After Removal:**
  - Standard sleep still works instantly (RAM remains powered in low-power state).
  - Mac mini, Mac Studio, Mac Pro, and AC-connected MacBooks do not need hibernation to disk.
  - Instantly frees **2 to 16+ GB** of fast NVMe storage and avoids continuous write cycles on SSD.
