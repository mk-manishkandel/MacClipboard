import Defaults
import Foundation

// Recognizes copied text that looks like a secret: API keys and tokens, private keys,
// credit card numbers, one-time codes and passwords. Copies that password managers
// mark as concealed are already skipped in Clipboard before this runs.
nonisolated enum SensitiveContent {
  enum Handling: String, CaseIterable, Identifiable, CustomStringConvertible, Defaults.Serializable {
    case removeAfterDelay
    case ignore
    case save

    static let removalDelay: Duration = .seconds(30)

    var id: Self { self }

    var description: String {
      switch self {
      case .removeAfterDelay:
        return NSLocalizedString("SensitiveRemoveAfterDelay", tableName: "StorageSettings",
                                 value: "Remove after 30 seconds", comment: "")
      case .ignore:
        return NSLocalizedString("SensitiveIgnore", tableName: "StorageSettings",
                                 value: "Don't save", comment: "")
      case .save:
        return NSLocalizedString("SensitiveSave", tableName: "StorageSettings",
                                 value: "Save like other copies", comment: "")
      }
    }
  }

  // Long copies are documents or code, not secrets, unless they carry a known token.
  private static let maxScannedLength = 20_000

  private static let tokenPatterns: [NSRegularExpression] = [
    #"-----BEGIN [A-Z ]*PRIVATE KEY-----"#,
    #"\b(?:AKIA|ASIA)[0-9A-Z]{16}\b"#,                            // AWS access key
    #"\bgh[pousr]_[A-Za-z0-9]{36,}\b"#,                          // GitHub token
    #"\bgithub_pat_[A-Za-z0-9_]{60,}\b"#,                        // GitHub fine-grained token
    #"\bxox[abposr]-[A-Za-z0-9-]{10,}"#,                         // Slack token
    #"\b(?:sk|rk)_(?:live|test)_[A-Za-z0-9]{16,}\b"#,            // Stripe secret key
    #"\bsk-(?:ant-|proj-)?[A-Za-z0-9_-]{20,}"#,                  // OpenAI / Anthropic key
    #"\bAIza[0-9A-Za-z_-]{35}\b"#,                               // Google API key
    #"\beyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}"# // JWT
  ].map { try! NSRegularExpression(pattern: $0) } // swiftlint:disable:this force_try

  private static let oneTimeCode = try! NSRegularExpression( // swiftlint:disable:this force_try
    pattern: #"^(?:\d{6,8}|\d{3}[ -]\d{3})$"#
  )

  static func isSensitive(_ string: String?) -> Bool {
    guard let string, string.count <= maxScannedLength else { return false }

    let range = NSRange(string.startIndex..., in: string)
    if tokenPatterns.contains(where: { $0.firstMatch(in: string, range: range) != nil }) {
      return true
    }

    let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
    return isCreditCardNumber(trimmed) || isOneTimeCode(trimmed) || isPassword(trimmed)
  }

  static func isCreditCardNumber(_ string: String) -> Bool {
    guard string.allSatisfy({ $0.isASCII && ($0.isNumber || $0 == " " || $0 == "-") }) else { return false }

    let digits = string.compactMap(\.wholeNumberValue)
    guard (13...19).contains(digits.count) else { return false }

    // Luhn checksum.
    let sum = digits.reversed().enumerated().reduce(0) { sum, pair in
      let (index, digit) = pair
      guard index.isMultiple(of: 2) else {
        let doubled = digit * 2
        return sum + (doubled > 9 ? doubled - 9 : doubled)
      }
      return sum + digit
    }
    return sum.isMultiple(of: 10)
  }

  static func isOneTimeCode(_ string: String) -> Bool {
    oneTimeCode.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)) != nil
  }

  // A single word mixing lowercase, uppercase, digits and symbols, which is how generated
  // and strong passwords look. Links, email addresses and paths are excluded.
  static func isPassword(_ string: String) -> Bool {
    guard (8...64).contains(string.count),
          !string.contains(where: \.isWhitespace),
          !string.contains("://"),
          !string.hasPrefix("/"), !string.hasPrefix("~"),
          !isEmailAddress(string) else {
      return false
    }

    return string.contains(where: \.isLowercase) &&
      string.contains(where: \.isUppercase) &&
      string.contains(where: \.isNumber) &&
      string.contains(where: { !$0.isLetter && !$0.isNumber })
  }

  private static func isEmailAddress(_ string: String) -> Bool {
    let parts = string.split(separator: "@")
    return parts.count == 2 && parts[1].contains(".")
  }
}

// How long unpinned history items are kept before they are removed automatically.
nonisolated enum HistoryRetention: String, CaseIterable, Identifiable, CustomStringConvertible,
  Defaults.Serializable {
  case forever
  case hour
  case day
  case week
  case month

  var id: Self { self }

  var interval: TimeInterval? {
    switch self {
    case .forever: return nil
    case .hour: return 60 * 60
    case .day: return 24 * 60 * 60
    case .week: return 7 * 24 * 60 * 60
    case .month: return 30 * 24 * 60 * 60
    }
  }

  var description: String {
    switch self {
    case .forever:
      return NSLocalizedString("KeepForever", tableName: "StorageSettings", value: "Forever", comment: "")
    case .hour:
      return NSLocalizedString("KeepHour", tableName: "StorageSettings", value: "1 hour", comment: "")
    case .day:
      return NSLocalizedString("KeepDay", tableName: "StorageSettings", value: "1 day", comment: "")
    case .week:
      return NSLocalizedString("KeepWeek", tableName: "StorageSettings", value: "7 days", comment: "")
    case .month:
      return NSLocalizedString("KeepMonth", tableName: "StorageSettings", value: "30 days", comment: "")
    }
  }
}
