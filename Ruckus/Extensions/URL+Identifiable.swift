import Foundation

struct IdentifiableURL: Identifiable {
  let url: URL
  var id: String { url.absoluteString }
}
