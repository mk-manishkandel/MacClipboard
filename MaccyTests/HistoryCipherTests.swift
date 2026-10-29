import Foundation
import Testing
@testable import MacClipboard

struct HistoryCipherTests {
  @Test("Data round-trips and is not stored as plaintext")
  func dataRoundTrip() throws {
    let plaintext = Data("secret clipboard text".utf8)
    let sealed = try #require(HistoryCipher.seal(plaintext))

    #expect(HistoryCipher.isSealed(sealed))
    #expect(sealed.range(of: plaintext) == nil)
    #expect(HistoryCipher.open(sealed) == plaintext)
  }

  @Test("Strings round-trip and are not stored as plaintext")
  func stringRoundTrip() {
    let sealed = HistoryCipher.seal("secret title ✨")

    #expect(HistoryCipher.isSealed(sealed))
    #expect(!sealed.contains("secret"))
    #expect(HistoryCipher.open(sealed) == "secret title ✨")
  }

  @Test("Sealing the same value twice gives different output")
  func uniqueNonce() {
    #expect(HistoryCipher.seal("same") != HistoryCipher.seal("same"))
  }

  @Test("Values written before encryption are returned as-is")
  func legacyPlaintext() {
    #expect(HistoryCipher.open("plain old title") == "plain old title")
    #expect(HistoryCipher.open(Data("plain".utf8)) == Data("plain".utf8))
  }

  @Test("Empty and missing values stay empty")
  func emptyValues() {
    #expect(HistoryCipher.seal("") == "")
    #expect(HistoryCipher.seal(nil as Data?) == nil)
    #expect(HistoryCipher.open(nil as Data?) == nil)
  }

  @Test("Tampered data does not decrypt")
  func tampered() throws {
    var sealed = try #require(HistoryCipher.seal(Data("secret".utf8)))
    sealed[sealed.count - 1] ^= 0xFF

    #expect(HistoryCipher.open(sealed) == nil)
  }
}
