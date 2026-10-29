import Foundation
import Testing
@testable import MacClipboard

struct TextTransformTests {
  @Test("Case changes")
  func caseChanges() {
    #expect(TextTransform.uppercase.apply(to: "Hello world") == "HELLO WORLD")
    #expect(TextTransform.lowercase.apply(to: "Hello World") == "hello world")
    #expect(TextTransform.titleCase.apply(to: "hello big world") == "Hello Big World")
  }

  @Test("Whitespace and lines")
  func whitespace() {
    #expect(TextTransform.trimWhitespace.apply(to: "  a   b \n\t c  d  \n") == "a b\nc d")
    #expect(TextTransform.joinLines.apply(to: "first line\n  second line\n\nthird") == "first line second line third")
  }

  @Test("Pretty JSON")
  func prettyJSON() {
    #expect(TextTransform.prettyJSON.apply(to: #"{"b":1,"a":[1,2]}"#) == "{\n  \"a\" : [\n    1,\n    2\n  ],\n  \"b\" : 1\n}")
    #expect(TextTransform.prettyJSON.apply(to: "not json") == nil)
    #expect(TextTransform.prettyJSON.apply(to: "42") == nil)
  }

  @Test("Clean link removes tracking only")
  func cleanLink() {
    #expect(TextTransform.cleanLink.apply(to: "https://example.com/page?id=7&utm_source=x&fbclid=abc")
      == "https://example.com/page?id=7")
    #expect(TextTransform.cleanLink.apply(to: "https://youtu.be/abc?si=XYZ") == "https://youtu.be/abc")
    #expect(TextTransform.cleanLink.apply(to: "https://example.com/page?id=7") == nil)
    #expect(TextTransform.cleanLink.apply(to: "not a link?utm_source=x") == nil)
  }

  @Test("Options that would not change the text are hidden")
  func noOps() {
    #expect(TextTransform.uppercase.apply(to: "ABC") == nil)
    #expect(TextTransform.joinLines.apply(to: "one line") == nil)
  }
}
