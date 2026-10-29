cask "macclipboard" do
  version "2.8.7"
  sha256 "6cf9a6a711388970e5668eec10d465322db4e060f9c5500fc173c4501ca86ce0"

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
