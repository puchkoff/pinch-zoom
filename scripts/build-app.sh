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
version="$(cat VERSION)"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $version" -c "Set :CFBundleVersion $version" "$app/Contents/Info.plist"
if [ -f Resources/AppIcon.icns ]; then
  cp Resources/AppIcon.icns "$app/Contents/Resources/AppIcon.icns"
fi

# Always sign with the same certificate. macOS ties the Accessibility
# permission to it, so a new build keeps the permission. Ad-hoc signing
# changes identity on every build and the permission silently stops working.
# Setup: see SIGNING.md.
identity="${SIGN_IDENTITY:-Oleg Puchkov Local Code Signing}"
echo "› Signing with \"$identity\"…"
if ! codesign --force --deep --sign "$identity" "$app"; then
  echo "✗ Signing failed. Is the certificate in your keychain? See SIGNING.md." >&2
  exit 1
fi

echo "› Zipping…"
( cd dist && ditto -c -k --keepParent PinchZoom.app PinchZoom.app.zip )

echo "✓ Built $app and dist/PinchZoom.app.zip"
