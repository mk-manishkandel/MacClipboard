#!/bin/bash
# Builds, signs and publishes a MacClipboard release that existing installs pick up over the air.
#
# Usage: scripts/release.sh <version> "<release notes>"
# Example: scripts/release.sh 2.8.1 "Fixed a crash when pasting images."
#
# Requires: Xcode, gh (logged in), the Sparkle EdDSA private key in your login Keychain under
# the account "MacClipboard" (created by generate_keys), and the "MacClipboard Code Signing"
# identity (created by scripts/create-signing-identity.sh).
set -euo pipefail

VERSION="${1:?usage: scripts/release.sh <version> \"<release notes>\"}"
NOTES="${2:?release notes required}"
REPO="mk-manishkandel/MacClipboard"
TAG="v$VERSION"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PBXPROJ="$ROOT/Maccy.xcodeproj/project.pbxproj"
WORK="$ROOT/release/$TAG"
SPARKLE_BIN="$ROOT/build/SourcePackages/artifacts/sparkle/Sparkle/bin"

cd "$ROOT"

if [ -n "$(git status --porcelain)" ]; then
  echo "Working tree is not clean. Commit or stash your changes first." >&2
  exit 1
fi
if git rev-parse "$TAG" >/dev/null 2>&1; then
  echo "Tag $TAG already exists." >&2
  exit 1
fi

# Sparkle decides what is "newer" by CFBundleVersion, so it must always increase.
BUILD=$(( $(grep -m1 'CURRENT_PROJECT_VERSION = ' "$PBXPROJ" | grep -o '[0-9]\+') + 1 ))
sed -i '' -E "s/CURRENT_PROJECT_VERSION = [0-9]+;/CURRENT_PROJECT_VERSION = $BUILD;/" "$PBXPROJ"
sed -i '' -E "s/MARKETING_VERSION = [0-9.]+;/MARKETING_VERSION = $VERSION;/" "$PBXPROJ"
echo "==> Building $VERSION ($BUILD)"

# Hardened runtime is off because the app is ad-hoc signed: with it on, macOS refuses to load
# the embedded Sparkle framework (different signing identity). Re-enable it with a Developer ID.
xcodebuild -project Maccy.xcodeproj -scheme Maccy -configuration Release -destination 'generic/platform=macOS' \
  -derivedDataPath build \
  CODE_SIGN_IDENTITY="-" CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM="" ENABLE_HARDENED_RUNTIME=NO \
  clean build | grep -E 'error:|BUILD (SUCCEEDED|FAILED)'

APP="build/Build/Products/Release/MacClipboard.app"
if [ "$(lipo -archs "$APP/Contents/MacOS/MacClipboard")" != "x86_64 arm64" ]; then
  echo "Expected a universal (Intel + Apple silicon) build." >&2
  exit 1
fi
# The MIT and third-party licenses require their notices to ship with every copy of the app.
cp LICENSE THIRD_PARTY_NOTICES.md "$APP/Contents/Resources/"
# A stable signing identity keeps Accessibility and Keychain access granted across updates.
if ! security find-identity -v -p codesigning | grep -q '"MacClipboard Code Signing"'; then
  echo "Missing \"MacClipboard Code Signing\" identity. Run scripts/create-signing-identity.sh first." >&2
  exit 1
fi
scripts/sign-app.sh "$APP"
rm -rf "$WORK" && mkdir -p "$WORK"
ZIP="$WORK/MacClipboard-$VERSION.zip"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"

# generate_appcast merges new archives into the existing feed and signs them with the Keychain key.
cp appcast.xml "$WORK/appcast.xml"
printf '<ul>\n<li>%s</li>\n</ul>\n' "$NOTES" > "$WORK/MacClipboard-$VERSION.html"
"$SPARKLE_BIN/generate_appcast" \
  --account MacClipboard \
  --download-url-prefix "https://github.com/$REPO/releases/download/$TAG/" \
  --link "https://github.com/$REPO" \
  --embed-release-notes \
  -o "$WORK/appcast.xml" \
  "$WORK"
cp "$WORK/appcast.xml" appcast.xml

# Newest version first, right below the marker line.
MARKER="<!-- release.sh adds new versions below this line -->"
ENTRY="$(printf '## %s — %s\n\n- %s' "$VERSION" "$(date +%Y-%m-%d)" "$NOTES")"
python3 -I -c 'import sys,pathlib; p=pathlib.Path("CHANGELOG.md"); m,e=sys.argv[1:]; s=p.read_text(); assert m in s; p.write_text(s.replace(m, m+"\n\n"+e, 1))' "$MARKER" "$ENTRY"

echo "==> Publishing GitHub release $TAG"
scripts/update-cask.sh "$VERSION" "$ZIP" --no-publish

git add "$PBXPROJ" appcast.xml CHANGELOG.md homebrew/Casks/macclipboard.rb
git commit -m "Release $VERSION"
git tag "$TAG"
# The zip must be downloadable before the new appcast goes live on main, so push main last.
git push origin "$TAG"
# A fixed-name copy gives the README a download link that always points at the latest release.
cp "$ZIP" "$WORK/MacClipboard.zip"
printf '%s\n\n' "$NOTES" | cat - docs/install-notes.md > "$WORK/release-notes.md"
gh release create "$TAG" "$WORK/MacClipboard.zip" "$ZIP" --repo "$REPO" --title "MacClipboard $VERSION" \
  --notes-file "$WORK/release-notes.md"
git push origin HEAD:main
# Homebrew users get the new version once the zip it points to is downloadable.
scripts/update-cask.sh "$VERSION" "$ZIP"

echo "==> Done. Installed copies will see $VERSION on their next update check."
