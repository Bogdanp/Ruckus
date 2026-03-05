import Foundation

enum SaveError: LocalizedError {
  case invalidFilename

  var errorDescription: String? {
    switch self {
    case .invalidFilename:
      return "Filename contains invalid characters"
    }
  }
}
