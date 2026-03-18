import SwiftUI

struct TabBarItemContent: View {
  let title: String
  let isDirty: Bool
  let isActive: Bool
  let onClose: () -> Void

  var body: some View {
    HStack(spacing: 5) {
      Text(title)
        .font(.system(.subheadline, design: .rounded))
        .fontWeight(isActive ? .medium : .regular)
        .foregroundColor(isActive ? Color(.label) : Color(.secondaryLabel))
        .lineLimit(1)
      if isDirty {
        Circle()
          .fill(isActive ? Color.accentColor : Color(.secondaryLabel))
          .frame(width: 5, height: 5)
          .accessibilityLabel("Unsaved changes")
      }
      if isActive {
        Button(action: onClose) {
          Image(systemName: "xmark")
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(Color(.tertiaryLabel))
            .frame(width: 16, height: 16)
            .background(Color(.quaternarySystemFill), in: .circle)
        }
        .buttonStyle(.plain)
        // Negative inset expands the tap target beyond the 16x16 visual frame.
        .contentShape(Circle().inset(by: -8))
        .accessibilityLabel("Close tab")
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
}
