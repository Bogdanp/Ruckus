import SwiftUI

struct ContentView: View {
  var body: some View {
    VStack {
      Image(systemName: "globe")
        .imageScale(.large)
        .foregroundStyle(.tint)
      Text("Hello, world!")
    }
    .padding()
    .task {
      let res = try? await Backend.shared.ping()
      print("res=\(res)")
    }
  }
}

#Preview {
  ContentView()
}
