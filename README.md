# 4chan Thread Monitor

> Zero-install Windows batch script that monitors and downloads 4chan threads.  
> Multi-thread queue, auto dead-removal, retry logic, and persistent stats — powered by [gallery-dl](https://github.com/mikf/gallery-dl).

---

## Table of Contents

- [Overview](#overview)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [How It Works](#how-it-works)
- [File Structure](#file-structure)
- [Usage](#usage)
- [Features](#features)
- [Configuration](#configuration)
- [Terminal Output](#terminal-output)
- [FAQ](#faq)

---

## Overview

`4chan_monitor.bat` is a Windows batch script that continuously monitors a list of 4chan thread URLs, downloads any new files using gallery-dl, and automatically cleans up dead threads. It runs in a terminal window with no installation — just drop the script in a folder, add some thread URLs, and run it.

It is designed to run unattended for hours or days. Threads that 404 or expire are detected and removed automatically. New threads can be added at any time without restarting the script. Stats are saved across sessions so nothing is lost if you close the window.

---

## Requirements

| Requirement | Notes |
|---|---|
| **Windows 10 or 11** | Uses built-in `powershell.exe` and `cmd.exe` features |
| **[gallery-dl](https://github.com/mikf/gallery-dl)** | Must be installed and available in system PATH |
| **Python 3** | Required by gallery-dl |

gallery-dl installation (if you don't have it):
```
pip install gallery-dl
```

Or download the standalone `.exe` from the [gallery-dl releases page](https://github.com/mikf/gallery-dl/releases) and place it somewhere in your PATH.

No other runtime, framework, or dependency is required. The script uses only tools that ship with Windows.

---

## Installation

1. Download `4chan_monitor.bat`
2. Place it in an empty folder — this folder will be used as the working directory
3. That's it

All data files (thread list, logs, stats) are created automatically in the same folder when the script first runs.

---

## Quick Start

**Step 1** — Create a file called `threads_4chan.txt` in the same folder as the script and add thread URLs, one per line:
```
https://boards.4chan.org/g/thread/12345678
https://boards.4chan.org/wg/thread/87654321
https://boards.4chan.org/an/thread/11223344
```

**Step 2** — Double-click `4chan_monitor.bat` or run it from a terminal:
```
4chan_monitor.bat
```

**Step 3** — When prompted, enter the number of monitor cycles to run, or `0` for infinite:
```
How many monitor cycles to run? (0 = infinite)
Loop Count: 0
```

The script will start monitoring immediately. Files are downloaded to gallery-dl's configured output directory (default: a `gallery-dl` folder in your home directory or current directory depending on your gallery-dl config).

---

## How It Works

The script runs in a continuous loop. Each loop iteration is called a **cycle**. During a cycle:

1. Any URLs in `new_4chan.txt` are merged into the main thread list (with deduplication)
2. All threads in `threads_4chan.txt` are processed in order
3. For each thread, gallery-dl is launched to download any new files
4. Dead threads (404'd, expired, archived) are detected and removed from the list
5. Stats are saved to `stats_4chan.txt`
6. A cycle summary is printed
7. The script rests for a configurable sleep period, then repeats

**Priority threads** (in `priority_4chan.txt`) are processed first at the start of every cycle, before the main list.

**Dead thread detection** works in two layers: if gallery-dl exits with a non-zero code the log is checked for HTTP error patterns; if gallery-dl exits cleanly but the log contains keywords like `Not Found`, `has expired`, or `is archived`, the thread is still marked as dead. This dual-layer approach handles all gallery-dl versions reliably.

**Adaptive sleep** automatically adjusts the delay between threads and between cycles based on how many threads are in the queue. A small queue gets longer delays (to avoid hammering the server); a large queue gets shorter delays (to cycle through everything efficiently).

---

## File Structure

All files are created automatically in the same folder as the script.

| File | Purpose |
|---|---|
| `threads_4chan.txt` | Main thread list — one URL per line. Edit directly or use the inbox. |
| `new_4chan.txt` | **Inbox** — drop URLs here at any time. They are merged into the main list at the start of the next cycle, with deduplication. The file is deleted after merging. |
| `priority_4chan.txt` | **Priority queue** — URLs here are processed first every cycle. The file is not deleted; it persists across cycles. |
| `pause_4chan.txt` | **Pause trigger** — create this file (contents don't matter) to pause the script. Delete it to resume. No restart needed. |
| `stats_4chan.txt` | Persistent stats — session count, success/404/blocked/failed totals. Survives restarts. |
| `failures_4chan.txt` | Timestamped log of every removed thread and error. |
| `log_4chan.txt` | gallery-dl output for the most recently processed thread. Overwritten each run. |

---

## Usage

### Running normally
```
4chan_monitor.bat
```

### Dry-run mode
Preview what would run without downloading anything. gallery-dl is never called.
```
4chan_monitor.bat --dry-run
```

### Help
```
4chan_monitor.bat --help
```

### Adding threads while running
Simply add URLs to `new_4chan.txt` — one per line — at any time. They will be picked up automatically at the start of the next cycle. The inbox is deduplicated against the existing thread list so duplicates are ignored.

### Pausing
Create a file named `pause_4chan.txt` in the script's folder (empty file is fine). The script will pause at the next safe point and poll every 10 seconds until the file is deleted.

### Stopping
Close the terminal window, or press `Ctrl+C`. Stats are saved at the end of each complete cycle, so closing mid-cycle will not corrupt anything — the last completed cycle's stats are preserved in `stats_4chan.txt`.

---

## Features

### Multi-thread queue management
Monitors any number of threads from a single list. The script processes every URL in the list each cycle.

### Auto dead-thread removal
Threads that have 404'd, expired, or been archived are automatically detected and removed from the thread list at the end of each cycle. Detection is two-layered:
- If gallery-dl exits non-zero: log is checked for `404 Client`, `Not Found`, `Unsupported URL`
- If gallery-dl exits zero but log contains `Not Found`, `has expired`, or `is archived`: thread is still treated as dead

This handles all gallery-dl versions and edge cases where a dead thread returns exit code 0.

### Inbox / priority queue
Two additional input mechanisms beyond the main list:
- **`new_4chan.txt`** — drop new URLs here at any time; merged and deduplicated on next cycle
- **`priority_4chan.txt`** — processed before the main queue every cycle; useful for threads you want to check more urgently

### Pause / resume
Create `pause_4chan.txt` to pause the script without killing it. Delete the file to resume. Useful if you need to free bandwidth or disk space temporarily without losing your session.

### Dry-run mode
`--dry-run` flag prints what gallery-dl *would* be called with, without actually downloading anything. Useful for testing a new thread list.

### Persistent stats
Session counts and cumulative totals (success, 404d, blocked, failed, unsupported) are written to `stats_4chan.txt` after every cycle and loaded on startup. Stats survive restarts and accumulate indefinitely.

### Failure log
Every removed thread and every error is timestamped and appended to `failures_4chan.txt`. Format:
```
[Mon 01/01/2025 12:00:00.00] 404 REMOVED: https://boards.4chan.org/g/thread/12345678
[Mon 01/01/2025 12:05:00.00] BLOCKED: https://boards.4chan.org/wg/thread/87654321
```

### Retry logic
On an unclassified error (not 404, not blocked, not unsupported), the thread is retried up to 3 times with a 10-second delay between attempts. If all retries are exhausted the thread is marked as FAILED and kept in the queue for the next cycle.

### Cloudflare / rate-limit handling
HTTP 429 (Too Many Requests) and HTTP 403 (Forbidden) trigger a 5-minute pause before moving on. The thread is kept in the queue and retried next cycle.

### Adaptive sleep
Sleep durations adjust automatically based on queue size:

| Queue size | Thread delay | Cycle rest |
|---|---|---|
| 1–2 threads | 15 seconds | 60 seconds |
| 3–9 threads | 8 seconds | 30 seconds |
| 10+ threads | 3 seconds | 15 seconds |

### gallery-dl update check
On startup the script queries PyPI for the latest gallery-dl version and compares it against the installed version. If an update is available, you are notified with the version number and the pip command to upgrade.

### Thread list sanitizer
On startup, `threads_4chan.txt` is automatically sanitized: BOM markers and invisible/non-ASCII characters are stripped, blank lines are removed, and any line that isn't a valid `http://` or `https://` URL is discarded. This prevents silent failures from copy-paste artifacts.

### HashSet deduplication
When merging `new_4chan.txt` into the main list, deduplication is done via a PowerShell `HashSet<string>` (O(1) lookups), making it fast even for large thread lists. All new URLs are batch-written in a single file operation.

### 600-second timeout
If gallery-dl hangs and does not exit within 600 seconds (10 minutes), the process is killed and the thread is classified as failed.

### Animated spinner
While gallery-dl is running, an animated spinner (`| / - \`) with an elapsed timer is shown in the terminal so you can tell at a glance that the script is actively working.

### Colour-coded output
All terminal output is colour-coded for quick scanning:
- **Cyan** — cycle headers, system messages
- **Green** — successful downloads, ready status
- **Yellow** — warnings, 404s, blocked threads, skipped
- **Red** — failures, fatal errors
- **White** — general info, thread URLs

---

## Configuration

All configurable values are at the top of the script and can be edited in any text editor.

```batch
set MAX_RETRIES=3          :: Retry attempts before marking a thread as FAILED
set BASE_THREAD_SLEEP=8    :: Seconds to wait between threads (medium queue)
set BASE_CYCLE_SLEEP=30    :: Seconds to rest between full cycles (medium queue)
set MIN_THREAD_SLEEP=3     :: Minimum thread delay (large queue, 10+ threads)
set MAX_THREAD_SLEEP=15    :: Maximum thread delay (small queue, 1-2 threads)
```

gallery-dl itself is configured via its own config file (`gallery-dl.conf` or `~/.config/gallery-dl/config.json`). The script passes `--sleep-request 2.0` to gallery-dl by default to space out individual file requests within a thread.

---

## Terminal Output

Example of what a running cycle looks like:

```
===============================================================================
 CYCLE: 3  |  TIME: 14:22:05  |  QUEUE: 12  |  SLEEP: 3s
===============================================================================

[NORMAL] Scraping: https://boards.4chan.org/g/thread/12345678
  [/] Scraping...  [00:04]
  [OK] Downloaded.
  [PAUSE] Waiting 3s...

[NORMAL] Scraping: https://boards.4chan.org/wg/thread/87654321
  [-] Scraping...  [00:01]
  [404] Thread gone (exit 0). Removing after cycle.

[CLEANUP] Removed 1 dead thread(s).

-----------------------------------------------------------------------
 CYCLE 3 SUMMARY
-----------------------------------------------------------------------
  Success     : 11
  404d        : 1
  Blocked     : 0
  Unsupported : 0
  Failed      : 0
  Skipped     : 0
-----------------------------------------------------------------------
 ALL-TIME  Sessions:3  OK:33  404:2  Blocked:0  Failed:0  Unsupported:0
-----------------------------------------------------------------------

[SYSTEM] Resting 15s...
```

---

## FAQ

**Does this work for all 4chan boards?**  
Yes. Any board URL that gallery-dl supports will work. Boards like `/wsg/` and `/gif/` that contain WebM files are supported too.

**Can I run this alongside other scripts?**  
Yes. Multiple instances can run in separate folders simultaneously as long as each has its own set of data files (the file names include `_4chan` to help with this).

**What happens if gallery-dl isn't installed?**  
The script detects this at startup and exits immediately with a clear error message and a link to the gallery-dl install page.

**What happens if I add a non-4chan URL to the thread list?**  
gallery-dl will attempt to download it. If the URL is unsupported by gallery-dl, it will be classified as `UNSUPPORTED` and removed from the list automatically.

**What happens if a thread is already fully downloaded?**  
gallery-dl exits cleanly with nothing to do. The script marks it as `[OK]` and moves on — the thread stays in the list for future monitoring.

**Where are files downloaded to?**  
gallery-dl decides the output location based on its own configuration. By default it creates a `gallery-dl` folder in the current directory or your home directory. You can configure the output path in your `gallery-dl.conf`.

**Can I edit `threads_4chan.txt` while the script is running?**  
Yes, with care. The file is read at the start of each cycle. Edits made during a cycle will be picked up on the next cycle. The safer approach is to use `new_4chan.txt` to add threads and let the script manage the main list.

**Will closing the terminal window lose my stats?**  
No. Stats are written to `stats_4chan.txt` at the end of every complete cycle. Closing the window mid-cycle only loses progress on that cycle; all previously completed cycles are saved.

---

## License

MIT
