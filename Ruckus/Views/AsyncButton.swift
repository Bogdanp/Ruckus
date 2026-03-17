import SwiftUI

enum AsyncButtonOption: CaseIterable, Hashable {
  case cancelsOnDisappear
  case disabledWhileRunning
  case showsProgressView
  case showsSuccessIcon

  static let all = Set(Self.allCases)
  static let allButCancel = Set(Self.allCases).subtracting([.cancelsOnDisappear])
}

struct AsyncButton<Label>: View where Label: View {
  var role: ButtonRole?
  var options = AsyncButtonOption.all
  let action: () async -> Void
  @ViewBuilder let label: () -> Label

  var trigger: Binding<Bool>?

  @State private var loading = false
  @State private var success = false
  @State private var running = false
  @State private var task: Task<Void, Never>?
  @State private var successTask: Task<Void, any Error>?

  var body: some View {
    Button(role: role) {
      fire()
    } label: {
      ZStack {
        let isShowingProgress = options.contains(.showsProgressView) && loading
        let isShowingSuccess = options.contains(.showsSuccessIcon) && success
        label()
          .opacity((isShowingProgress || isShowingSuccess) ? 0 : 1)
        if isShowingProgress {
          ProgressView()
        } else if isShowingSuccess {
          SwiftUI.Label("Success", systemImage: "checkmark.circle.fill")
            .labelStyle(.iconOnly)
        }
      }
    }
    .disabled(options.contains(.disabledWhileRunning) && running)
    .onDisappear {
      guard options.contains(.cancelsOnDisappear) else { return }
      task?.cancel()
      task = nil
      successTask?.cancel()
      successTask = nil
    }
    .onChange(of: trigger?.wrappedValue) {
      if trigger?.wrappedValue == true {
        fire()
        trigger?.wrappedValue = false
      }
    }
  }

  private func fire() {
    task?.cancel()
    task = Task {
      running = true
      var progressTask: Task<Void, any Error>?
      if options.contains(.showsProgressView) {
        progressTask = Task {
          try await Task.sleep(for: .milliseconds(250))
          withAnimation {
            loading = true
          }
        }
      }
      await action()
      guard !Task.isCancelled else { return }
      progressTask?.cancel()
      withAnimation {
        loading = false
        running = false
      }
      if options.contains(.showsSuccessIcon) {
        successTask?.cancel()
        successTask = Task {
          withAnimation {
            success = true
          }
          try await Task.sleep(for: .seconds(1))
          withAnimation {
            success = false
          }
        }
      }
    }
  }
}

extension AsyncButton where Label == Text {
  init(_ label: LocalizedStringKey, action: @escaping () async -> Void) {
    self.init(action: action, label: {
      Text(label)
    })
  }
}

extension AsyncButton where Label == Image {
  init(systemImageName name: String, action: @escaping () async -> Void) {
    self.init(action: action, label: {
      Image(systemName: name)
    })
  }
}
