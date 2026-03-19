import Foundation
import Testing

@testable import Ruckus

@Suite
struct ScriptManifestTests {

  private func seedManifest(root: String, scripts: [String]) {
    ScriptManifest.update(rootPath: root, scripts: scripts)
  }

  // MARK: - update

  @Test
  func updateSetsRootPathAndScripts() {
    seedManifest(root: "/files", scripts: ["a.rkt", "sub/b.rkt"])
    #expect(ScriptManifest.rootPath() == "/files")
    #expect(ScriptManifest.scripts() == ["a.rkt", "sub/b.rkt"])
  }

  // MARK: - add

  @Test
  func addAppendsNewScript() {
    seedManifest(root: "/files", scripts: ["a.rkt"])
    ScriptManifest.add(scriptAtPath: "/files/b.rkt")
    #expect(ScriptManifest.scripts() == ["a.rkt", "b.rkt"])
  }

  @Test
  func addDoesNotDuplicateExistingScript() {
    seedManifest(root: "/files", scripts: ["a.rkt", "b.rkt"])
    ScriptManifest.add(scriptAtPath: "/files/a.rkt")
    #expect(ScriptManifest.scripts() == ["a.rkt", "b.rkt"])
  }

  @Test
  func addHandlesSubdirectoryPath() {
    seedManifest(root: "/files", scripts: [])
    ScriptManifest.add(scriptAtPath: "/files/Examples/hello.rkt")
    #expect(ScriptManifest.scripts() == ["Examples/hello.rkt"])
  }

  // MARK: - remove

  @Test
  func removeDeletesMatchingScript() {
    seedManifest(root: "/files", scripts: ["a.rkt", "b.rkt"])
    ScriptManifest.remove(scriptAtPath: "/files/a.rkt")
    #expect(ScriptManifest.scripts() == ["b.rkt"])
  }

  @Test
  func removeNoOpForMissingScript() {
    seedManifest(root: "/files", scripts: ["a.rkt"])
    ScriptManifest.remove(scriptAtPath: "/files/b.rkt")
    #expect(ScriptManifest.scripts() == ["a.rkt"])
  }

  // MARK: - removeAll(underDirectoryAtPath:)

  @Test
  func removeAllUnderDirectoryRemovesMatchingScripts() {
    seedManifest(root: "/files", scripts: ["a.rkt", "Examples/b.rkt", "Examples/c.rkt"])
    ScriptManifest.removeAll(underDirectoryAtPath: "/files/Examples")
    #expect(ScriptManifest.scripts() == ["a.rkt"])
  }

  @Test
  func removeAllUnderDirectoryDoesNotMatchPartialNames() {
    seedManifest(root: "/files", scripts: ["Examples2/a.rkt"])
    ScriptManifest.removeAll(underDirectoryAtPath: "/files/Examples")
    #expect(ScriptManifest.scripts() == ["Examples2/a.rkt"])
  }
}
