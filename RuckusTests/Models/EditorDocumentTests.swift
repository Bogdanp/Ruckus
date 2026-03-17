import Testing
import UIKit

@testable import Ruckus

@Suite
@MainActor
struct EditorDocumentTests {

  // MARK: - init

  @Test
  func defaultInit() {
    let doc = EditorDocument()
    #expect(doc.title == "Untitled")
    #expect(doc.path == nil)
    #expect(doc.code == "")
    #expect(!doc.isDirty)
    #expect(!doc.isEvaluating)
    #expect(doc.executionId == nil)
    #expect(doc.tempPath == nil)
    #expect(doc.completions.isEmpty)
    #expect(doc.output.length == 0)
    #expect(!doc.hasUnseenOutput)
  }

  @Test
  func initWithArguments() {
    let doc = EditorDocument(title: "test.rkt", path: "/files/test.rkt", code: "(+ 1 2)")
    #expect(doc.title == "test.rkt")
    #expect(doc.path == "/files/test.rkt")
    #expect(doc.code == "(+ 1 2)")
  }

  // MARK: - appendOutput

  @Test
  func appendStdoutSetsLabelColor() {
    let doc = EditorDocument()
    doc.appendOutput("hello", stream: .stdout)
    #expect(doc.output.length == 5)
    let attrs = doc.output.attributes(at: 0, effectiveRange: nil)
    let color = attrs[.foregroundColor] as? UIColor
    #expect(color == .label)
  }

  @Test
  func appendStderrSetsRedColor() {
    let doc = EditorDocument()
    doc.appendOutput("error", stream: .stderr)
    let attrs = doc.output.attributes(at: 0, effectiveRange: nil)
    let color = attrs[.foregroundColor] as? UIColor
    #expect(color == .systemRed)
  }

  @Test
  func appendOutputUsesMonospacedFont() {
    let doc = EditorDocument()
    doc.appendOutput("text", stream: .stdout)
    let attrs = doc.output.attributes(at: 0, effectiveRange: nil)
    let font = attrs[.font] as? UIFont
    #expect(font != nil)
    #expect(font!.fontDescriptor.symbolicTraits.contains(.traitMonoSpace))
  }

  @Test
  func appendOutputAccumulates() {
    let doc = EditorDocument()
    doc.appendOutput("line1\n", stream: .stdout)
    doc.appendOutput("line2\n", stream: .stderr)
    #expect(doc.output.string == "line1\nline2\n")
  }

  @Test
  func appendOutputSetsHasUnseenOnFirstAppend() {
    let doc = EditorDocument()
    #expect(!doc.hasUnseenOutput)
    doc.appendOutput("first", stream: .stdout)
    #expect(doc.hasUnseenOutput)
  }

  @Test
  func appendOutputDoesNotResetHasUnseenOnSubsequentAppends() {
    let doc = EditorDocument()
    doc.appendOutput("first", stream: .stdout)
    doc.hasUnseenOutput = false
    doc.appendOutput("second", stream: .stdout)
    // hasUnseenOutput is only set when output transitions from empty
    #expect(!doc.hasUnseenOutput)
  }

  // MARK: - identity

  @Test
  func eachDocumentGetsUniqueId() {
    let doc1 = EditorDocument()
    let doc2 = EditorDocument()
    #expect(doc1.id != doc2.id)
  }

  // MARK: - saved state

  @Test
  func savedContentOffsetDefaultsToNil() {
    let doc = EditorDocument()
    #expect(doc.savedContentOffset == nil)
    #expect(doc.savedSelectedRange == nil)
  }
}
