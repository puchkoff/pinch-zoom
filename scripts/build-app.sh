#!/usr/bin/env bash
# Builds a clickable PinchZoom.app bundle and a zip for release.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

app="dist/PinchZoom.app"
macos="$app/Contents/MacOS"

echo "› Building release binary…"
swift build -c release

echo "› Assembling bundle…"
rm -rf "$app"
mkdir -p "$macos" "$app/Contents/Resources"
cp "$(swift build -c release --show-bin-path)/PinchZoom" "$macos/PinchZoom"
cp Resources/Info.plist "$app/Contents/Info.plist"
if [ -f Resources/AppIcon.icns ]; then
  cp Resources/AppIcon.icns "$app/Contents/Resources/AppIcon.icns"
fi

echo "› Ad-hoc signing…"
codesign --force --deep --sign - "$app"

echo "› Zipping…"
( cd dist && ditto -c -k --keepParent PinchZoom.app PinchZoom.app.zip )

echo "✓ Built $app and dist/PinchZoom.app.zip"
