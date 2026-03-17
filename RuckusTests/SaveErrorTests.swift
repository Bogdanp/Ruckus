import Testing

@testable import Ruckus

@Suite
struct SaveErrorTests {

  @Test
  func invalidFilenameHasDescription() {
    let error = SaveError.invalidFilename
    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("invalid"))
  }

  @Test
  func invalidFilenameIsLocalizedError() {
    let error: any Error = SaveError.invalidFilename
    #expect(error.localizedDescription.contains("invalid"))
  }
}
