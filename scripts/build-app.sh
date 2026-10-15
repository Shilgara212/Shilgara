#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_DIR="${SCRIPT_DIR:h}"
SDK="$(xcrun --sdk macosx --show-sdk-path)"
SWIFTC="$(xcrun --find swiftc)"
ARCH="$(uname -m)"
BUILD_DIR="$PROJECT_DIR/.build/local"
APP_DIR="$PROJECT_DIR/dist/Shilgara.app"

mkdir -p "$BUILD_DIR" "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
export CLANG_MODULE_CACHE_PATH="$BUILD_DIR/clang-cache"
export SWIFT_MODULECACHE_PATH="$BUILD_DIR/swift-cache"

"$SWIFTC" -parse-as-library \
  -sdk "$SDK" \
  -target "$ARCH-apple-macosx14.0" \
  -module-cache-path "$SWIFT_MODULECACHE_PATH" \
  -O \
  "$PROJECT_DIR"/Sources/MacStudy/*.swift \
  -o "$APP_DIR/Contents/MacOS/Shilgara"

if [[ ! -f "$PROJECT_DIR/Resources/AppIcon.icns" ]]; then
  mkdir -p "$PROJECT_DIR/Resources"
  "$SWIFTC" -parse-as-library -sdk "$SDK" -target "$ARCH-apple-macosx14.0" \
    -module-cache-path "$SWIFT_MODULECACHE_PATH" \
    "$PROJECT_DIR/scripts/make-icon.swift" -o "$BUILD_DIR/make-icon"
  "$BUILD_DIR/make-icon" "$BUILD_DIR/icon-1024.png"
  ICONSET="$BUILD_DIR/AppIcon.iconset"
  mkdir -p "$ICONSET"
  for SIZE in 16 32 128 256 512; do
    sips -z "$SIZE" "$SIZE" "$BUILD_DIR/icon-1024.png" --out "$ICONSET/icon_${SIZE}x${SIZE}.png" >/dev/null
    DOUBLE=$((SIZE * 2))
    sips -z "$DOUBLE" "$DOUBLE" "$BUILD_DIR/icon-1024.png" --out "$ICONSET/icon_${SIZE}x${SIZE}@2x.png" >/dev/null
  done
  iconutil -c icns "$ICONSET" -o "$PROJECT_DIR/Resources/AppIcon.icns"
fi
cp "$PROJECT_DIR/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"

cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleExecutable</key><string>Shilgara</string>
  <key>CFBundleIdentifier</key><string>com.macstudy.academiccompanion</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleName</key><string>Shilgara</string>
  <key>CFBundleDisplayName</key><string>Shilgara</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST

codesign --force --sign - "$APP_DIR"

echo "Built $APP_DIR"
