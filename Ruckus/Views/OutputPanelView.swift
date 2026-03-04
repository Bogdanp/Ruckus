import SwiftUI

struct OutputPanelView: View {
  let text: String

  var body: some View {
    Divider()
    ScrollView {
      Text(text)
        .font(.system(.caption, design: .monospaced))
        .frame(maxWidth: .infinity, alignment: .leading)
        .textSelection(.enabled)
        .padding(8)
    }
    .defaultScrollAnchor(.bottom)
    .frame(maxHeight: 200)
  }
}
