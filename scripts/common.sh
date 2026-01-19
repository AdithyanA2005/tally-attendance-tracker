#!/usr/bin/env bash
set -e

# Resolve project root
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

APP_NAME="tally"

# Extract version from pubspec.yaml
VERSION="$(grep '^version:' "$ROOT_DIR/pubspec.yaml" | awk '{print $2}' | cut -d+ -f1)"

if [ -z "$VERSION" ]; then
  echo "❌ Could not determine version from pubspec.yaml"
  exit 1
fi

log() {
  echo "▶ $1"
}
