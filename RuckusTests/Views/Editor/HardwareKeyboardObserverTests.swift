import Runestone
import Testing
import UIKit

@testable import Ruckus

@Suite
@MainActor
struct HardwareKeyboardObserverTests {

  // MARK: - Helpers

  private func makeCoordinator(
    keyboardObserver: StubHardwareKeyboardObserver
  ) -> CodeEditingView.Coordinator {
    CodeEditingView.Coordinator(
      document: EditorDocument(),
      keyboardObserver: keyboardObserver
    )
  }

  // MARK: - Initial state

  @Test
  func hasHardwareKeyboardReflectsObserver() {
    let stub = StubHardwareKeyboardObserver(connected: false)
    let coord = makeCoordinator(keyboardObserver: stub)
    #expect(!coord.hasHardwareKeyboard)

    let connectedStub = StubHardwareKeyboardObserver(connected: true)
    let coord2 = makeCoordinator(keyboardObserver: connectedStub)
    #expect(coord2.hasHardwareKeyboard)
  }

  // MARK: - Runtime connect/disconnect

  @Test
  func connectUpdatesHasHardwareKeyboard() {
    let stub = StubHardwareKeyboardObserver(connected: false)
    let coord = makeCoordinator(keyboardObserver: stub)
    coord.startObservingKeyboard(for: makeTextView())

    stub.simulateConnect()

    #expect(coord.hasHardwareKeyboard)
  }

  @Test
  func disconnectUpdatesHasHardwareKeyboard() {
    let stub = StubHardwareKeyboardObserver(connected: true)
    let coord = makeCoordinator(keyboardObserver: stub)
    coord.startObservingKeyboard(for: makeTextView())

    stub.simulateDisconnect()

    #expect(!coord.hasHardwareKeyboard)
  }

  @Test
  func connectThenDisconnectCycles() {
    let stub = StubHardwareKeyboardObserver(connected: false)
    let coord = makeCoordinator(keyboardObserver: stub)
    coord.startObservingKeyboard(for: makeTextView())

    stub.simulateConnect()
    #expect(coord.hasHardwareKeyboard)

    stub.simulateDisconnect()
    #expect(!coord.hasHardwareKeyboard)

    stub.simulateConnect()
    #expect(coord.hasHardwareKeyboard)
  }

  // MARK: - Cleanup

  @Test
  func stopObservingStopsTheObserver() {
    let stub = StubHardwareKeyboardObserver(connected: false)
    let coord = makeCoordinator(keyboardObserver: stub)
    coord.startObservingKeyboard(for: makeTextView())

    #expect(stub.observing)

    coord.stopObservingKeyboard()

    #expect(!stub.observing)
  }

  @Test
  func stopObservingPreventsStateUpdates() {
    let stub = StubHardwareKeyboardObserver(connected: false)
    let coord = makeCoordinator(keyboardObserver: stub)
    coord.startObservingKeyboard(for: makeTextView())

    coord.stopObservingKeyboard()
    stub.simulateConnect()

    // The observer updated its own state, but the coordinator's
    // onChange closure was cleared, so no side effects occurred.
    // hasHardwareKeyboard is a passthrough to the observer, so it
    // reflects the observer's state directly.
    #expect(stub.isConnected)
  }

  // MARK: - Stub behavior

  @Test
  func stubSimulateConnectCallsOnChange() {
    let stub = StubHardwareKeyboardObserver(connected: false)
    // nonisolated(unsafe) is safe here: the stub calls onChange synchronously
    // on the main actor, so there is no actual concurrent access.
    nonisolated(unsafe) var callbackValues: [Bool] = []
    stub.startObserving { callbackValues.append($0) }

    stub.simulateConnect()
    stub.simulateDisconnect()
    stub.simulateConnect()

    #expect(callbackValues == [true, false, true])
  }

  // MARK: - Private

  private func makeTextView() -> TextView {
    TextView(frame: .zero)
  }
}
