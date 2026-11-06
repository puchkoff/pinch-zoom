#!/usr/bin/env bash
# Builds, signs, tags, and publishes a GitHub release for the version in VERSION.
# Usage: scripts/release.sh            (release current VERSION)
#        scripts/release.sh 1.2.0      (set VERSION to 1.2.0 first)
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

if [ $# -ge 1 ]; then echo "$1" > VERSION; fi
version="$(cat VERSION)"
if [ -z "$version" ]; then
  echo "✗ VERSION is empty." >&2
  exit 1
fi
tag="v$version"

if [ -n "$(git status --porcelain)" ] && [ $# -eq 0 ]; then
  echo "✗ Working tree is not clean. Commit first." >&2
  exit 1
fi
if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
  echo "✗ Tag $tag already exists. Bump VERSION." >&2
  exit 1
fi

scripts/build-app.sh
codesign --verify --deep --strict dist/PinchZoom.app

if [ -n "$(git status --porcelain -- VERSION)" ]; then
  git add VERSION
  git commit -m "Release $tag"
fi
git tag "$tag"
git push origin HEAD "$tag"

gh release create "$tag" dist/PinchZoom.app.zip \
  --title "PinchZoom $version" \
  --notes "Signed with the \"Oleg Puchkov Local Code Signing\" certificate, so the Accessibility permission carries over from earlier releases. Install: unzip, move PinchZoom.app to /Applications, then run \`xattr -dr com.apple.quarantine /Applications/PinchZoom.app\`."

echo "✓ Released $tag"
