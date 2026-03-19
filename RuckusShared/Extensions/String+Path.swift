import Foundation

extension String {
  func appendingPathComponent(_ component: String) -> String {
    (self as NSString).appendingPathComponent(component)
  }

  func relativePath(from root: String) -> String {
    String(dropFirst(root.count).drop(while: { $0 == "/" }))
  }
}
