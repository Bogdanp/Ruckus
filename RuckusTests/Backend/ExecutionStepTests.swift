import Foundation
import Testing

@testable import Ruckus

@Suite
struct ExecutionStepTests {

  // MARK: - isDone

  @Test
  func doneStepIsDone() {
    let step = ExecutionStep.done(ExecutionOutput(stdout: Data(), stderr: Data()))
    #expect(step.isDone)
  }

  @Test
  func moreStepIsNotDone() {
    let step = ExecutionStep.more(ExecutionOutput(stdout: Data(), stderr: Data()))
    #expect(!step.isDone)
  }

  // MARK: - output

  @Test
  func doneStepReturnsOutput() {
    let out = ExecutionOutput(stdout: Data("hello".utf8), stderr: Data("err".utf8))
    let step = ExecutionStep.done(out)
    #expect(step.output.stdout == Data("hello".utf8))
    #expect(step.output.stderr == Data("err".utf8))
  }

  @Test
  func moreStepReturnsOutput() {
    let out = ExecutionOutput(stdout: Data("chunk".utf8), stderr: Data())
    let step = ExecutionStep.more(out)
    #expect(step.output.stdout == Data("chunk".utf8))
    #expect(step.output.stderr == Data())
  }

  @Test
  func emptyOutput() {
    let step = ExecutionStep.more(ExecutionOutput(stdout: Data(), stderr: Data()))
    #expect(step.output.stdout.isEmpty)
    #expect(step.output.stderr.isEmpty)
  }
}
