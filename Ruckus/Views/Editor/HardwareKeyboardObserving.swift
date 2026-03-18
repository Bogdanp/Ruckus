/// Detects whether an external hardware keyboard is connected and notifies
/// when the connection state changes.
@MainActor
protocol HardwareKeyboardObserving: AnyObject {
  /// Whether a hardware keyboard is currently connected.
  var isConnected: Bool { get }

  /// Begin observing hardware keyboard connect/disconnect events.
  /// The `onChange` closure is called on the main actor whenever the
  /// connection state changes; the argument is the new `isConnected` value.
  func startObserving(onChange: @escaping @Sendable (Bool) -> Void)

  /// Stop observing and release any notification registrations.
  func stopObserving()
}
