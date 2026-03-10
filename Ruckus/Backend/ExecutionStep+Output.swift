extension ExecutionStep {
  var output: ExecutionOutput {
    switch self {
    case .done(let value), .more(let value): return value
    }
  }
}
