#!/usr/bin/env bash
set -e
source "$(dirname "$0")/common.sh"

log "Starting Android release build"
log "Version: $VERSION"

cd "$ROOT_DIR"

# ---------------------------
# Build APK (direct install)
# ---------------------------
log "Building Android APK (release)"
flutter build apk --release

APK_SRC="build/app/outputs/flutter-apk/app-release.apk"
APK_DST="${APP_NAME}-${VERSION}.apk"

if [ ! -f "$APK_SRC" ]; then
  echo "❌ APK not found at expected location"
  exit 1
fi

cp "$APK_SRC" "$APK_DST"
log "APK created: $APK_DST"

# -----------------------------------
# Build App Bundle (Play Store upload)
# -----------------------------------
log "Building Android App Bundle (AAB)"
flutter build appbundle --release

AAB_SRC="build/app/outputs/bundle/release/app-release.aab"
AAB_DST="${APP_NAME}-${VERSION}.aab"

if [ ! -f "$AAB_SRC" ]; then
  echo "❌ AAB not found at expected location"
  exit 1
fi

cp "$AAB_SRC" "$AAB_DST"
log "AAB created: $AAB_DST"

log "Android build completed successfully"
ls -lh "$APK_DST" "$AAB_DST"
