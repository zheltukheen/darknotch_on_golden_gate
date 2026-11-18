#!/bin/bash
# End-to-end check: build the app, sign-check it, build the DMG and inspect its
# mounted contents. This is the release gate used by CI.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${VERSION:-$(tr -d '[:space:]' < "$ROOT/VERSION")}"
APP="$ROOT/dist/DarkNotch.app"
DMG="$ROOT/dist/DarkNotch-$VERSION.dmg"
MOUNT="$(mktemp -d)"
DETACHED=0

cleanup() {
    if [[ "$DETACHED" == "0" ]]; then
        hdiutil detach "$MOUNT" -quiet >/dev/null 2>&1 || true
    fi
    rm -rf "$MOUNT"
}
trap cleanup EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }

"$ROOT/scripts/check-translations.py"
VERSION="$VERSION" "$ROOT/scripts/build.sh"

echo "==> Checking app bundle"
[[ -d "$APP" ]] || fail "missing $APP"
[[ -x "$APP/Contents/MacOS/DarkNotch" ]] || fail "missing executable"
[[ -f "$APP/Contents/Resources/AppIcon.icns" ]] || fail "missing icon"
[[ -f "$APP/Contents/Resources/LICENSE" ]] || fail "missing license"
[[ -d "$APP/Contents/Frameworks/Sparkle.framework" ]] || fail "missing Sparkle"
[[ -f "$APP/Contents/Resources/LICENSE-SPARKLE" ]] || fail "missing Sparkle license"
otool -L "$APP/Contents/MacOS/DarkNotch" | grep -q "Sparkle.framework" || fail "Sparkle is not linked"
[[ "$(find "$APP/Contents/Resources/i18n" -name "*.json" | wc -l | tr -d " ")" -ge 10 ]] || fail "missing translations"
[[ -f "$APP/Contents/Resources/i18n/ru.json" ]] || fail "missing Russian translation"
[[ "$(plutil -extract SUPublicEDKey raw "$APP/Contents/Info.plist")" == "$(tr -d '[:space:]' < "$ROOT/packaging/sparkle-public-key.txt")" ]] \
    || fail "wrong Sparkle public key"
[[ "$(plutil -extract CFBundleIdentifier raw "$APP/Contents/Info.plist")" == "com.zheltukheen.darknotch" ]] \
    || fail "wrong bundle identifier"
[[ "$(plutil -extract CFBundleShortVersionString raw "$APP/Contents/Info.plist")" == "$VERSION" ]] \
    || fail "wrong version"
[[ "$(lipo -archs "$APP/Contents/MacOS/DarkNotch")" == "arm64" ]] || fail "not an arm64 binary"
codesign --verify --strict "$APP" || fail "bad signature"

VERSION="$VERSION" SKIP_BUILD=1 "$ROOT/scripts/make-dmg.sh"
[[ -f "$DMG" ]] || fail "missing $DMG"

echo "==> Checking disk image"
hdiutil verify "$DMG" >/dev/null || fail "corrupt disk image"
hdiutil attach "$DMG" -nobrowse -readonly -mountpoint "$MOUNT" >/dev/null
[[ -d "$MOUNT/DarkNotch.app" ]] || fail "app missing from disk image"
[[ -L "$MOUNT/Applications" ]] || fail "Applications symlink missing"
[[ -f "$MOUNT/Install.html" ]] || fail "Install.html missing"
[[ ! -e "$MOUNT/README.txt" ]] || fail "old README.txt still in the image"
[[ -f "$MOUNT/.DS_Store" ]] || fail "Finder layout missing"
[[ -f "$MOUNT/.background.tiff" || -f "$MOUNT/.background.png" ]] || fail "DMG background missing"
[[ "$(readlink "$MOUNT/Applications")" == "/Applications" ]] || fail "bad Applications symlink"
codesign --verify --deep --strict "$MOUNT/DarkNotch.app" || fail "bad signature inside disk image"
[[ "$(plutil -extract CFBundleShortVersionString raw "$MOUNT/DarkNotch.app/Contents/Info.plist")" == "$VERSION" ]] \
    || fail "wrong version inside disk image"

hdiutil detach "$MOUNT" -quiet >/dev/null
DETACHED=1

if [[ -n "${SPARKLE_PRIVATE_KEY:-}" ]]; then
    VERSION="$VERSION" "$ROOT/scripts/make-appcast.sh" >/dev/null
    grep -q "sparkle:edSignature" "$ROOT/dist/appcast.xml" || fail "appcast has no signature"
fi

echo "PASS: DarkNotch $VERSION"
