import SwiftUI

struct TabBar: View {
  var documents: [EditorDocument]
  var activeDocumentID: UUID?
  var onSelect: (EditorDocument) -> Void
  var onClose: (EditorDocument) -> Void
  var onReorder: ([UUID]) -> Void
  var onNew: () -> Void

  var body: some View {
    HStack(spacing: 0) {
      TabBarCollectionView(
        documents: documents,
        activeDocumentID: activeDocumentID,
        onSelect: onSelect,
        onClose: onClose,
        onReorder: onReorder
      )
      Button(action: onNew) {
        Image(systemName: "plus")
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(.secondary)
          .frame(width: 36, height: 36)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .padding(.trailing, 4)
    }
    .frame(height: 44)
    .background(.bar)
    .overlay(alignment: .bottom) {
      Divider()
    }
  }
}
