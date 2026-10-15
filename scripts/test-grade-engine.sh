#!/bin/zsh
set -euo pipefail
SCRIPT_DIR="${0:A:h}"
PROJECT_DIR="${SCRIPT_DIR:h}"
SDK="$(xcrun --sdk macosx --show-sdk-path)"
SWIFTC="$(xcrun --find swiftc)"
ARCH="$(uname -m)"
BUILD_DIR="$PROJECT_DIR/.build/local"
mkdir -p "$BUILD_DIR"
export CLANG_MODULE_CACHE_PATH="$BUILD_DIR/clang-cache"
export SWIFT_MODULECACHE_PATH="$BUILD_DIR/swift-cache"
"$SWIFTC" -sdk "$SDK" -target "$ARCH-apple-macosx14.0" -module-cache-path "$SWIFT_MODULECACHE_PATH" \
  "$PROJECT_DIR/Sources/MacStudy/Models.swift" \
  "$PROJECT_DIR/Sources/MacStudy/GradeEngine.swift" \
  "$PROJECT_DIR/Tests/MacStudyTests/GradeEngineChecks.swift" \
  -o "$BUILD_DIR/GradeEngineChecks"
"$BUILD_DIR/GradeEngineChecks"
"$SWIFTC" -sdk "$SDK" -target "$ARCH-apple-macosx14.0" -module-cache-path "$SWIFT_MODULECACHE_PATH" \
  "$PROJECT_DIR/Sources/MacStudy/Models.swift" \
  "$PROJECT_DIR/Sources/MacStudy/AcademicStore.swift" \
  "$PROJECT_DIR/Tests/MacStudyTests/StoreChecks.swift" \
  -o "$BUILD_DIR/StoreChecks"
"$BUILD_DIR/StoreChecks"
