import Foundation

// "Paste as" options in a history item's context menu.
nonisolated enum TextTransform: CaseIterable, Identifiable {
  case uppercase
  case lowercase
  case titleCase
  case trimWhitespace
  case joinLines
  case prettyJSON
  case cleanLink

  var id: Self { self }

  var title: String {
    switch self {
    case .uppercase: NSLocalizedString("transform_uppercase", value: "UPPERCASE", comment: "")
    case .lowercase: NSLocalizedString("transform_lowercase", value: "lowercase", comment: "")
    case .titleCase: NSLocalizedString("transform_title_case", value: "Title Case", comment: "")
    case .trimWhitespace: NSLocalizedString("transform_trim", value: "Trim spaces", comment: "")
    case .joinLines: NSLocalizedString("transform_join_lines", value: "Join lines", comment: "")
    case .prettyJSON: NSLocalizedString("transform_pretty_json", value: "Pretty JSON", comment: "")
    case .cleanLink: NSLocalizedString("transform_clean_link", value: "Clean link", comment: "")
    }
  }

  // Query parameters that only track where a link was shared from.
  private static let trackingParameters: Set<String> = [
    "fbclid", "gclid", "dclid", "gbraid", "wbraid", "msclkid", "yclid", "igshid", "si",
    "mc_cid", "mc_eid", "_hsenc", "_hsmi", "mkt_tok", "ref_src", "ref_url", "spm"
  ]

  // Returns nil when the transform does not apply or would not change the text.
  func apply(to text: String) -> String? {
    let result: String?
    switch self {
    case .uppercase:
      result = text.uppercased()
    case .lowercase:
      result = text.lowercased()
    case .titleCase:
      result = text.capitalized
    case .trimWhitespace:
      result = text
        .components(separatedBy: .newlines)
        .map { $0.replacingOccurrences(of: "[ \\t]+", with: " ", options: .regularExpression)
          .trimmingCharacters(in: .whitespaces) }
        .joined(separator: "\n")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    case .joinLines:
      result = text
        .components(separatedBy: .newlines)
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty }
        .joined(separator: " ")
    case .prettyJSON:
      result = Self.prettyJSON(text)
    case .cleanLink:
      result = Self.cleanLink(text)
    }

    guard let result, !result.isEmpty, result != text else { return nil }
    return result
  }

  private static func prettyJSON(_ text: String) -> String? {
    guard let data = text.trimmingCharacters(in: .whitespacesAndNewlines).data(using: .utf8),
          let object = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]),
          object is [Any] || object is [String: Any],
          let pretty = try? JSONSerialization.data(
            withJSONObject: object, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
          ) else {
      return nil
    }
    return String(decoding: pretty, as: UTF8.self)
  }

  private static func cleanLink(_ text: String) -> String? {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.contains(where: \.isWhitespace),
          var components = URLComponents(string: trimmed),
          ["http", "https"].contains(components.scheme?.lowercased()),
          let queryItems = components.queryItems else {
      return nil
    }

    let kept = queryItems.filter { item in
      let name = item.name.lowercased()
      return !name.hasPrefix("utm_") && !trackingParameters.contains(name)
    }
    components.queryItems = kept.isEmpty ? nil : kept
    return components.string
  }
}
