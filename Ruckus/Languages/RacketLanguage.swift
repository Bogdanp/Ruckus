import Foundation
import Runestone
import TreeSitterRacket

extension TreeSitterLanguage {
  nonisolated(unsafe) static let racket: TreeSitterLanguage = {
    let highlightsURL = Bundle.main.url(forResource: "highlights", withExtension: "scm")!
    let query = TreeSitterLanguage.Query(contentsOf: highlightsURL)
    return TreeSitterLanguage(tree_sitter_racket(), highlightsQuery: query)
  }()
}
