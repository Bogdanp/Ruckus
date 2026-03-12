import UIKit

extension CALayer {
  /// Light shadow for small elevated elements like snippet buttons.
  func applySoftShadow() {
    shadowColor = UIColor.black.cgColor
    shadowOpacity = 0.15
    shadowOffset = CGSize(width: 0, height: 1)
    shadowRadius = 0.5
  }

  /// Deeper shadow for floating panels like the completion popover.
  func applyPanelShadow() {
    shadowColor = UIColor.black.cgColor
    shadowOpacity = 0.2
    shadowOffset = CGSize(width: 0, height: 2)
    shadowRadius = 4
  }
}
