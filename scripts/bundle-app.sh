#!/usr/bin/env bash
# Builds Porticide in release mode and wraps the binary in a signed .app bundle.
#
# Usage: scripts/bundle-app.sh [--universal] [output-dir]   (default output: build/)
#   --universal   build for both Apple silicon and Intel
#   VERSION=1.2.0 overrides CFBundleShortVersionString (used by the release workflow)
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="Porticide"
BUILD_FLAGS=(-c release --product "$APP_NAME")
if [[ "${1:-}" == "--universal" ]]; then
    BUILD_FLAGS+=(--arch arm64 --arch x86_64)
    shift
fi
OUTPUT_DIR="${1:-build}"
APP_DIR="$OUTPUT_DIR/$APP_NAME.app"

swift build "${BUILD_FLAGS[@]}"
BIN_DIR="$(swift build "${BUILD_FLAGS[@]}" --show-bin-path)"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

cp "$BIN_DIR/$APP_NAME" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp -R "$BIN_DIR/${APP_NAME}_${APP_NAME}.bundle" "$APP_DIR/Contents/Resources/"
cp Support/Info.plist "$APP_DIR/Contents/Info.plist"
cp Support/AppIcon.icns "$APP_DIR/Contents/Resources/AppIcon.icns"

if [[ -n "${VERSION:-}" ]]; then
    plutil -replace CFBundleShortVersionString -string "$VERSION" "$APP_DIR/Contents/Info.plist"
fi

# Ad-hoc signature: enough to run locally and to register as a login item.
codesign --force --sign - --timestamp=none "$APP_DIR"

echo "Built $APP_DIR"
