#!/usr/bin/env bash
# Builds Porticide in release mode and wraps the binary in a signed .app bundle.
#
# Usage: scripts/bundle-app.sh [output-dir]   (default: build/)
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="Porticide"
OUTPUT_DIR="${1:-build}"
APP_DIR="$OUTPUT_DIR/$APP_NAME.app"

swift build -c release --product "$APP_NAME"
BIN_DIR="$(swift build -c release --show-bin-path)"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

cp "$BIN_DIR/$APP_NAME" "$APP_DIR/Contents/MacOS/$APP_NAME"
if [[ -d "$BIN_DIR/${APP_NAME}_${APP_NAME}.bundle" ]]; then
    cp -R "$BIN_DIR/${APP_NAME}_${APP_NAME}.bundle" "$APP_DIR/Contents/Resources/"
fi
cp Support/Info.plist "$APP_DIR/Contents/Info.plist"
cp Support/AppIcon.icns "$APP_DIR/Contents/Resources/AppIcon.icns"

# Ad-hoc signature: enough to run locally and to register as a login item.
codesign --force --sign - --timestamp=none "$APP_DIR"

echo "Built $APP_DIR"
