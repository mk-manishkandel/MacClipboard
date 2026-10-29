#!/bin/bash
# Renders the app screen images in docs/screenshots from scripts/screenshots/mockups.html.
# Needs Google Chrome. Edit mockups.html when the app's UI changes, then run this script.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/scripts/screenshots/mockups.html"
OUT="$ROOT/docs/screenshots"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

[ -x "$CHROME" ] || { echo "Google Chrome is required." >&2; exit 1; }
mkdir -p "$OUT"

# scene in mockups.html : output file name
for pair in history:history pasteas:paste-as settings:settings; do
  scene="${pair%%:*}"
  name="${pair##*:}"
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=2 \
    --window-size=1200,760 --user-data-dir="$TMP/profile" \
    --screenshot="$TMP/$name.png" "file://$SRC#$scene" >/dev/null 2>&1
  sips -Z 1600 "$TMP/$name.png" >/dev/null
  sips -s format jpeg -s formatOptions 88 "$TMP/$name.png" --out "$OUT/$name.jpg" >/dev/null
  echo "Wrote docs/screenshots/$name.jpg"
done
