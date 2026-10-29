#!/bin/bash
# Signs a built MacClipboard.app and its embedded Sparkle framework with one identity.
#
# Usage: scripts/sign-app.sh <path/to/MacClipboard.app> [identity]
# The identity defaults to "MacClipboard Code Signing" and falls back to ad-hoc ("-") when missing.
set -euo pipefail

APP="${1:?usage: scripts/sign-app.sh <path/to/MacClipboard.app> [identity]}"
IDENTITY="${2:-MacClipboard Code Signing}"

if [ "$IDENTITY" != "-" ] && ! security find-identity -v -p codesigning | grep -q "\"$IDENTITY\""; then
  echo "warning: signing identity \"$IDENTITY\" not found, signing ad-hoc." >&2
  echo "warning: run scripts/create-signing-identity.sh so permissions survive updates." >&2
  IDENTITY="-"
fi

SPARKLE="$APP/Contents/Frameworks/Sparkle.framework"
ENTITLEMENTS="$(mktemp)"
trap 'rm -f "$ENTITLEMENTS"' EXIT
codesign -d --entitlements :- "$APP" > "$ENTITLEMENTS" 2>/dev/null

# Inside-out, in the order Sparkle documents for sandboxed apps.
codesign -f -s "$IDENTITY" "$SPARKLE/Versions/B/XPCServices/Installer.xpc"
codesign -f -s "$IDENTITY" --preserve-metadata=entitlements "$SPARKLE/Versions/B/XPCServices/Downloader.xpc"
codesign -f -s "$IDENTITY" "$SPARKLE/Versions/B/Autoupdate"
codesign -f -s "$IDENTITY" "$SPARKLE/Versions/B/Updater.app"
codesign -f -s "$IDENTITY" "$SPARKLE"
codesign -f -s "$IDENTITY" --entitlements "$ENTITLEMENTS" "$APP"

codesign --verify --deep --strict "$APP"
echo "Signed $APP with: $IDENTITY"
