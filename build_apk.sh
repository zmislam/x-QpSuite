#!/bin/bash
# ──────────────────────────────────────────────────────────
# QP Suite — APK Build Script
# ──────────────────────────────────────────────────────────
# Usage:
#   ./build_apk.sh              → Build debug APK (default)
#   ./build_apk.sh release      → Build release APK
#   ./build_apk.sh setup        → Install Java & Android SDK only
#   ./build_apk.sh clean        → Clean build artifacts then build
# ──────────────────────────────────────────────────────────

set -e

# ── Configuration ──────────────────────────────────────────
APP_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILDS_DIR="${APP_DIR}/builds"
FLUTTER_BIN="$HOME/flutter/bin/flutter"
JAVA_VERSION="17"
ANDROID_SDK_DIR="$HOME/android-sdk"
CMDLINE_TOOLS_VERSION="11076708"  # Latest command-line tools
CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS_VERSION}_latest.zip"

# ── Colors ─────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

# ── Helper Functions ───────────────────────────────────────
log_info()    { echo -e "${CYAN}ℹ ${NC}$1"; }
log_success() { echo -e "${GREEN}✓ ${NC}$1"; }
log_warn()    { echo -e "${YELLOW}⚠ ${NC}$1"; }
log_error()   { echo -e "${RED}✗ ${NC}$1"; }

print_banner() {
  echo ""
  echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║       ${YELLOW}QP Suite — APK Build Script${CYAN}            ║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
  echo ""
}

# ── Prerequisite: Java JDK ─────────────────────────────────
install_java() {
  if java --version &>/dev/null; then
    local java_ver=$(java --version 2>&1 | head -1)
    log_success "Java already installed: ${java_ver}"
    return 0
  fi

  log_warn "Java JDK ${JAVA_VERSION} not found. Installing..."
  # Clean stale apt cache to avoid hash mismatch errors
  sudo rm -rf /var/lib/apt/lists/*
  sudo apt-get clean
  sudo apt-get update
  sudo apt-get install -y openjdk-${JAVA_VERSION}-jdk-headless
  
  # Set JAVA_HOME
  export JAVA_HOME="/usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64"
  export PATH="$JAVA_HOME/bin:$PATH"

  if java --version &>/dev/null; then
    log_success "Java JDK ${JAVA_VERSION} installed successfully."
  else
    log_error "Failed to install Java JDK. Please install manually."
    exit 1
  fi
}

# ── Prerequisite: Android SDK ──────────────────────────────
install_android_sdk() {
  if [[ -d "$ANDROID_SDK_DIR/platforms" ]] && [[ -d "$ANDROID_SDK_DIR/build-tools" ]]; then
    log_success "Android SDK found at ${ANDROID_SDK_DIR}"
    return 0
  fi

  log_warn "Android SDK not found. Installing to ${ANDROID_SDK_DIR}..."
  mkdir -p "${ANDROID_SDK_DIR}/cmdline-tools"

  # Download command-line tools
  local tmp_zip="/tmp/android-cmdtools.zip"
  if [[ ! -f "$tmp_zip" ]]; then
    log_info "Downloading Android command-line tools..."
    curl -sL "$CMDLINE_TOOLS_URL" -o "$tmp_zip"
  fi

  # Extract and organize
  unzip -qo "$tmp_zip" -d "${ANDROID_SDK_DIR}/cmdline-tools"
  # The zip extracts to 'cmdline-tools/cmdline-tools' — move to 'latest'
  if [[ -d "${ANDROID_SDK_DIR}/cmdline-tools/cmdline-tools" ]]; then
    rm -rf "${ANDROID_SDK_DIR}/cmdline-tools/latest"
    mv "${ANDROID_SDK_DIR}/cmdline-tools/cmdline-tools" "${ANDROID_SDK_DIR}/cmdline-tools/latest"
  fi
  rm -f "$tmp_zip"

  export ANDROID_HOME="$ANDROID_SDK_DIR"
  export ANDROID_SDK_ROOT="$ANDROID_SDK_DIR"
  export PATH="$ANDROID_SDK_DIR/cmdline-tools/latest/bin:$ANDROID_SDK_DIR/platform-tools:$PATH"

  # Accept licenses (non-interactive)
  log_info "Accepting Android SDK licenses..."
  yes | sdkmanager --licenses >/dev/null 2>&1 || true

  # Install required SDK components
  log_info "Installing Android SDK components (this may take a few minutes)..."
  sdkmanager --install \
    "platforms;android-35" \
    "build-tools;35.0.0" \
    "platform-tools" \
    2>&1 | grep -E "^\[|done$" || true

  log_success "Android SDK installed successfully."
}

# ── Environment Setup ──────────────────────────────────────
setup_env() {
  # Java
  if [[ -z "$JAVA_HOME" ]] && [[ -d "/usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64" ]]; then
    export JAVA_HOME="/usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64"
    export PATH="$JAVA_HOME/bin:$PATH"
  fi

  # Android SDK
  if [[ -d "$ANDROID_SDK_DIR" ]]; then
    export ANDROID_HOME="$ANDROID_SDK_DIR"
    export ANDROID_SDK_ROOT="$ANDROID_SDK_DIR"
    export PATH="$ANDROID_SDK_DIR/cmdline-tools/latest/bin:$ANDROID_SDK_DIR/platform-tools:$PATH"
  fi

  # Flutter
  export PATH="$HOME/flutter/bin:$PATH"
}

# ── Write android/local.properties ─────────────────────────
write_local_properties() {
  local props_file="${APP_DIR}/android/local.properties"
  cat > "$props_file" <<EOF
flutter.sdk=${HOME}/flutter
sdk.dir=${ANDROID_SDK_DIR}
EOF
  log_info "Updated android/local.properties with SDK paths."
}

# ── Build APK ──────────────────────────────────────────────
build_apk() {
  local build_type="${1:-debug}"
  local timestamp=$(date +"%Y%m%d_%H%M%S")

  cd "$APP_DIR"

  # Create builds output directory
  mkdir -p "$BUILDS_DIR"

  # Clean if requested
  if [[ "$CLEAN_BUILD" == "true" ]]; then
    log_info "Cleaning previous build artifacts..."
    $FLUTTER_BIN clean
    echo ""
  fi

  # Get dependencies
  log_info "Fetching dependencies..."
  $FLUTTER_BIN pub get

  echo ""
  log_info "Building ${BOLD}${build_type}${NC} APK..."
  echo ""

  if [[ "$build_type" == "release" ]]; then
    $FLUTTER_BIN build apk --release --no-tree-shake-icons 2>&1
    local src_apk="${APP_DIR}/build/app/outputs/flutter-apk/app-release.apk"
    local dest_name="qp-suite-release-${timestamp}.apk"
  else
    $FLUTTER_BIN build apk --debug 2>&1
    local src_apk="${APP_DIR}/build/app/outputs/flutter-apk/app-debug.apk"
    local dest_name="qp-suite-debug-${timestamp}.apk"
  fi

  # Verify APK was generated
  if [[ ! -f "$src_apk" ]]; then
    log_error "APK build failed — output file not found."
    log_error "Expected: ${src_apk}"
    exit 1
  fi

  # Copy to builds folder with timestamp
  cp "$src_apk" "${BUILDS_DIR}/${dest_name}"

  # Also keep a 'latest' copy for convenience
  local latest_name="qp-suite-${build_type}-latest.apk"
  cp "$src_apk" "${BUILDS_DIR}/${latest_name}"

  # Get file size
  local apk_size=$(du -h "${BUILDS_DIR}/${dest_name}" | cut -f1)

  echo ""
  echo -e "${GREEN}══════════════════════════════════════════════${NC}"
  echo -e "${GREEN}  ✓ APK Build Successful!${NC}"
  echo -e "${GREEN}══════════════════════════════════════════════${NC}"
  echo ""
  echo -e "  ${BOLD}Type:${NC}     ${build_type}"
  echo -e "  ${BOLD}Size:${NC}     ${apk_size}"
  echo -e "  ${BOLD}File:${NC}     ${BUILDS_DIR}/${dest_name}"
  echo -e "  ${BOLD}Latest:${NC}   ${BUILDS_DIR}/${latest_name}"
  echo ""
  echo -e "  ${CYAN}All builds: ${BUILDS_DIR}/${NC}"
  echo ""
}

# ── Main ───────────────────────────────────────────────────
main() {
  print_banner

  local cmd="${1:-debug}"
  CLEAN_BUILD="false"

  case "$cmd" in
    setup)
      log_info "Running prerequisite setup only..."
      install_java
      install_android_sdk
      setup_env
      write_local_properties
      echo ""
      log_success "Setup complete. Run ${BOLD}./build_apk.sh${NC} to build the APK."
      exit 0
      ;;
    clean)
      CLEAN_BUILD="true"
      cmd="${2:-debug}"
      ;;
    release)
      cmd="release"
      ;;
    debug)
      cmd="debug"
      ;;
    help|--help|-h)
      echo "Usage: ./build_apk.sh [command]"
      echo ""
      echo "Commands:"
      echo "  debug       Build debug APK (default)"
      echo "  release     Build release APK"
      echo "  setup       Install Java & Android SDK prerequisites only"
      echo "  clean       Clean build artifacts before building"
      echo "  help        Show this help message"
      echo ""
      echo "Examples:"
      echo "  ./build_apk.sh                  # Debug build"
      echo "  ./build_apk.sh release          # Release build"
      echo "  ./build_apk.sh clean release    # Clean + release build"
      exit 0
      ;;
    *)
      log_error "Unknown command: ${cmd}"
      echo "Run './build_apk.sh help' for usage."
      exit 1
      ;;
  esac

  # Step 1: Install prerequisites if missing
  install_java
  install_android_sdk

  # Step 2: Set up environment variables
  setup_env

  # Step 3: Update local.properties with correct SDK path
  write_local_properties

  # Step 4: Verify Flutter can see Android toolchain
  log_info "Verifying Flutter environment..."
  $FLUTTER_BIN doctor --android 2>&1 | grep -E "Android|✓|✗|!" | head -5
  echo ""

  # Step 5: Build the APK
  build_apk "$cmd"
}

main "$@"
