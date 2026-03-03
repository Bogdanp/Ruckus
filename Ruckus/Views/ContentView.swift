import SwiftUI

struct ContentView: View {
  @State private var code = """
    #lang racket/base

    (displayln 42)
    """
  @State private var output = ""
  @State private var isEvaluating = false

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        CodeEditingView(text: $code)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        if !output.isEmpty {
          ScrollView {
            Text(output)
              .font(.system(.body, design: .monospaced))
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding()
          }
          .frame(maxHeight: 200)
          .background(.bar)
        }
      }
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button {
            Task {
              await evaluate()
            }
          } label: {
            Image(systemName: "play.fill")
          }
          .disabled(isEvaluating)
        }
      }
    }
  }

  private func evaluate() async {
    isEvaluating = true
    defer { isEvaluating = false }
    do {
      let result = try await Backend.shared.evaluate(code: code)
      let stdout = String(decoding: result.stdout, as: UTF8.self)
      let stderr = String(decoding: result.stderr, as: UTF8.self)
      output = stdout + stderr
    } catch {
      output = error.localizedDescription
    }
  }
}

#Preview {
  ContentView()
}
