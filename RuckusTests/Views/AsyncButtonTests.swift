import Semaphore
import SwiftUI
import Testing

@testable import Ruckus

@Suite
struct AsyncButtonTests {
  @MainActor
  @Test
  func taskIsCancelledOnDisappear() async throws {
    let started = AsyncSemaphore(value: 0)
    let cancelled = AsyncSemaphore(value: 0)

    let model = WrapperModel()
    let wrapper = AsyncButtonWrapper(
      model: model,
      started: started,
      cancelled: cancelled
    )

    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
      Issue.record("No active window scene")
      return
    }
    let window = UIWindow(windowScene: scene)
    let host = UIHostingController(rootView: wrapper)
    window.rootViewController = host
    window.makeKeyAndVisible()
    host.view.layoutIfNeeded()
    await Task.yield()

    model.trigger = true
    await started.wait()

    model.showButton = false
    await cancelled.wait()
  }

  @Test
  func allContainsAllFourCases() {
    #expect(AsyncButtonOption.all == Set(AsyncButtonOption.allCases))
    #expect(AsyncButtonOption.all.count == 4)
    #expect(AsyncButtonOption.all.contains(.cancelsOnDisappear))
    #expect(AsyncButtonOption.all.contains(.disabledWhileRunning))
    #expect(AsyncButtonOption.all.contains(.showsProgressView))
    #expect(AsyncButtonOption.all.contains(.showsSuccessIcon))
  }

  @Test
  func allButCancelContainsAllExceptCancelsOnDisappear() {
    #expect(AsyncButtonOption.allButCancel.count == 3)
    #expect(!AsyncButtonOption.allButCancel.contains(.cancelsOnDisappear))
    #expect(AsyncButtonOption.allButCancel.contains(.disabledWhileRunning))
    #expect(AsyncButtonOption.allButCancel.contains(.showsProgressView))
    #expect(AsyncButtonOption.allButCancel.contains(.showsSuccessIcon))
  }

  @Test
  func allButCancelSubtractingShowsSuccessIcon() {
    let result = AsyncButtonOption.allButCancel.subtracting([.showsSuccessIcon])
    #expect(result.count == 2)
    #expect(result == Set<AsyncButtonOption>([.disabledWhileRunning, .showsProgressView]))
  }
}

@Observable
@MainActor
private final class WrapperModel {
  var showButton = true
  var trigger = false
}

private struct AsyncButtonWrapper: View {
  @State var model: WrapperModel
  let started: AsyncSemaphore
  let cancelled: AsyncSemaphore

  var body: some View {
    VStack {
      if model.showButton {
        AsyncButton(
          action: {
            started.signal()
            await withTaskCancellationHandler {
              for await _ in AsyncStream<Never>.makeStream().stream {
                break
              }
            } onCancel: {
              cancelled.signal()
            }
          },
          label: { Text("Test") },
          trigger: $model.trigger
        )
      }
    }
  }
}
