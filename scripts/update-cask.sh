#!/bin/bash
# Writes the Homebrew cask for a release and, if the tap repository exists, publishes it there.
#
# Usage: scripts/update-cask.sh <version> <path/to/MacClipboard-version.zip> [--no-publish]
set -euo pipefail

VERSION="${1:?usage: scripts/update-cask.sh <version> <zip>}"
ZIP="${2:?usage: scripts/update-cask.sh <version> <zip>}"
TAP="mk-manishkandel/homebrew-tap"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CASK="$ROOT/homebrew/Casks/macclipboard.rb"
SHA="$(shasum -a 256 "$ZIP" | cut -d' ' -f1)"

cat > "$CASK" <<CASK
cask "macclipboard" do
  version "$VERSION"
  sha256 "$SHA"

  url "https://github.com/mk-manishkandel/MacClipboard/releases/download/v#{version}/MacClipboard-#{version}.zip"
  name "MacClipboard"
  desc "Private clipboard manager with encrypted local history"
  homepage "https://github.com/mk-manishkandel/MacClipboard"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
  depends_on macos: :sonoma

  app "MacClipboard.app"

  uninstall quit: "com.mkmanishkandel.MacClipboard"

  zap trash: [
    "~/Library/Application Scripts/com.mkmanishkandel.MacClipboard",
    "~/Library/Containers/com.mkmanishkandel.MacClipboard",
  ]

  caveats <<~EOS
    MacClipboard is not notarized by Apple. If macOS blocks it on first launch, open
    System Settings → Privacy & Security and click "Open Anyway", or run:
      xattr -dr com.apple.quarantine /Applications/MacClipboard.app
  EOS
end
CASK
echo "Wrote $CASK"

if [ "${3:-}" = "--no-publish" ]; then
  exit 0
fi

if gh repo view "$TAP" >/dev/null 2>&1; then
  EXISTING_SHA="$(gh api "repos/$TAP/contents/Casks/macclipboard.rb" --jq .sha 2>/dev/null || true)"
  # Commit with the GitHub no-reply address so no personal email is published.
  NOREPLY="$(gh api user --jq '"\(.id)+\(.login)@users.noreply.github.com"')"
  LOGIN="$(gh api user --jq .login)"
  gh api -X PUT "repos/$TAP/contents/Casks/macclipboard.rb" \
    -f message="macclipboard $VERSION" \
    -f "committer[name]=$LOGIN" -f "committer[email]=$NOREPLY" \
    -f "author[name]=$LOGIN" -f "author[email]=$NOREPLY" \
    -f content="$(base64 < "$CASK" | tr -d '\n')" \
    ${EXISTING_SHA:+-f sha="$EXISTING_SHA"} > /dev/null
  echo "Updated $TAP"
else
  echo "Tap $TAP not found; skipped publishing the cask."
fi
