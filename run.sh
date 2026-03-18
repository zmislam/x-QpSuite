#!/bin/bash
# ──────────────────────────────────────────────────
# QP Suite — Flutter Web Dev Server
# ──────────────────────────────────────────────────
# Usage:
#   ./run.sh          → Start dev server (default port 8686)
#   ./run.sh stop     → Stop the running server
#   ./run.sh restart  → Restart the server
#   ./run.sh status   → Check if the server is running
# ──────────────────────────────────────────────────

PORT=8686
HOST="0.0.0.0"
SERVER_IP="217.73.238.134"
APP_DIR="$(cd "$(dirname "$0")" && pwd)"

export PATH="$HOME/flutter/bin:$PATH"
export CHROME_EXECUTABLE=$(which chromium 2>/dev/null)

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_banner() {
  echo ""
  echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║        ${YELLOW}QP Suite — Dev Server${CYAN}             ║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
  echo ""
}

stop_server() {
  if fuser ${PORT}/tcp >/dev/null 2>&1; then
    echo -e "${YELLOW}Stopping QP Suite on port ${PORT}...${NC}"
    fuser -k ${PORT}/tcp >/dev/null 2>&1
    sleep 2
    echo -e "${GREEN}✓ Server stopped.${NC}"
  else
    echo -e "${YELLOW}No server running on port ${PORT}.${NC}"
  fi
}

check_status() {
  if fuser ${PORT}/tcp >/dev/null 2>&1; then
    echo -e "${GREEN}✓ QP Suite is running on port ${PORT}${NC}"
    echo -e "  Open: ${CYAN}http://${SERVER_IP}:${PORT}${NC}"
  else
    echo -e "${RED}✗ QP Suite is not running.${NC}"
    echo -e "  Run: ${CYAN}./run.sh${NC} to start"
  fi
}

start_server() {
  print_banner

  # Check Flutter is available
  if ! command -v flutter &>/dev/null; then
    echo -e "${RED}✗ Flutter not found. Make sure ~/flutter/bin is in PATH.${NC}"
    exit 1
  fi

  # Kill any existing process on the port
  if fuser ${PORT}/tcp >/dev/null 2>&1; then
    echo -e "${YELLOW}Port ${PORT} in use — stopping existing server...${NC}"
    fuser -k ${PORT}/tcp >/dev/null 2>&1
    sleep 2
  fi

  # Install dependencies if needed
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
  echo -e "${YELLOW}Press Ctrl+C to stop the server${NC}"
  echo ""

  cd "$APP_DIR" && flutter run -d web-server \
    --web-port=${PORT} \
    --web-hostname=${HOST}
}

# ── Main ──
case "${1}" in
  stop)
    stop_server
    ;;
  restart)
    stop_server
    start_server
    ;;
  status)
    check_status
    ;;
  *)
    start_server
    ;;
esac
