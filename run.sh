#!/bin/bash
# ──────────────────────────────────────────────────
# QP Suite — Flutter Web Dev Server
# ──────────────────────────────────────────────────
# Usage:
#   ./run.sh               → Start dev server (default mode)
#   ./run.sh mobile        → Start dev server + mobile auto-open
#   ./run.sh stop          → Stop the running server
#   ./run.sh restart       → Full restart (kill + start)
#   ./run.sh status        → Check if the server is running
#   ./run.sh r | reload    → Rebuild from another terminal
#   ./run.sh R | hot-restart → Rebuild from another terminal
# Optional env:
#   SERVER_IP=... PORT=... MOBILE_PATH=/preview.html ./run.sh mobile
#   OPEN_TIMEOUT_SECONDS=0  # 0 = wait until ready
#   ADB_DEVICE=192.168.1.25:5555 ./run.sh mobile
#   DISABLE_MOBILE_OPEN=1 ./run.sh mobile
# ──────────────────────────────────────────────────

PORT="${PORT:-8686}"
HOST="${HOST:-0.0.0.0}"
SERVER_IP="${SERVER_IP:-217.73.238.134}"
MOBILE_PATH="${MOBILE_PATH:-/preview.html}"
OPEN_TIMEOUT_SECONDS="${OPEN_TIMEOUT_SECONDS:-0}"
APP_DIR="$(cd "$(dirname "$0")" && pwd)"
PID_FILE="/tmp/qp_flutter_${PORT}.pid"
RUNNER_PID_FILE="/tmp/qp_runner_${PORT}.pid"
STDIN_FIFO="/tmp/qp_flutter_stdin_${PORT}"

export PATH="$HOME/flutter/bin:$PATH"
export CHROME_EXECUTABLE=$(which chromium 2>/dev/null)

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

if [[ "${MOBILE_PATH}" != /* ]]; then
  MOBILE_PATH="/${MOBILE_PATH}"
fi

if ! [[ "${OPEN_TIMEOUT_SECONDS}" =~ ^[0-9]+$ ]]; then
  echo -e "${YELLOW}ℹ Invalid OPEN_TIMEOUT_SECONDS (${OPEN_TIMEOUT_SECONDS}); using 0.${NC}"
  OPEN_TIMEOUT_SECONDS=0
fi

# ── Internal state ──
FLUTTER_PID=""
_STDIN_KEEPER_PID=""
_restart_flag=0

print_banner() {
  echo ""
  echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║        ${YELLOW}QP Suite — Dev Server${CYAN}             ║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
  echo ""
}

stop_server() {
  local stopped=false

  # 1. Kill runner process if present
  if [ -f "$RUNNER_PID_FILE" ]; then
    local rpid
    rpid=$(cat "$RUNNER_PID_FILE" 2>/dev/null)
    if [ -n "$rpid" ] && kill -0 "$rpid" 2>/dev/null; then
      echo -e "${YELLOW}Stopping runner (PID $rpid)...${NC}"
      kill "$rpid" 2>/dev/null
      sleep 1
      kill -9 "$rpid" 2>/dev/null
      stopped=true
    fi
    rm -f "$RUNNER_PID_FILE"
  fi

  # 2. Kill Flutter process from PID file
  if [ -f "$PID_FILE" ]; then
    local pid
    pid=$(cat "$PID_FILE" 2>/dev/null)
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      echo -e "${YELLOW}Stopping Flutter (PID $pid)...${NC}"
      kill "$pid" 2>/dev/null
      for i in $(seq 1 10); do
        kill -0 "$pid" 2>/dev/null || break
        sleep 0.5
      done
      kill -9 "$pid" 2>/dev/null
      stopped=true
    fi
    rm -f "$PID_FILE"
  fi

  # 3. Clean up anything still on the port
  if fuser ${PORT}/tcp >/dev/null 2>&1; then
    echo -e "${YELLOW}Cleaning up port ${PORT}...${NC}"
    fuser -k ${PORT}/tcp >/dev/null 2>&1
    sleep 2
    stopped=true
  fi

  # 4. Kill orphan dart/flutter processes from previous runs
  local orphans
  orphans=$(pgrep -f "flutter_tools.snapshot run -d web-server.*--web-port=${PORT}" 2>/dev/null)
  if [ -n "$orphans" ]; then
    echo -e "${YELLOW}Cleaning orphan flutter processes...${NC}"
    echo "$orphans" | xargs kill 2>/dev/null
    sleep 1
    echo "$orphans" | xargs kill -9 2>/dev/null
  fi

  # 5. Clean up FIFO
  rm -f "$STDIN_FIFO"

  if [ "$stopped" = true ]; then
    echo -e "${GREEN}✓ Server stopped.${NC}"
  else
    echo -e "${YELLOW}No server running on port ${PORT}.${NC}"
  fi
}

# ── Launch / Kill Flutter as a managed child process ──
_launch_flutter() {
  # Clean up port from previous run
  fuser -k ${PORT}/tcp >/dev/null 2>&1 && sleep 0.5

  # Create a dummy stdin for Flutter via named pipe (FIFO).
  # This keeps Flutter's stdin open (no EOF → won't exit) but never
  # sends data (Flutter won't try its broken interactive r/R/q commands
  # that always timeout on web-server device without a debug connection).
  rm -f "$STDIN_FIFO"
  mkfifo "$STDIN_FIFO"
  sleep infinity > "$STDIN_FIFO" &
  _STDIN_KEEPER_PID=$!

  flutter run -d web-server \
    --web-port=${PORT} \
    --web-hostname=${HOST} \
    < "$STDIN_FIFO" &
  FLUTTER_PID=$!
  echo "$FLUTTER_PID" > "$PID_FILE"
}

_kill_flutter() {
  # Kill Flutter
  if [ -n "$FLUTTER_PID" ] && kill -0 "$FLUTTER_PID" 2>/dev/null; then
    kill "$FLUTTER_PID" 2>/dev/null
    for i in $(seq 1 10); do
      kill -0 "$FLUTTER_PID" 2>/dev/null || break
      sleep 0.5
    done
    kill -9 "$FLUTTER_PID" 2>/dev/null
  fi
  wait "$FLUTTER_PID" 2>/dev/null
  FLUTTER_PID=""

  # Kill stdin keeper
  kill "$_STDIN_KEEPER_PID" 2>/dev/null
  _STDIN_KEEPER_PID=""
  rm -f "$STDIN_FIFO"

  # Clean up port and orphans
  fuser -k ${PORT}/tcp >/dev/null 2>&1
  pgrep -f "flutter_tools.snapshot run -d web-server.*--web-port=${PORT}" 2>/dev/null \
    | xargs kill -9 2>/dev/null
  sleep 0.5
}

_cleanup_all() {
  _kill_flutter
  rm -f "$PID_FILE" "$RUNNER_PID_FILE" "$STDIN_FIFO"
}

# ── Rebuild from another terminal ──
_signal_runner() {
  if [ -f "$RUNNER_PID_FILE" ]; then
    local runner_pid
    runner_pid=$(cat "$RUNNER_PID_FILE" 2>/dev/null)
    if [ -n "$runner_pid" ] && kill -0 "$runner_pid" 2>/dev/null; then
      echo -e "${CYAN}🔄 Sending rebuild signal (→ runner PID $runner_pid)...${NC}"
      kill -USR2 "$runner_pid"
      echo -e "${GREEN}✓ Rebuild triggered. Watch the server terminal.${NC}"
      return
    fi
  fi
  echo -e "${RED}✗ No running server found. Start with: ./run.sh${NC}"
  exit 1
}

do_hot_reload() { _signal_runner; }
do_hot_restart() { _signal_runner; }

# ── Server main loop ──
# Runs Flutter as a managed child, handles r/R/q from user, and
# accepts SIGUSR2 from other terminals to trigger rebuilds.
_server_loop() {
  echo $$ > "$RUNNER_PID_FILE"

  # SIGUSR2 from ./run.sh R in another terminal → flag + kill Flutter
  trap '_restart_flag=1; _kill_flutter' USR2
  trap '_cleanup_all; exit 0' EXIT
  trap '_cleanup_all; exit 130' INT TERM

  while true; do
    _restart_flag=0
    _launch_flutter

    echo -e "${CYAN}⏳ Building Flutter web app (PID: ${FLUTTER_PID})...${NC}"

    # Monitor Flutter + handle user keypresses
    while true; do
      # Check if restart was requested via signal from another terminal
      if [ "$_restart_flag" = "1" ]; then
        _restart_flag=0
        echo ""
        echo -e "${CYAN}🔄 Rebuild triggered from another terminal...${NC}"
        break
      fi

      # Check if Flutter exited
      if [ -n "$FLUTTER_PID" ] && ! kill -0 "$FLUTTER_PID" 2>/dev/null; then
        wait "$FLUTTER_PID" 2>/dev/null
        FLUTTER_PID=""

        # If restart was requested (via signal), loop back immediately
        if [ "$_restart_flag" = "1" ]; then
          echo -e "${CYAN}🔄 Rebuilding...${NC}"
          break
        fi

        # Flutter exited on its own
        echo ""
        echo -e "${RED}✗ Flutter process exited.${NC}"
        echo -e "${YELLOW}Press ${BOLD}R${NC}${YELLOW} to rebuild, ${BOLD}q${NC}${YELLOW} to quit.${NC}"
        while true; do
          read -rsn1 key
          case "$key" in
            r|R) break 2 ;;
            q)   exit 0 ;;
          esac
        done
      fi

      # Read user input with 1s timeout (non-blocking check)
      if read -rsn1 -t 1 key 2>/dev/null; then
        case "$key" in
          r|R)
            echo ""
            echo -e "${CYAN}🔄 Rebuilding Flutter...${NC}"
            _kill_flutter
            break
            ;;
          q)
            echo ""
            echo -e "${YELLOW}Shutting down...${NC}"
            exit 0
            ;;
          c)
            clear
            ;;
        esac
      fi
    done
  done
}

check_status() {
  if fuser ${PORT}/tcp >/dev/null 2>&1; then
    echo -e "${GREEN}✓ QP Suite is running on port ${PORT}${NC}"
    echo -e "  Open: ${CYAN}http://${SERVER_IP}:${PORT}${NC}"
    if [ -f "$RUNNER_PID_FILE" ]; then
      local rpid
      rpid=$(cat "$RUNNER_PID_FILE" 2>/dev/null)
      if kill -0 "$rpid" 2>/dev/null; then
        echo -e "  Runner PID: ${CYAN}${rpid}${NC}"
        echo -e "  ${YELLOW}./run.sh R${NC}  → rebuild from another terminal"
      fi
    fi
    if [ -f "$PID_FILE" ]; then
      local fpid
      fpid=$(cat "$PID_FILE" 2>/dev/null)
      if kill -0 "$fpid" 2>/dev/null; then
        echo -e "  Flutter PID: ${CYAN}${fpid}${NC}"
      fi
    fi
  else
    echo -e "${RED}✗ QP Suite is not running.${NC}"
    echo -e "  Run: ${CYAN}./run.sh${NC} to start"
  fi
}

is_server_ready() {
  local probe_url="http://127.0.0.1:${PORT}${MOBILE_PATH}"

  if command -v curl >/dev/null 2>&1; then
    curl --silent --output /dev/null --max-time 2 "${probe_url}" >/dev/null 2>&1
  else
    fuser ${PORT}/tcp >/dev/null 2>&1
  fi
}

wait_for_server() {
  local pid="$1"
  local elapsed=0

  while true; do
    if ! kill -0 "${pid}" >/dev/null 2>&1; then
      return 1
    fi

    if is_server_ready; then
      return 0
    fi

    sleep 1
    elapsed=$((elapsed + 1))

    if [ "${OPEN_TIMEOUT_SECONDS}" -gt 0 ] && [ "${elapsed}" -ge "${OPEN_TIMEOUT_SECONDS}" ]; then
      return 2
    fi
  done

  return 1
}

open_mobile_browser() {
  local url="$1"
  local adb_target=""

  if [ "${DISABLE_MOBILE_OPEN}" = "1" ]; then
    echo -e "${YELLOW}ℹ Mobile auto-open disabled (DISABLE_MOBILE_OPEN=1).${NC}"
    return
  fi

  if command -v termux-open-url >/dev/null 2>&1; then
    if termux-open-url "${url}" >/dev/null 2>&1; then
      echo -e "${GREEN}✓ Opened on mobile via Termux.${NC}"
      return
    fi
  fi

  if command -v adb >/dev/null 2>&1; then
    if [ -n "${ADB_DEVICE}" ]; then
      adb connect "${ADB_DEVICE}" >/dev/null 2>&1 || true
      if adb -s "${ADB_DEVICE}" get-state 2>/dev/null | grep -q "^device$"; then
        adb_target="${ADB_DEVICE}"
      fi
    else
      adb_target="$(adb devices 2>/dev/null | awk 'NR>1 && $2=="device" {print $1; exit}')"
    fi

    if [ -n "${adb_target}" ]; then
      if adb -s "${adb_target}" shell am start -a android.intent.action.VIEW -d "${url}" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Opened on Android device (${adb_target}).${NC}"
        return
      fi
    else
      echo -e "${YELLOW}ℹ ADB found, but no authorized Android device is connected.${NC}"
      echo -e "  Tip: set ${CYAN}ADB_DEVICE=<phone-ip>:5555${NC} for wireless open."
    fi
  else
    echo -e "${YELLOW}ℹ No mobile bridge found on this host (termux-open-url/adb missing).${NC}"
  fi

  echo -e "${YELLOW}ℹ Could not auto-open your mobile browser automatically.${NC}"
  echo -e "  Open manually: ${CYAN}${url}${NC}"
}

show_mobile_qr() {
  local url="$1"

  if command -v qrencode >/dev/null 2>&1; then
    echo ""
    echo -e "${CYAN}Scan this on mobile:${NC}"
    qrencode -t ansiutf8 "${url}"
  fi
}

start_server() {
  print_banner

  if ! command -v flutter &>/dev/null; then
    echo -e "${RED}✗ Flutter not found. Make sure ~/flutter/bin is in PATH.${NC}"
    exit 1
  fi

  if fuser ${PORT}/tcp >/dev/null 2>&1; then
    echo -e "${YELLOW}Port ${PORT} in use — stopping existing server...${NC}"
    stop_server
  fi

  if [ ! -d "$APP_DIR/.dart_tool" ]; then
    echo -e "${CYAN}Installing dependencies...${NC}"
    cd "$APP_DIR" && flutter pub get
  fi

  echo -e "${GREEN}Starting QP Suite...${NC}"
  echo ""
  echo -e "  ${CYAN}➜  Mobile Preview: ${NC}http://${SERVER_IP}:${PORT}/preview.html"
  echo -e "  ${CYAN}➜  Full screen:    ${NC}http://${SERVER_IP}:${PORT}"
  echo -e "  ${CYAN}➜  Local:          ${NC}http://localhost:${PORT}/preview.html"
  echo ""
  echo -e "  ${YELLOW}In this terminal:${NC}  ${BOLD}r${NC} / ${BOLD}R${NC} = rebuild  |  ${BOLD}q${NC} = quit  |  ${BOLD}c${NC} = clear"
  echo -e "  ${YELLOW}From any terminal:${NC} ./run.sh R"
  echo ""

  cd "$APP_DIR"
  _server_loop
}

start_server_mobile() {
  local mobile_url="http://${SERVER_IP}:${PORT}${MOBILE_PATH}"

  print_banner

  if ! command -v flutter &>/dev/null; then
    echo -e "${RED}✗ Flutter not found. Make sure ~/flutter/bin is in PATH.${NC}"
    exit 1
  fi

  if fuser ${PORT}/tcp >/dev/null 2>&1; then
    echo -e "${YELLOW}Port ${PORT} in use — stopping existing server...${NC}"
    stop_server
  fi

  if [ ! -d "$APP_DIR/.dart_tool" ]; then
    echo -e "${CYAN}Installing dependencies...${NC}"
    cd "$APP_DIR" && flutter pub get
  fi

  echo -e "${GREEN}Starting QP Suite (mobile mode)...${NC}"
  echo ""
  echo -e "  ${CYAN}➜  Mobile Preview: ${NC}${mobile_url}"
  echo -e "  ${CYAN}➜  Full screen:    ${NC}http://${SERVER_IP}:${PORT}"
  echo -e "  ${CYAN}➜  Local:          ${NC}http://localhost:${PORT}${MOBILE_PATH}"
  echo ""
  echo -e "  ${YELLOW}In this terminal:${NC}  ${BOLD}r${NC} / ${BOLD}R${NC} = rebuild  |  ${BOLD}q${NC} = quit  |  ${BOLD}c${NC} = clear"
  echo -e "  ${YELLOW}From any terminal:${NC} ./run.sh R"
  echo ""

  # Spawn mobile-open helper in background
  (
    wait_for_server_background
    open_mobile_browser "${mobile_url}"
    show_mobile_qr "${mobile_url}"
  ) &

  cd "$APP_DIR"
  _server_loop
}

# Background-safe server readiness check (no PID to track, just poll the port)
wait_for_server_background() {
  local elapsed=0
  while true; do
    if is_server_ready; then
      return 0
    fi
    sleep 1
    elapsed=$((elapsed + 1))
    if [ "${OPEN_TIMEOUT_SECONDS}" -gt 0 ] && [ "${elapsed}" -ge "${OPEN_TIMEOUT_SECONDS}" ]; then
      return 2
    fi
    # Safety: give up after 120s
    if [ "${elapsed}" -ge 120 ]; then
      return 1
    fi
  done
}

# ── Main ──
case "${1}" in
  mobile)
    start_server_mobile
    ;;
  stop)
    stop_server
    ;;
  restart)
    stop_server
    start_server
    ;;
  r|reload)
    do_hot_reload
    ;;
  R|hot-restart)
    do_hot_restart
    ;;
  status)
    check_status
    ;;
  *)
    start_server
    ;;
esac
