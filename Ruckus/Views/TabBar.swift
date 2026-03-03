import SwiftUI

struct TabBar: View {
  var documents: [EditorDocument]
  var activeDocumentID: UUID?
  var onSelect: (EditorDocument) -> Void
  var onClose: (EditorDocument) -> Void
  var onNew: () -> Void

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 6) {
        ForEach(documents) { doc in
          TabBarItem(
            title: doc.title,
            isDirty: doc.isDirty,
            isActive: doc.id == activeDocumentID,
            onSelect: { onSelect(doc) },
            onClose: { onClose(doc) }
          )
        }
        Button(action: onNew) {
          Image(systemName: "plus")
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.secondary)
            .frame(width: 28, height: 28)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 6)
    }
    .background(.bar)
    .overlay(alignment: .bottom) {
      Divider()
    }
  }
}

private struct TabBarItem: View {
  let title: String
  let isDirty: Bool
  let isActive: Bool
  let onSelect: () -> Void
  let onClose: () -> Void

  var body: some View {
    Button(action: onSelect) {
      HStack(spacing: 5) {
        Text(title)
          .font(.subheadline)
          .fontWeight(isActive ? .medium : .regular)
          .foregroundStyle(isActive ? .primary : .secondary)
          .lineLimit(1)
        if isDirty {
          Circle()
            .fill(isActive ? Color.accentColor : .secondary)
            .frame(width: 5, height: 5)
        }
        if isActive {
          Button(action: onClose) {
            Image(systemName: "xmark")
              .font(.system(size: 8, weight: .bold))
              .foregroundStyle(.tertiary)
              .frame(width: 16, height: 16)
              .background(.quaternary, in: .circle)
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.leading, 10)
      .padding(.trailing, isActive ? 6 : 10)
      .padding(.vertical, 6)
      .background {
        if isActive {
          Capsule()
            .fill(.thickMaterial)
            .shadow(color: .black.opacity(0.08), radius: 1, y: 1)
        }
      }
    }
    .buttonStyle(.plain)
  }
}
