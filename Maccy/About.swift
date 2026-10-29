import Cocoa

class About {
  private var upstreamCredits: NSMutableAttributedString {
    let string = NSMutableAttributedString(string: "Based on Maccy by Alex Rodionov (MIT License).",
                                           attributes: [NSAttributedString.Key.foregroundColor: NSColor.labelColor])
    string.addAttribute(.link, value: "https://github.com/p0deje/Maccy", range: NSRange(location: 9, length: 5))
    return string
  }

  private var links: NSMutableAttributedString {
    let string = NSMutableAttributedString(string: "GitHub│Issues",
                                           attributes: [NSAttributedString.Key.foregroundColor: NSColor.labelColor])
    string.addAttribute(.link, value: "https://github.com/mk-manishkandel/MacClipboard", range: NSRange(location: 0, length: 6))
    string.addAttribute(.link, value: "https://github.com/mk-manishkandel/MacClipboard/issues",
                        range: NSRange(location: 7, length: 6))
    return string
  }

  private var credits: NSMutableAttributedString {
    let credits = NSMutableAttributedString(string: "",
                                            attributes: [NSAttributedString.Key.foregroundColor: NSColor.labelColor])
    credits.append(links)
    credits.append(NSAttributedString(string: "\n\n"))
    credits.append(upstreamCredits)
    credits.setAlignment(.center, range: NSRange(location: 0, length: credits.length))
    return credits
  }

  @objc
  func openAbout(_ sender: NSMenuItem?) {
    NSApp.activate(ignoringOtherApps: true)
    NSApp.orderFrontStandardAboutPanel(options: [NSApplication.AboutPanelOptionKey.credits: credits])
  }
}
