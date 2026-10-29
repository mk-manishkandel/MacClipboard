import AppKit.NSPasteboard
import Foundation
import SQLite3
import SwiftData

@MainActor
class Storage {
  static let shared = Storage()

  var container: ModelContainer
  var context: ModelContext { container.mainContext }
  var size: String {
    guard let size = try? url.resourceValues(forKeys: [.fileSizeKey]).allValues.first?.value as? Int64, size > 1 else {
      return ""
    }

    return ByteCountFormatter().string(fromByteCount: size)
  }

  private let url = URL.applicationSupportDirectory.appending(path: "MacClipboard/Storage.sqlite")

  init() {
    Self.vacuumIfNeeded(url)

    var config = ModelConfiguration(url: url)

    #if DEBUG
    if AppDelegate.isTesting {
      config = ModelConfiguration(isStoredInMemoryOnly: true)
    }
    #endif

    do {
      container = try ModelContainer(for: HistoryItem.self, configurations: config)
    } catch let error {
      fatalError("Cannot load database: \(error.localizedDescription).")
    }
  }

  func cleanupOrphanedContents() throws -> Int {
    let descriptor = FetchDescriptor<HistoryItemContent>(
      predicate: #Predicate { $0.item == nil }
    )
    let count = try context.fetchCount(descriptor)
    guard count > 0 else {
      return 0
    }

    try context.delete(
      model: HistoryItemContent.self,
      where: #Predicate { $0.item == nil }
    )
    context.processPendingChanges()
    try context.save()

    return count
  }

  func removeUnpersistableContents() throws -> Int {
    let contents = try context.fetch(FetchDescriptor<HistoryItemContent>())
    let unwanted = contents.filter {
      !Clipboard.shared.isPersistable(NSPasteboard.PasteboardType($0.type))
    }

    guard !unwanted.isEmpty else {
      return 0
    }

    unwanted.forEach(context.delete)
    context.processPendingChanges()
    try context.save()

    return unwanted.count
  }

  // Re-saves rows written before history encryption so they are encrypted on disk too.
  // SQLite keeps the old plaintext in free pages, so the file is vacuumed on next launch.
  func encryptPlaintextRows() throws -> Int {
    var count = 0

    for item in try context.fetch(FetchDescriptor<HistoryItem>())
    where !item.sealedTitle.isEmpty && !HistoryCipher.isSealed(item.sealedTitle) {
      item.title = item.sealedTitle
      count += 1
    }

    for content in try context.fetch(FetchDescriptor<HistoryItemContent>()) {
      guard let sealedValue = content.sealedValue, !HistoryCipher.isSealed(sealedValue) else { continue }
      content.value = sealedValue
      count += 1
    }

    guard count > 0 else {
      return 0
    }

    context.processPendingChanges()
    try context.save()
    UserDefaults.standard.set(true, forKey: Self.needsVacuumKey)

    return count
  }

  private static let needsVacuumKey = "historyNeedsVacuum"

  // Runs before SwiftData opens the store, so no other connection holds the database.
  private static func vacuumIfNeeded(_ url: URL) {
    guard UserDefaults.standard.bool(forKey: needsVacuumKey) else { return }

    var db: OpaquePointer?
    if sqlite3_open(url.path, &db) == SQLITE_OK {
      sqlite3_exec(db, "PRAGMA wal_checkpoint(TRUNCATE); VACUUM; PRAGMA wal_checkpoint(TRUNCATE);", nil, nil, nil)
    }
    sqlite3_close(db)
    UserDefaults.standard.removeObject(forKey: needsVacuumKey)
  }

  // Titles stored before the sanitization in `HistoryItem.generateTitle()` may
  // contain scalars that hang CoreText on macOS 26. Such an item makes MacClipboard
  // spin at 100% CPU on every launch without ever drawing its window, so the
  // store has to be healed before the history is first rendered.
  // See https://github.com/p0deje/Maccy/issues/1520.
  func sanitizeTitles() throws -> Int {
    let items = try context.fetch(FetchDescriptor<HistoryItem>())
    var count = 0

    for item in items where item.title.containsScalarsUnsafeForTitleLayout {
      item.title = item.title.removingScalarsUnsafeForTitleLayout()
      count += 1
    }

    guard count > 0 else {
      return 0
    }

    context.processPendingChanges()
    try context.save()

    return count
  }
}
