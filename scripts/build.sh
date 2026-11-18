#!/bin/bash
# Builds dist/DarkNotch.app from Sources/DarkNotch.
#
# VERSION      marketing version, defaults to the VERSION file (e.g. 1.2.3)
# BUILD_NUMBER build number, defaults to 1
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${VERSION:-$(tr -d '[:space:]' < "$ROOT/VERSION")}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
APP="$ROOT/dist/DarkNotch.app"

case "$VERSION" in
    *[!0-9.]* | "" | .* | *. | *..*)
        echo "VERSION must look like 1.2.3, got: $VERSION" >&2
        exit 1
        ;;
esac
case "$BUILD_NUMBER" in
    *[!0-9]* | "") echo "BUILD_NUMBER must be an integer, got: $BUILD_NUMBER" >&2; exit 1 ;;
esac

if ! command -v swiftc >/dev/null; then
    echo "swiftc not found. Run: xcode-select --install" >&2
    exit 1
fi
for tool in sips iconutil codesign plutil; do
    if ! command -v "$tool" >/dev/null; then
        echo "$tool not found. Install Apple's command line tools." >&2
        exit 1
    fi
done

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

echo "==> Compiling DarkNotch $VERSION ($BUILD_NUMBER)"
swiftc -O -target arm64-apple-macos13.0 \
    "$ROOT/Sources/DarkNotch/main.swift" \
    -o "$APP/Contents/MacOS/DarkNotch"

echo "==> Building app icon"
ICONSET="$(mktemp -d)/AppIcon.iconset"
trap 'rm -rf "$(dirname "$ICONSET")"' EXIT
mkdir -p "$ICONSET"
for size in 16 32 128 256 512; do
    sips -z "$size" "$size" "$ROOT/Resources/AppIcon.png" \
        --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
    sips -z $((size * 2)) $((size * 2)) "$ROOT/Resources/AppIcon.png" \
        --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

echo "==> Writing Info.plist"
sed -e "s/__VERSION__/$VERSION/g" -e "s/__BUILD__/$BUILD_NUMBER/g" \
    "$ROOT/packaging/Info.plist" > "$APP/Contents/Info.plist"
plutil -lint "$APP/Contents/Info.plist" >/dev/null

# Ad-hoc signature: no Developer ID, but it keeps the bundle internally
# consistent and lets Apple silicon run it after Gatekeeper confirmation.
echo "==> Signing (ad-hoc)"
codesign --force --sign - --identifier com.zheltukheen.darknotch \
    --timestamp=none "$APP"
codesign --verify --strict "$APP"

rm -rf "$ROOT/dist/DarkNotch.app.zip"
ditto -c -k --keepParent "$APP" "$ROOT/dist/DarkNotch.app.zip"

echo "Built $APP"
