import SwiftUI

extension FocusedValues {
  @Entry var saveAction: SaveActionHandler?
  @Entry var openFile: (@MainActor @Sendable () -> Void)?
  @Entry var viewOutput: (@MainActor @Sendable () -> Void)?
}
