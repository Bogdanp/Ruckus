extension InstallStep {
  var output: InstallOutput {
    switch self {
    case .done(let value), .failed(let value, _), .more(let value): return value
    }
  }
}
