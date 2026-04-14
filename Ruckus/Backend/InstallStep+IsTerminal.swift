extension InstallStep {
  var isTerminal: Bool {
    switch self {
    case .more: return false
    case .done, .failed: return true
    }
  }
}
