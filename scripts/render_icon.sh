#!/bin/bash
# Renders Resources/AppIcon.svg to the 1024x1024 PNG used by build.sh.
# Needs Google Chrome for correct SVG filters and gradients.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
SVG="$ROOT/Resources/AppIcon.svg"
OUT="$ROOT/Resources/AppIcon.png"

if [[ ! -x "$CHROME" ]]; then
    echo "Google Chrome not found. Set CHROME=/path/to/chrome." >&2
    exit 1
fi

HTML="$(mktemp -d)/icon.html"
trap 'rm -rf "$(dirname "$HTML")"' EXIT
cat > "$HTML" <<HTML
<!doctype html><html><head><style>
html,body{margin:0;padding:0;background:transparent}
img{display:block;width:1024px;height:1024px}
</style></head><body>
<img src="file://$SVG" width="1024" height="1024">
</body></html>
HTML

"$CHROME" --headless=new --disable-gpu --hide-scrollbars \
    --default-background-color=00000000 --window-size=1024,1024 \
    --screenshot="$OUT" "file://$HTML" >/dev/null 2>&1

echo "Wrote $OUT"
