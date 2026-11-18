#!/bin/bash
# Downloads the pinned Sparkle release and prints the directory containing
# Sparkle.framework and bin/sign_update. Cached under .build/.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="2.10.1"
SHA256="1a856d2a9edb8e628de88121d7be04cf0e2167f8641650b78fca00b14244cf27"
DIR="$ROOT/.build/sparkle-$VERSION"

if [[ -d "$DIR/Sparkle.framework" && -x "$DIR/bin/sign_update" ]]; then
    echo "$DIR"
    exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
echo "==> Downloading Sparkle $VERSION" >&2
curl -L --fail --silent --show-error --retry 3 \
    -o "$TMP/Sparkle.tar.xz" \
    "https://github.com/sparkle-project/Sparkle/releases/download/$VERSION/Sparkle-$VERSION.tar.xz"
echo "$SHA256  $TMP/Sparkle.tar.xz" | shasum -a 256 -c - >/dev/null
tar -xf "$TMP/Sparkle.tar.xz" -C "$TMP"

rm -rf "$DIR"
mkdir -p "$DIR"
mv "$TMP/Sparkle.framework" "$TMP/bin" "$DIR"/
echo "$DIR"
