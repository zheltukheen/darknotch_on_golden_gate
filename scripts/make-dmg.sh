#!/bin/bash
# Builds the styled, self-opening DarkNotch disk image.
#
# Requires scripts/build.sh to have produced dist/DarkNotch.app, or it runs it.
# Output: dist/DarkNotch-<version>.dmg
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${VERSION:-$(tr -d '[:space:]' < "$ROOT/VERSION")}"
APP="$ROOT/dist/DarkNotch.app"
DMG="$ROOT/dist/DarkNotch-$VERSION.dmg"
README="$ROOT/Resources/dmg/README.txt"
BACKGROUND="$ROOT/Resources/dmg/background.png"
VENV="$ROOT/.build/dmg-venv"

if [[ ! -d "$APP" || "${SKIP_BUILD:-0}" != "1" ]]; then
    VERSION="$VERSION" "$ROOT/scripts/build.sh"
fi
for file in "$README" "$BACKGROUND"; do
    if [[ ! -f "$file" ]]; then
        echo "Missing $file" >&2
        exit 1
    fi
done

if ! "$VENV/bin/python" -c "import dmgbuild" >/dev/null 2>&1; then
    echo "==> Installing dmgbuild"
    python3 -m venv "$VENV"
    PIP_DISABLE_PIP_VERSION_CHECK=1 "$VENV/bin/pip" install --quiet \
        -r "$ROOT/packaging/requirements-dmg.txt"
fi

rm -f "$DMG"
echo "==> Building $DMG"
cd "$ROOT"
"$VENV/bin/dmgbuild" \
    -s "$ROOT/packaging/dmg_settings.py" \
    -D "app=$APP" \
    -D "readme=$README" \
    -D "background=$BACKGROUND" \
    -D "filename=$DMG" \
    -D "version=$VERSION" \
    "DarkNotch $VERSION" "$DMG"

hdiutil verify "$DMG" >/dev/null
echo "Built $DMG"
