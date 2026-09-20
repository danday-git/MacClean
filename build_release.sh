#!/bin/bash
set -e

echo "Building MacClean for Release (Optimized for size: -Osize & dead_strip)..."
swift build -c release -Xswiftc -Osize -Xlinker -dead_strip

RELEASE_BIN=".build/out/Products/Release/MacClean"
APP_DIR="MacClean.app"

echo "Packaging App Bundle structure..."
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copy binary
cp "$RELEASE_BIN" "$APP_DIR/Contents/MacOS/MacClean"

# Strip symbols to achieve minimum possible installation size
echo "Stripping debug symbols..."
strip -u -r "$APP_DIR/Contents/MacOS/MacClean"

# Copy Info.plist and resolve build variable substitutions
cp "MacClean/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
# Replace Xcode build variable $(EXECUTABLE_NAME) with the actual binary name
plutil -replace CFBundleExecutable -string MacClean "$APP_DIR/Contents/Info.plist"

# Ad-hoc code sign for macOS
echo "Applying code signature..."
codesign --force --deep --sign - "$APP_DIR"

# Package release zip
echo "Packaging MacClean.zip for GitHub release..."
rm -f "MacClean.zip"
zip -r -q -9 "MacClean.zip" "$APP_DIR"

BIN_SIZE=$(ls -lh "$APP_DIR/Contents/MacOS/MacClean" | awk '{print $5}')
APP_SIZE=$(du -sh "$APP_DIR" | awk '{print $1}')
ZIP_SIZE=$(du -sh "MacClean.zip" | awk '{print $1}')

echo "=========================================="
echo " MacClean v1.0 Release Package Ready!"
echo "   Binary Size  : $BIN_SIZE"
echo "   App Bundle   : $APP_SIZE"
echo "   Release Zip  : $ZIP_SIZE"
echo "=========================================="
