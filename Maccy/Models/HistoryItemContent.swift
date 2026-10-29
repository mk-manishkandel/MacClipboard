import Foundation
import SwiftData

@Model
class HistoryItemContent {
  var type: String = ""

  // Encrypted on disk by HistoryCipher. Read and write plaintext through `value`.
  @Attribute(originalName: "value")
  var sealedValue: Data?

  @Transient private var openedValue: Data?

  var value: Data? {
    get {
      if openedValue == nil, sealedValue != nil {
        openedValue = HistoryCipher.open(sealedValue)
      }
      return openedValue
    }
    set {
      openedValue = newValue
      sealedValue = HistoryCipher.seal(newValue)
    }
  }

  @Relationship
  var item: HistoryItem?

  init(type: String, value: Data? = nil) {
    self.type = type
    self.value = value
  }
}
