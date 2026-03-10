extension ExecutionStep {
  var isDone: Bool {
    if case .done = self { return true }
    return false
  }
}
