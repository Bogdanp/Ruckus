import Testing
import UIKit

@testable import Ruckus

@Suite
@MainActor
struct EditorDocumentOutputTests {

  // MARK: - appendOutput color

  @Test
  func appendOutputWithStdoutSetsLabelColor() {
    let doc = EditorDocument()
    doc.appendOutput("hello", stream: .stdout)
    let attrs = doc.output.attributes(at: 0, effectiveRange: nil)
    let color = attrs[.foregroundColor] as? UIColor
    #expect(color == .label)
  }

  @Test
  func appendOutputWithStderrSetsSystemRedColor() {
    let doc = EditorDocument()
    doc.appendOutput("error", stream: .stderr)
    let attrs = doc.output.attributes(at: 0, effectiveRange: nil)
    let color = attrs[.foregroundColor] as? UIColor
    #expect(color == .systemRed)
  }

  // MARK: - hasUnseenOutput

  @Test
  func hasUnseenOutputSetOnFirstAppendOnly() {
    let doc = EditorDocument()
    #expect(!doc.hasUnseenOutput)

    // First append into empty output sets hasUnseenOutput.
    doc.appendOutput("first", stream: .stdout)
    #expect(doc.hasUnseenOutput)

    // Consumer marks output as seen.
    doc.hasUnseenOutput = false

    // Subsequent append while output is non-empty does NOT re-set the flag.
    doc.appendOutput("second", stream: .stdout)
    #expect(!doc.hasUnseenOutput)
  }

  // MARK: - clearOutput

  @Test
  func clearOutputResetsLength() {
    let doc = EditorDocument()
    doc.appendOutput("some text", stream: .stdout)
    #expect(doc.output.length > 0)
    doc.clearOutput()
    #expect(doc.output.length == 0)
  }

  @Test
  func outputVersionIncrementsAfterClearOutput() {
    let doc = EditorDocument()
    let versionBefore = doc.outputVersion
    doc.appendOutput("text", stream: .stdout)
    doc.clearOutput()
    #expect(doc.outputVersion > versionBefore)
  }

  // MARK: - outputVersion after flush

  @Test
  func outputVersionIncrementsAfterFlush() async {
    let doc = EditorDocument()
    let versionBefore = doc.outputVersion
    doc.appendOutput("text", stream: .stdout)
    // The scheduled flush fires after ~16ms; wait 25ms to be safe.
    try? await Task.sleep(for: .milliseconds(25))
    #expect(doc.outputVersion > versionBefore)
  }

  // MARK: - hasOutput

  @Test
  func hasOutputReflectsOutputState() {
    let doc = EditorDocument()
    #expect(!doc.hasOutput)

    doc.appendOutput("data", stream: .stdout)
    #expect(doc.hasOutput)

    doc.clearOutput()
    #expect(!doc.hasOutput)
  }
}
