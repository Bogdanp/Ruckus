@testable import Ruckus

/// A stub that lets tests control the hardware keyboard state.
@MainActor
final class StubHardwareKeyboardObserver: HardwareKeyboardObserving {
  private(set) var isConnected: Bool
  private var onChange: ((Bool) -> Void)?
  private(set) var observing = false

  init(connected: Bool = false) {
    isConnected = connected
  }

  func startObserving(onChange: @escaping @Sendable (Bool) -> Void) {
    self.onChange = onChange
    observing = true
  }

  func stopObserving() {
    onChange = nil
    observing = false
  }

  /// Simulate connecting a hardware keyboard.
  func simulateConnect() {
    isConnected = true
    onChange?(true)
  }

  /// Simulate disconnecting a hardware keyboard.
  func simulateDisconnect() {
    isConnected = false
    onChange?(false)
  }
}
