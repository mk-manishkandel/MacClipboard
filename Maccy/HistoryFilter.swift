import Foundation

// The filter tabs under the search field.
enum HistoryFilter: String, CaseIterable, Identifiable {
  case all
  case text
  case links
  case images
  case files
  case snippets

  var id: Self { self }

  var title: String {
    switch self {
    case .all: NSLocalizedString("filter_all", value: "All", comment: "")
    case .text: NSLocalizedString("filter_text", value: "Text", comment: "")
    case .links: NSLocalizedString("filter_links", value: "Links", comment: "")
    case .images: NSLocalizedString("filter_images", value: "Images", comment: "")
    case .files: NSLocalizedString("filter_files", value: "Files", comment: "")
    case .snippets: NSLocalizedString("filter_snippets", value: "Snippets", comment: "")
    }
  }

  // Snippets are pinned items.
  func includes(_ item: HistoryItemDecorator) -> Bool {
    switch self {
    case .all: true
    case .text: !item.item.isImage && !item.item.isFile && !item.item.isLink
    case .links: item.item.isLink
    case .images: item.item.isImage
    case .files: item.item.isFile
    case .snippets: item.isPinned
    }
  }
}
