# What's new in MacClipboard

The latest version is always available from the
[download link](https://github.com/mk-manishkandel/MacClipboard/releases/latest/download/MacClipboard.zip).
Already installed? MacClipboard updates itself, or open **Settings → General → Check now**.

<!-- release.sh adds new versions below this line -->

## 2.8.5 — 2026-10-29

- Passwords, API keys, card numbers and one-time codes are now removed from history after 30 seconds. New setting to delete old history automatically (Settings → Storage → Keep history for). The details panel no longer opens by itself (press ⌃Space to open it). If pasting is blocked, MacClipboard now asks for the Accessibility permission instead of silently doing nothing.

## 2.8.4 — 2026-10-29

- The history popup is simpler: Preferences, About and Quit are now in the menu bar icon's menu.

## 2.8.3 — 2026-10-29

- Clicking the menu bar icon now opens a menu. Choose **History** to see your clipboard history, or press **⇧⌘C**.

## 2.8.2 — 2026-10-29

- Now runs on Intel Macs as well as Apple silicon.

## 2.8.1 — 2026-10-29

First MacClipboard release, based on [Maccy](https://github.com/p0deje/Maccy) 2.8.0.

- New name, icon and app identity.
- Clipboard history is encrypted on your Mac with a key kept in your Keychain.
- Picking an item pastes it straight into the text field you were typing in.
- Updates install over the air from this repository and are cryptographically verified.
- No analytics, tracking or cloud sync: the only network request is the update check.
