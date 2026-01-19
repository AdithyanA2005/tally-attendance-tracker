#!/usr/bin/env bash
set -euo pipefail

# ---
# Main build script for the Tally app.
#
# This script orchestrates the build process for different platforms.
# It calls platform-specific build scripts located in the same directory.
# ---

# Get the directory of the script
SCRIPT_DIR="$(dirname "$0")"
cd "$SCRIPT_DIR"

# Source common variables and functions
# shellcheck source=scripts/common.sh
source "common.sh"

# ---
# Usage instructions
# ---
usage() {
  echo "Tally Build Script"
  echo "------------------"
  echo "Usage: $0 <platform>"
  echo
  echo "Arguments:"
  echo "  all                  Build for all supported platforms (Android, AppImage)."
  echo "  android              Build Android release (APK and AAB)."
  echo "  linux                Build Linux AppImage."
  echo "  ios (coming soon)    Build iOS release."
  echo "  macos (coming soon)  Build macOS release."
  echo "  windows (coming soon)Build Windows release."
  echo
  echo "Examples:"
  echo "  $0 android"
  echo "  $0 all"
  exit 1
}

# ---
# Build functions
# ---
build_android() {
  echo
  log "Starting Android build..."
  ./build_android_release.sh
  log "Android build finished."
  echo
}

build_linux() {
  echo
  log "Starting AppImage build..."
  ./build_linux_appimage.sh
  log "AppImage build finished."
  echo
}

# ---
# Main logic
# ---
main() {
  if [ $# -eq 0 ]; then
    usage
  fi

  case "$1" in
  all)
    log "Building all platforms..."
    build_android
    build_linux
    log "All builds completed."
    ;;
  android)
    build_android
    ;;
  linux)
    build_linux
    ;;
  ios | macos | windows)
    log "Build script for '$1' is not implemented yet."
    exit 0 # Exit with 0 to not fail CI/CD if one platform is not ready
    ;;
  *)
    log "Error: Unknown platform '$1'"
    usage
    ;;
  esac
}

main "$@"
