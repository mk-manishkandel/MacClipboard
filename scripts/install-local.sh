#!/bin/bash
# Builds MacClipboard, signs it with the stable identity and installs it to /Applications.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
APP="build/Build/Products/Release/MacClipboard.app"

xcodebuild -project Maccy.xcodeproj -scheme Maccy -configuration Release -derivedDataPath build \
  CODE_SIGN_IDENTITY="-" CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM="" ENABLE_HARDENED_RUNTIME=NO \
  build | grep -E 'error:|BUILD (SUCCEEDED|FAILED)'
cp LICENSE THIRD_PARTY_NOTICES.md "$APP/Contents/Resources/"
scripts/sign-app.sh "$APP"

osascript -e 'quit app id "com.mkmanishkandel.MacClipboard"' 2>/dev/null || true
sleep 2
rm -rf /Applications/MacClipboard.app
cp -R "$APP" /Applications/
open /Applications/MacClipboard.app
echo "Installed /Applications/MacClipboard.app"
