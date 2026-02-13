#!/bin/bash
set -euo pipefail

APP_NAME="MDown"
BUILD_DIR="build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS="${APP_BUNDLE}/Contents"
MACOS="${CONTENTS}/MacOS"

# Find the SPM build output
EXECUTABLE=$(swift build --show-bin-path)/${APP_NAME}

if [ ! -f "$EXECUTABLE" ]; then
    echo "Error: Build first with 'swift build' or 'make build'"
    exit 1
fi

echo "Assembling ${APP_NAME}.app ..."

# Clean and create bundle structure
rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS}"

# Copy executable
cp "${EXECUTABLE}" "${MACOS}/${APP_NAME}"

# Copy Info.plist
cp "Resources/Info.plist" "${CONTENTS}/Info.plist"

echo "Done: ${APP_BUNDLE}"
echo "Launch with: open ${APP_BUNDLE}"
