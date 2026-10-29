import Foundation
import Testing
@testable import MacClipboard

struct SensitiveContentTests {
  // Fake keys are split in two so secret scanners do not flag this file.
  static let fakeKeys: [String] = [
    "AKIA" + "IOSFODNN7EXAMPLE",
    "ghp_" + "aBcDeFgHiJkLmNoPqRsTuVwXyZ0123456789",
    "xoxb-" + "1234567890-abcdefghij",
    "sk_live_" + "51HxYzAbCdEfGhIjKlMnOp",
    "sk-ant-" + "api03-abcdefghijklmnopqrstuvwxyz",
    "sk-proj-" + "abcdefghijklmnopqrstuvwxyz012345",
    "AIza" + "SyA1234567890abcdefghijklmnopqrstuv",
  ]

  @Test("Detects secrets", arguments: fakeKeys + [
    "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N",
    "-----BEGIN OPENSSH PRIVATE KEY-----\nb3BlbnNzaC1rZXktdjEAAAAA\n-----END OPENSSH PRIVATE KEY-----",
    "export API_KEY=sk-ant-api03-abcdefghijklmnopqrstuvwxyz",
    "4111 1111 1111 1111",
    "4111-1111-1111-1111",
    "5500005555555559",
    "482913",
    "482 913",
    "12345678",
    "Tr0ub4dor&3xyz",
    "abcdEf-ghijk1-lmnoPq",
    "  P@ssw0rd!  "
  ])
  func detectsSecrets(_ string: String) {
    #expect(SensitiveContent.isSensitive(string))
  }

  @Test("Leaves everyday copies alone", arguments: [
    "Hello world",
    "Meeting at 5pm in Room B",
    "https://github.com/mk-manishkandel/MacClipboard?tab=Readme1",
    "someone@Example1.com",
    "/Users/Me/Documents/Report2026.pdf",
    "4111 1111 1111 1112",
    "2026",
    "12345",
    "123456789",
    "+1 (555) 010-9999",
    "password",
    "Password1",
    "MacClipboard",
    "let value = items.first(where: { $0.isVisible })"
  ])
  func leavesEverydayCopiesAlone(_ string: String) {
    #expect(!SensitiveContent.isSensitive(string))
  }

  @Test("Missing and very long text is not scanned")
  func limits() {
    #expect(!SensitiveContent.isSensitive(nil))
    #expect(!SensitiveContent.isSensitive(String(repeating: "Ab1!", count: 10_000)))
  }

  @Test("Retention intervals")
  func retention() {
    #expect(HistoryRetention.forever.interval == nil)
    #expect(HistoryRetention.day.interval == 86_400)
    #expect(HistoryRetention.month.interval == 2_592_000)
  }
}
