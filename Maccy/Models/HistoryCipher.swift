import CryptoKit
import Foundation
import Logging
import Security

// Encrypts copied contents and titles with AES-GCM before they reach the history database,
// so the file on disk is unreadable without the key kept in the user's login Keychain.
// Values written before encryption existed have no prefix and are returned as-is.
nonisolated enum HistoryCipher {
  private static let dataPrefix = Data("MCE1".utf8)
  private static let stringPrefix = "mce1:"
  private static let keychainService = "com.mkmanishkandel.MacClipboard.history-key"
  private static let keychainAccount = "history"
  private static let logger = Logger(label: "com.mkmanishkandel.MacClipboard")

  static let key: SymmetricKey = loadOrCreateKey()

  static func seal(_ data: Data?) -> Data? {
    guard let data else { return nil }

    do {
      guard let combined = try AES.GCM.seal(data, using: key).combined else { return nil }
      return dataPrefix + combined
    } catch {
      // Never fall back to storing plaintext.
      logger.error("Failed to encrypt history content: \(error.localizedDescription)")
      return nil
    }
  }

  static func open(_ data: Data?) -> Data? {
    guard let data, isSealed(data) else { return data }

    do {
      return try AES.GCM.open(AES.GCM.SealedBox(combined: data.dropFirst(dataPrefix.count)), using: key)
    } catch {
      logger.error("Failed to decrypt history content: \(error.localizedDescription)")
      return nil
    }
  }

  static func seal(_ string: String) -> String {
    guard !string.isEmpty, let sealed = seal(Data(string.utf8)) else { return "" }

    return stringPrefix + sealed.dropFirst(dataPrefix.count).base64EncodedString()
  }

  static func open(_ string: String) -> String {
    guard isSealed(string) else { return string }

    guard let combined = Data(base64Encoded: String(string.dropFirst(stringPrefix.count))),
          let data = open(dataPrefix + combined) else {
      return ""
    }
    return String(decoding: data, as: UTF8.self)
  }

  static func isSealed(_ data: Data) -> Bool { data.starts(with: dataPrefix) }
  static func isSealed(_ string: String) -> Bool { string.hasPrefix(stringPrefix) }

  private static func loadOrCreateKey() -> SymmetricKey {
    #if DEBUG
    if AppDelegate.isTesting {
      return SymmetricKey(size: .bits256)
    }
    #endif

    let query: [CFString: Any] = [
      kSecClass: kSecClassGenericPassword,
      kSecAttrService: keychainService,
      kSecAttrAccount: keychainAccount,
      kSecReturnData: true
    ]
    var result: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    if status == errSecSuccess, let data = result as? Data, data.count == 32 {
      return SymmetricKey(data: data)
    }

    if status == errSecItemNotFound {
      let key = SymmetricKey(size: .bits256)
      let attributes: [CFString: Any] = [
        kSecClass: kSecClassGenericPassword,
        kSecAttrService: keychainService,
        kSecAttrAccount: keychainAccount,
        kSecAttrLabel: "MacClipboard history encryption key",
        kSecValueData: key.withUnsafeBytes { Data($0) }
      ]
      let addStatus = SecItemAdd(attributes as CFDictionary, nil)
      if addStatus == errSecSuccess {
        return key
      }
      logger.error("Failed to save history key to Keychain: \(addStatus)")
    } else {
      logger.error("Failed to read history key from Keychain: \(status)")
    }

    // Keychain is unavailable: keep history encrypted with a key that lives only for this session.
    return SymmetricKey(size: .bits256)
  }
}
