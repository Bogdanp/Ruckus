import SwiftUI

struct OutputSheetView: View {
  let text: NSAttributedString
  let version: UInt64
  @State private var showShareSheet = false

  var body: some View {
    SheetNavigation(title: "Output") {
      OutputTextView(text: text, version: version)
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            Button {
              showShareSheet = true
            } label: {
              Image(systemName: "square.and.arrow.up")
            }
          }
        }
        .sheet(isPresented: $showShareSheet) {
          ActivitySheet(items: [text.string])
        }
    }
  }
}
