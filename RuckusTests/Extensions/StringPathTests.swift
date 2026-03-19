import Testing

@testable import Ruckus

@Suite
struct StringPathTests {

  // MARK: - appendingPathComponent

  @Test
  func appendingPathComponentJoinsWithSlash() {
    #expect("/files".appendingPathComponent("a.rkt") == "/files/a.rkt")
  }

  @Test
  func appendingPathComponentNormalizesTrailingSlash() {
    #expect("/files/".appendingPathComponent("a.rkt") == "/files/a.rkt")
  }

  @Test
  func appendingPathComponentHandlesEmptyBase() {
    #expect("".appendingPathComponent("a.rkt") == "a.rkt")
  }

  // MARK: - relativePath

  @Test
  func relativePathStripsRootPrefix() {
    #expect("/files/Examples/foo.rkt".relativePath(from: "/files") == "Examples/foo.rkt")
  }

  @Test
  func relativePathStripsTrailingSlash() {
    #expect("/files/Examples/foo.rkt".relativePath(from: "/files/") == "Examples/foo.rkt")
  }

  @Test
  func relativePathReturnsEmptyForExactMatch() {
    #expect("/files".relativePath(from: "/files") == "")
  }
}
