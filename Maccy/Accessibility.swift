import AppKit

struct Accessibility {
  private static var allowed: Bool { AXIsProcessTrustedWithOptions(nil) }

  // Pasting needs Accessibility permission. Without it the paste silently does nothing,
  // so ask macOS to show its prompt, which links straight to the Accessibility settings.
  static func check() {
    guard !allowed else {
      return
    }

    let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
    AXIsProcessTrustedWithOptions(options)
  }
}
