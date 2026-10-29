<img width="128px" src="Maccy/Assets.xcassets/AppIcon.appiconset/AppIcon (Big Sur)-256w.png" alt="MacClipboard icon" />

# MacClipboard

[![Release](https://img.shields.io/github/v/release/mk-manishkandel/MacClipboard)](https://github.com/mk-manishkandel/MacClipboard/releases/latest)

MacClipboard is a lightweight, privacy-focused clipboard manager for macOS. It keeps the history of what you copy
and lets you quickly navigate, search, and use previous clipboard contents.

It is an independent fork of [Maccy](https://github.com/p0deje/Maccy) by Alex Rodionov, used under the MIT License.
MacClipboard is not affiliated with or endorsed by the Maccy project. See [Credits and license](#credits-and-license).

MacClipboard works on macOS Sonoma 14 or higher.

## Privacy

* Clipboard history is stored **only on your Mac**, inside the app's sandbox container:
  `~/Library/Containers/com.mkmanishkandel.MacClipboard/Data/Library/Application Support/MacClipboard/Storage.sqlite`.
* The copied contents and titles in that database are **encrypted with AES-256-GCM**. The key is generated on first
  launch and kept in your login Keychain, so the file is unreadable to other apps, backups or anyone who copies it.
* There is no analytics, telemetry, crash reporting or cloud sync.
* The only network request the app makes is the optional update check. It downloads
  [`appcast.xml`](appcast.xml) from this repository and, if you accept an update, the release zip from GitHub Releases.
  Nothing about your clipboard is sent. You can turn the check off in **Settings → General → Check for updates**.

## Install

1. Download `MacClipboard-<version>.zip` from the [latest release](https://github.com/mk-manishkandel/MacClipboard/releases/latest).
2. Unzip it and move `MacClipboard.app` to `/Applications`.
3. The app is not notarized by Apple, so on first launch right-click it and choose **Open**
   (or run `xattr -dr com.apple.quarantine /Applications/MacClipboard.app`).
4. Grant Accessibility permission when asked so it can paste for you.

After that, updates arrive over the air: the app checks this repository's feed and offers to install new versions.
Every update is verified against the EdDSA public key built into the app, so only releases signed by this repository's key are accepted.

## Features

* Lightweight and fast
* Keyboard-first
* Secure and private
* Native UI
* Open source and free

## Usage

1. <kbd>SHIFT (⇧)</kbd> + <kbd>COMMAND (⌘)</kbd> + <kbd>C</kbd> to popup MacClipboard or click on its icon in the menu bar.
2. Type what you want to find.
3. To select the history item you wish to copy, press <kbd>ENTER</kbd>, or click the item, or use <kbd>COMMAND (⌘)</kbd> + `n` shortcut.
4. To choose the history item and paste, press <kbd>OPTION (⌥)</kbd> + <kbd>ENTER</kbd>, or <kbd>OPTION (⌥)</kbd> + <kbd>CLICK</kbd> the item, or use <kbd>OPTION (⌥)</kbd> + `n` shortcut.
5. To choose the history item and paste without formatting, press <kbd>OPTION (⌥)</kbd> + <kbd>SHIFT (⇧)</kbd> + <kbd>ENTER</kbd>, or <kbd>OPTION (⌥)</kbd> + <kbd>SHIFT (⇧)</kbd> + <kbd>CLICK</kbd> the item, or use <kbd>OPTION (⌥)</kbd> + <kbd>SHIFT (⇧)</kbd> + `n` shortcut.
6. To delete the history item, press <kbd>OPTION (⌥)</kbd> + <kbd>DELETE (⌫)</kbd>.
7. To see the full text of the history item, wait a couple of seconds for tooltip.
8. To pin the history item so that it remains on top of the list, press <kbd>OPTION (⌥)</kbd> + <kbd>P</kbd>. The item will be moved to the top with a random but permanent keyboard shortcut. To unpin it, press <kbd>OPTION (⌥)</kbd> + <kbd>P</kbd> again.
9. To clear all unpinned items, select _Clear_ in the menu, or press <kbd>OPTION (⌥)</kbd> + <kbd>COMMAND (⌘)</kbd> + <kbd>DELETE (⌫)</kbd>. To clear all items including pinned, select _Clear_ in the menu with  <kbd>OPTION (⌥)</kbd> pressed, or press <kbd>SHIFT (⇧)</kbd> + <kbd>OPTION (⌥)</kbd> + <kbd>COMMAND (⌘)</kbd> + <kbd>DELETE (⌫)</kbd>.
10. To disable MacClipboard and ignore new copies, click on the menu icon with <kbd>OPTION (⌥)</kbd> pressed.
11. To ignore only the next copy, click on the menu icon with <kbd>OPTION (⌥)</kbd> + <kbd>SHIFT (⇧)</kbd> pressed.
12. To customize the behavior, check "Preferences…" window, or press <kbd>COMMAND (⌘)</kbd> + <kbd>,</kbd>.

## Advanced

### Ignore Copied Items

You can tell MacClipboard to ignore all copied items:

```sh
defaults write com.mkmanishkandel.MacClipboard ignoreEvents true # default is false
```

This is useful if you have some workflow for copying sensitive data. You can set `ignoreEvents` to true, copy the data and set `ignoreEvents` back to false.

You can also click the menu icon with <kbd>OPTION (⌥)</kbd> pressed. To ignore only the next copy, click with <kbd>OPTION (⌥)</kbd> + <kbd>SHIFT (⇧)</kbd> pressed.

### Ignore Custom Copy Types

By default MacClipboard will ignore certain copy types that are considered to be confidential
or temporary. The default list always include the following types:

* `org.nspasteboard.TransientType`
* `org.nspasteboard.ConcealedType`
* `org.nspasteboard.AutoGeneratedType`

Also, default configuration includes the following types but they can be removed
or overwritten:

* `com.agilebits.onepassword`
* `com.typeit4me.clipping`
* `de.petermaurer.TransientPasteboardType`
* `Pasteboard generator type`
* `net.antelle.keeweb`

You can add additional custom types using settings.
To find what custom types are used by an application, you can use
free application [Pasteboard-Viewer](https://github.com/sindresorhus/Pasteboard-Viewer).
Simply download the application, open it, copy something from the application you
want to ignore and look for any custom types in the left sidebar. [Here is an example
of using this approach to ignore Adobe InDesign](https://github.com/p0deje/Maccy/issues/125).

### Speed up Clipboard Check Interval

By default, MacClipboard checks clipboard every 500 ms, which should be enough for most users. If you want
to speed it up, you can change it with `defaults`:

```sh
defaults write com.mkmanishkandel.MacClipboard clipboardCheckInterval 0.1 # 100 ms
```

## FAQ

### Why doesn't it paste when I select an item in history?

1. Make sure you have "Paste automatically" enabled in Preferences.
2. Make sure "MacClipboard" is added to System Settings -> Privacy & Security -> Accessibility.

### When assigning a hotkey to open MacClipboard, it says that this hotkey is already used in some system setting.

1. Open System settings -> Keyboard -> Keyboard Shortcuts.
2. Find where that hotkey is used. For example, "Convert text to simplified Chinese" is under Services -> Text.
3. Disable that hotkey or remove assigned combination ([screenshot](https://github.com/p0deje/Maccy/assets/576152/446719e6-c3e5-4eb0-95fb-5a811066487f)).
4. Restart MacClipboard.
5. Assign hotkey in MacClipboard settings.

### How to restore hidden footer?

1. Open MacClipboard window.
2. Press <kbd>COMMAND (⌘)</kbd> + <kbd>,</kbd> to open preferences.
3. Enable footer in Appearance section.

If for some reason it doesn't work, run the following command in Terminal.app:

```sh
defaults write com.mkmanishkandel.MacClipboard showFooter 1
```

### How to ignore copies from [Universal Clipboard](https://support.apple.com/en-us/102430)?

1. Open Preferences -> Ignore -> Pasteboard Types.
2. Add `com.apple.is-remote-clipboard`.

### My keyboard shortcut stopped working in password fields. How do I fix this?

If your shortcut produces a character (like `Option+C` → "ç"), macOS security may block it in password fields. Use [Karabiner-Elements](https://karabiner-elements.pqrs.org/) to remap your shortcut to a different combination like `Cmd+Shift+C`. [See detailed solution](docs/keyboard-shortcut-password-fields.md).

## Build from source

```sh
git clone https://github.com/mk-manishkandel/MacClipboard.git
cd MacClipboard
xcodebuild -project Maccy.xcodeproj -scheme Maccy -configuration Release -derivedDataPath build \
  CODE_SIGN_IDENTITY="-" CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM="" ENABLE_HARDENED_RUNTIME=NO build
open build/Build/Products/Release
```

The Xcode project, targets and source folders keep their upstream `Maccy` names so upstream fixes can be merged easily.

## Publishing a release (maintainers)

One-time setup on the machine you release from:

```sh
scripts/create-signing-identity.sh
```

This creates a self-signed "MacClipboard Code Signing" certificate in your login Keychain and saves a backup `.p12`
on your Desktop. Every release is signed with it, so the app's signature stays the same between versions and macOS
keeps the Accessibility permission and Keychain access granted after updates. Keep the backup safe: a release signed
with a different certificate makes every user grant Accessibility again.

Then, for each release:

```sh
scripts/release.sh 2.8.1 "What changed in this version."
```

The script bumps the version, builds, zips, signs the update with the Sparkle private key from your Keychain
(account `MacClipboard`), updates `appcast.xml`, creates the GitHub release and pushes the new feed.
Back up the private key with `generate_keys --account MacClipboard -x private-key.txt` and keep it secret:
without it you cannot ship updates to existing installs.

## Credits and license

MacClipboard is a modified version of [Maccy](https://github.com/p0deje/Maccy), Copyright (c) Alex Rodionov,
and is distributed under the [MIT License](LICENSE). "Maccy" is the name of the original project and is used here
only to credit it. MacClipboard has its own name, icon and bundle identifier, and is not affiliated with
or endorsed by the Maccy project.

Translations come from the Maccy community. Third-party libraries and their licenses are listed in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
