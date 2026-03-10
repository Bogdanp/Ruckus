import SwiftUI

struct SheetNavigation<Content: View>: View {
  let title: String
  var titleDisplayMode: NavigationBarItem.TitleDisplayMode = .inline
  @ViewBuilder var content: () -> Content
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      content()
        .presentationDragIndicator(.visible)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(titleDisplayMode)
        .toolbar {
          ToolbarItem(placement: .confirmationAction) {
            Button("Done") { dismiss() }
          }
        }
    }
  }
}
