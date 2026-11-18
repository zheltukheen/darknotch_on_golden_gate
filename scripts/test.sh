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

VERSION="$VERSION" "$ROOT/scripts/build.sh"

echo "==> Checking app bundle"
[[ -d "$APP" ]] || fail "missing $APP"
[[ -x "$APP/Contents/MacOS/DarkNotch" ]] || fail "missing executable"
[[ -f "$APP/Contents/Resources/AppIcon.icns" ]] || fail "missing icon"
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
[[ -f "$MOUNT/README.txt" ]] || fail "README.txt missing"
[[ "$(readlink "$MOUNT/Applications")" == "/Applications" ]] || fail "bad Applications symlink"
codesign --verify --strict "$MOUNT/DarkNotch.app" || fail "bad signature inside disk image"
[[ "$(plutil -extract CFBundleShortVersionString raw "$MOUNT/DarkNotch.app/Contents/Info.plist")" == "$VERSION" ]] \
    || fail "wrong version inside disk image"

hdiutil detach "$MOUNT" -quiet >/dev/null
DETACHED=1
echo "PASS: DarkNotch $VERSION"
