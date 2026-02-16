#!/bin/bash
set -euo pipefail

APP_NAME="MDown"
BUILD_DIR="build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS="${APP_BUNDLE}/Contents"
MACOS="${CONTENTS}/MacOS"
RESOURCES="${CONTENTS}/Resources"
VERSION_FILE=".build-number"

# Auto-increment build number
if [ -f "$VERSION_FILE" ]; then
    BUILD_NUMBER=$(cat "$VERSION_FILE")
    BUILD_NUMBER=$((BUILD_NUMBER + 1))
else
    BUILD_NUMBER=1
fi
echo "$BUILD_NUMBER" > "$VERSION_FILE"

# Read version from Info.plist
VERSION=$(defaults read "$(pwd)/Resources/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "1.0")

# Build release
echo "Building ${APP_NAME} v${VERSION} (build ${BUILD_NUMBER}) ..."
swift build -c release 2>&1

EXECUTABLE=$(swift build -c release --show-bin-path)/${APP_NAME}

if [ ! -f "$EXECUTABLE" ]; then
    echo "Error: Build failed"
    exit 1
fi

echo "Assembling ${APP_NAME}.app ..."

# Clean and create bundle structure
rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS}" "${RESOURCES}"

# Copy executable
cp "${EXECUTABLE}" "${MACOS}/${APP_NAME}"

# Copy Info.plist and stamp build number
cp "Resources/Info.plist" "${CONTENTS}/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${BUILD_NUMBER}" "${CONTENTS}/Info.plist"

# Copy icon
if [ -f "Resources/MDown.icns" ]; then
    cp "Resources/MDown.icns" "${RESOURCES}/MDown.icns"
fi

echo "Done: ${APP_BUNDLE} — v${VERSION} (build ${BUILD_NUMBER})"
echo "Launch with: open ${APP_BUNDLE}"
