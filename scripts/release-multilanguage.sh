#!/bin/bash
# Build and package the community fork without requiring the original author's signing credentials.
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-1.4.7-multilanguage.1}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$PROJECT_DIR/dist/DerivedData}"
DIST="$PROJECT_DIR/dist"
mkdir -p "$DIST"
xcodebuild -project "$PROJECT_DIR/Compositor.xcodeproj" -scheme Compositor \
  -configuration Release -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath "$DERIVED_DATA_PATH" CODE_SIGNING_ALLOWED=NO build
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/compositor-multilanguage.XXXXXX")"
APP_PATH="$STAGE/Compositor Multilanguage.app"
ditto "$DERIVED_DATA_PATH/Build/Products/Release/Compositor.app" "$APP_PATH"
# Ad-hoc signing supplies a local code signature; it is not Developer ID signing or Apple notarization.
codesign --force --deep --sign - "$APP_PATH"
codesign --verify --deep --strict "$APP_PATH"
ZIP="$DIST/Compositor-Multilanguage-$VERSION-macos-arm64.zip"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP"
(cd "$DIST" && shasum -a 256 "$(basename "$ZIP")" > "$(basename "$ZIP").sha256")
echo "Release asset: $ZIP"
echo "This build is ad-hoc signed and is not notarized by Apple."
