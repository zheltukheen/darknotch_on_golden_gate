#!/bin/bash
# Builds the signed Sparkle appcast for the current release.
#
# VERSION             marketing version
# TAG                 release tag, e.g. v1.1.0
# REPO                owner/name on GitHub
# SPARKLE_PRIVATE_KEY EdDSA private key (base64), normally a CI secret
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${VERSION:-$(tr -d '[:space:]' < "$ROOT/VERSION")}"
TAG="${TAG:-v$VERSION}"
REPO="${REPO:-zheltukheen/darknotch_on_golden_gate}"
ZIP="${ZIP:-$ROOT/dist/DarkNotch-$VERSION.zip}"
PRIVATE_KEY="${SPARKLE_PRIVATE_KEY:-}"

if [[ -z "$PRIVATE_KEY" ]]; then
    echo "SPARKLE_PRIVATE_KEY is not set" >&2
    exit 1
fi
if [[ ! -f "$ZIP" ]]; then
    echo "Missing $ZIP" >&2
    exit 1
fi

SPARKLE_DIR="$("$ROOT/scripts/fetch-sparkle.sh")"
UPDATES="$(mktemp -d)"
trap 'rm -rf "$UPDATES"' EXIT
cp "$ZIP" "$UPDATES/"

echo "==> Generating appcast for $VERSION"
printf '%s\n' "$PRIVATE_KEY" | "$SPARKLE_DIR/bin/generate_appcast" \
    --ed-key-file - \
    --download-url-prefix "https://github.com/$REPO/releases/download/$TAG/" \
    --link "https://github.com/$REPO" \
    -o "$ROOT/dist/appcast.xml" "$UPDATES"

test -s "$ROOT/dist/appcast.xml"
echo "Built $ROOT/dist/appcast.xml"
