import SwiftUI

extension FocusedValues {
  @Entry var saveAction: SaveActionHandler?
  @Entry var openFile: (@MainActor @Sendable () -> Void)?
  @Entry var viewOutput: (@MainActor @Sendable () -> Void)?
  @Entry var findAction: (@MainActor @Sendable () -> Void)?
  @Entry var findAndReplaceAction: (@MainActor @Sendable () -> Void)?
  @Entry var formatAction: (@MainActor @Sendable () -> Void)?
  @Entry var shareAction: (@MainActor @Sendable () -> Void)?
  @Entry var closeAction: (@MainActor @Sendable () -> Void)?
}

struct FocusedCommandValues: ViewModifier {
  let saveAction: SaveActionHandler
  let openFile: @MainActor @Sendable () -> Void
  let viewOutput: @MainActor @Sendable () -> Void
  let findAction: @MainActor @Sendable () -> Void
  let findAndReplaceAction: @MainActor @Sendable () -> Void
  let formatAction: @MainActor @Sendable () -> Void
  let shareAction: @MainActor @Sendable () -> Void
  let closeAction: @MainActor @Sendable () -> Void

  func body(content: Content) -> some View {
    content
      .focusedSceneValue(\.saveAction, saveAction)
      .focusedSceneValue(\.openFile, openFile)
      .focusedSceneValue(\.viewOutput, viewOutput)
      .focusedSceneValue(\.findAction, findAction)
      .focusedSceneValue(\.findAndReplaceAction, findAndReplaceAction)
      .focusedSceneValue(\.formatAction, formatAction)
      .focusedSceneValue(\.shareAction, shareAction)
      .focusedSceneValue(\.closeAction, closeAction)
  }
}
