import AppKit.NSSound

// Built-in macOS system sounds, so the app ships no audio files of its own.
extension NSSound {
  static let knock = NSSound(named: "Tink")
  static let write = NSSound(named: "Pop")
}
