enum ExecutionResult: Sendable {
  case completed
  case stopped
  case failed(any Error)
}
