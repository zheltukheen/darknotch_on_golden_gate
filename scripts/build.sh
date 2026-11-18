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
for tool in sips iconutil codesign plutil ditto; do
    if ! command -v "$tool" >/dev/null; then
        echo "$tool not found. Install Apple's command line tools." >&2
        exit 1
    fi
done

SPARKLE_DIR="$("$ROOT/scripts/fetch-sparkle.sh")"
PUBLIC_KEY="$(tr -d '[:space:]' < "$ROOT/packaging/sparkle-public-key.txt")"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Frameworks"

echo "==> Compiling DarkNotch $VERSION ($BUILD_NUMBER)"
swiftc -O -target arm64-apple-macos13.0 \
    "$ROOT/Sources/DarkNotch/main.swift" \
    "$ROOT/Sources/DarkNotch/L10n.swift" \
    -F "$SPARKLE_DIR" -framework Sparkle \
    -Xlinker -rpath -Xlinker @executable_path/../Frameworks \
    -o "$APP/Contents/MacOS/DarkNotch"

echo "==> Embedding Sparkle"
ditto "$SPARKLE_DIR/Sparkle.framework" "$APP/Contents/Frameworks/Sparkle.framework"

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

cp "$ROOT/LICENSE" "$APP/Contents/Resources/LICENSE"
cp "$ROOT/Resources/LICENSE-SPARKLE" "$APP/Contents/Resources/LICENSE-SPARKLE"
cp -R "$ROOT/Resources/i18n" "$APP/Contents/Resources/i18n"

echo "==> Writing Info.plist"
sed -e "s/__VERSION__/$VERSION/g" \
    -e "s/__BUILD__/$BUILD_NUMBER/g" \
    -e "s|__SPARKLE_PUBLIC_KEY__|$PUBLIC_KEY|g" \
    "$ROOT/packaging/Info.plist" > "$APP/Contents/Info.plist"
plutil -lint "$APP/Contents/Info.plist" >/dev/null

# Ad-hoc signature: no Developer ID, but it keeps the bundle internally
# consistent and lets Apple silicon run it after Gatekeeper confirmation.
echo "==> Signing (ad-hoc)"
codesign --force --sign - --identifier com.zheltukheen.darknotch \
    --timestamp=none "$APP"
codesign --verify --deep --strict "$APP"

rm -f "$ROOT/dist/DarkNotch.app.zip" "$ROOT/dist/DarkNotch-$VERSION.zip"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ROOT/dist/DarkNotch-$VERSION.zip"

echo "Built $APP"
