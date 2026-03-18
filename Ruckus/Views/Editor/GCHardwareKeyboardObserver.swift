import GameController

/// Production implementation of ``HardwareKeyboardObserving`` backed by `GCKeyboard`.
@MainActor
final class GCHardwareKeyboardObserver: HardwareKeyboardObserving {
  private(set) var isConnected: Bool
  private var observers: [Any] = []

  init() {
    isConnected = GCKeyboard.coalesced != nil
  }

  func startObserving(onChange: @escaping @Sendable (Bool) -> Void) {
    stopObserving()
    let center = NotificationCenter.default
    observers = [
      center.addObserver(
        forName: .GCKeyboardDidConnect, object: nil, queue: .main
      ) { [weak self] _ in
        MainActor.assumeIsolated {
          guard let self else { return }
          self.isConnected = true
          onChange(true)
        }
      },
      center.addObserver(
        forName: .GCKeyboardDidDisconnect, object: nil, queue: .main
      ) { [weak self] _ in
        MainActor.assumeIsolated {
          guard let self else { return }
          self.isConnected = false
          onChange(false)
        }
      }
    ]
  }

  func stopObserving() {
    for observer in observers {
      NotificationCenter.default.removeObserver(observer)
    }
    observers = []
  }
}
