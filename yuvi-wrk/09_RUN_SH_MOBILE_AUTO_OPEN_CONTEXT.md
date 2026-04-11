# 09_RUN_SH_MOBILE_AUTO_OPEN_CONTEXT

## Purpose
Ensure that when `run.sh` starts the Flutter web server, mobile users can be taken directly to the app URL automatically when possible.

## What Changed
- Added configurable env defaults:
  - `PORT` (default `8686`)
  - `HOST` (default `0.0.0.0`)
  - `SERVER_IP` (default existing public IP)
  - `MOBILE_PATH` (default `/preview.html`)
  - `OPEN_TIMEOUT_SECONDS` (default `45`)
- Added readiness checks before opening mobile URL to avoid opening too early.
- Added mobile open strategies:
  1. `termux-open-url` (Termux/native mobile shell)
  2. `adb shell am start ...` (connected Android device)
- Added wireless ADB support via `ADB_DEVICE=<phone-ip>:5555` so remote server can open URL on your phone.
- Added explicit diagnostics when auto-open is not possible due to missing host tools/device authorization.
- Added optional QR rendering via `qrencode` for manual scan fallback.
- Added opt-out switch: `DISABLE_MOBILE_OPEN=1`.

## Affected File
- `run.sh`

## Behavioral Notes
- Server still runs via `flutter run -d web-server --web-port --web-hostname`.
- Existing stop/status/restart behavior remains unchanged.
- If auto-open is unavailable, script prints manual URL instead of failing.

## Why This Fits
This keeps the startup flow intact while improving mobile access UX and preserving operational safety (no PM2, no service restarts outside this script's process scope).
