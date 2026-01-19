#!/usr/bin/env bash
set -euo pipefail

# ----------------------------------
# Load shared configuration
# ----------------------------------
source "$(dirname "$0")/common.sh"

# ----------------------------------
# Paths and constants
# ----------------------------------
APPDIR="${APP_NAME}.AppDir"
BUILD_DIR="$ROOT_DIR/build/linux/x64/release/bundle"
ICON_SRC="$ROOT_DIR/assets/icon/icon.png"

cd "$ROOT_DIR"

log "Detecting architecture"
UNAME_ARCH="$(uname -m)"

case "$UNAME_ARCH" in
x86_64)
  ARCH="x86_64"
  APPIMAGETOOL_URL="https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
  APPIMAGETOOL_BIN="appimagetool-x86_64.AppImage"
  ;;
aarch64)
  ARCH="aarch64"
  APPIMAGETOOL_URL="https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-aarch64.AppImage"
  APPIMAGETOOL_BIN="appimagetool-aarch64.AppImage"
  ;;
*)
  echo "❌ Unsupported architecture: $UNAME_ARCH"
  exit 1
  ;;
esac

log "Architecture: $ARCH"
log "Version: $VERSION"

# ----------------------------------
# Build Flutter app
# ----------------------------------
log "Building Flutter Linux release"
flutter build linux --release

# ----------------------------------
# Prepare AppDir
# ----------------------------------
log "Cleaning old AppDir"
rm -rf "$APPDIR"

log "Creating AppDir structure"
mkdir -p \
  "$APPDIR/usr/bin" \
  "$APPDIR/usr/share/applications" \
  "$APPDIR/usr/share/icons/hicolor/256x256/apps"

log "Copying Flutter bundle"
cp -r "$BUILD_DIR/"* "$APPDIR/usr/bin/"
chmod +x "$APPDIR/usr/bin/$APP_NAME"

# ----------------------------------
# Desktop entry
# ----------------------------------
log "Creating desktop entry"
cat >"$APPDIR/usr/share/applications/$APP_NAME.desktop" <<EOF
[Desktop Entry]
Name=$APP_NAME
Exec=$APP_NAME
Icon=$APP_NAME
Terminal=false
Type=Application
Categories=Utility;
StartupWMClass=$APP_NAME
EOF

# Required by AppImage
cp "$APPDIR/usr/share/applications/$APP_NAME.desktop" \
  "$APPDIR/$APP_NAME.desktop"

# ----------------------------------
# Icon
# ----------------------------------
log "Copying icon"
cp "$ICON_SRC" \
  "$APPDIR/usr/share/icons/hicolor/256x256/apps/$APP_NAME.png"
cp "$ICON_SRC" "$APPDIR/$APP_NAME.png"

# ----------------------------------
# AppRun
# ----------------------------------
log "Creating AppRun"
cat >"$APPDIR/AppRun" <<EOF
#!/bin/bash
set -e
HERE="\$(dirname "\$(readlink -f "\$0")")"
exec "\$HERE/usr/bin/$APP_NAME" "\$@"
EOF

chmod +x "$APPDIR/AppRun"

# ----------------------------------
# Download appimagetool
# ----------------------------------
log "Downloading appimagetool"
if [ ! -f "$APPIMAGETOOL_BIN" ]; then
  wget -q "$APPIMAGETOOL_URL" -O "$APPIMAGETOOL_BIN"
  chmod +x "$APPIMAGETOOL_BIN"
fi

# ----------------------------------
# Build AppImage
# ----------------------------------
APPIMAGE_TMP="$(mktemp --suffix=.AppImage)"

log "Building AppImage"
ARCH="$ARCH" "./$APPIMAGETOOL_BIN" "$APPDIR" "$APPIMAGE_TMP"

if [ ! -f "$APPIMAGE_TMP" ]; then
  echo "❌ AppImage was not created"
  exit 1
fi

FINAL_NAME="${APP_NAME}-${VERSION}-${ARCH}.AppImage"

log "Moving final AppImage to project root: $FINAL_NAME"
mv "$APPIMAGE_TMP" "$ROOT_DIR/$FINAL_NAME"

# ----------------------------------
# Cleanup
# ----------------------------------
log "Cleaning temporary artifacts"
rm -rf "$APPDIR"
rm -f "$APPIMAGETOOL_BIN"

log "Done"
ls -lh "$FINAL_NAME"
