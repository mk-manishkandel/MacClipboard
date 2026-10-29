import Defaults
import SwiftUI

struct HeaderView: View {
  @State private var appState = AppState.shared

  let controller: SlideoutController
  @FocusState.Binding var searchFocused: Bool

  var previewPlacement: SlideoutPlacement {
    return controller.placement
  }

  var body: some View {
    VStack(spacing: 6) {
      HStack(alignment: .top, spacing: 0) {
        HStack(alignment: .center, spacing: 0) {
          ListHeaderView(
            searchFocused: $searchFocused,
            searchQuery: $appState.history.searchQuery
          )
          .padding(.horizontal, Popup.horizontalPadding)

          ToolbarButton {
            controller.togglePreview()
          } label: {
            Image(
              systemName: previewPlacement == .right
                ? "sidebar.left" : "sidebar.right"
            )
          }
          .shortcutKeyHelp(
            name: .togglePreview,
            key: controller.state.isOpen ? "ClosePreview" : "OpenPreview",
            tableName: "PreviewItemView",
            replacementKey: "previewKey"
          )
          .padding(.trailing, Popup.horizontalPadding)
        }
        .opacity(appState.searchVisible ? 1 : 0)
        .accessibilityHidden(!appState.searchVisible)
        .layoutPriority(1)
      }

      FilterTabs(selection: $appState.history.typeFilter)
        .padding(.horizontal, Popup.horizontalPadding)
        .padding(.vertical, 4)
      .opacity(appState.searchVisible ? 1 : 0)
      .accessibilityHidden(!appState.searchVisible)
    }
    .padding(.top, Popup.verticalPadding)
    .padding(.horizontal, 10)
    .animation(.default.speed(3), value: appState.navigator.leadSelection)
    .background(.clear)
    .frame(maxHeight: !appState.searchVisible ? 0 : nil, alignment: .top)
    .readHeight(appState, into: \.popup.headerHeight)
  }
}

// Tall filter tabs that share the popup's width, so they never make the popup wider.
private struct FilterTabs: View {
  @Binding var selection: HistoryFilter

  var body: some View {
    HStack(spacing: 2) {
      ForEach(HistoryFilter.allCases) { filter in
        let isSelected = filter == selection
        Button {
          selection = filter
        } label: {
          Text(filter.title)
            .font(.callout.weight(isSelected ? .medium : .regular))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .frame(maxWidth: .infinity, minHeight: 24)
            .contentShape(Rectangle())
            .background(
              RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color(nsColor: .controlBackgroundColor) : .clear)
                .shadow(color: .black.opacity(isSelected ? 0.15 : 0), radius: 1, y: 0.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
      }
    }
    .padding(2)
    .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
  }
}
