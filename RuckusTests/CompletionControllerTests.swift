import Testing

@testable import Ruckus

@Suite
@MainActor
struct CompletionControllerTests {

  private let controller = CompletionController()

  // MARK: - scanIdentifiers

  @Test func emptyString() {
    let ids = controller.scanIdentifiers(in: "")
    #expect(ids.isEmpty)
  }

  @Test func singleShortToken() {
    let ids = controller.scanIdentifiers(in: "x")
    #expect(ids.isEmpty)
  }

  @Test func singleValidToken() {
    let ids = controller.scanIdentifiers(in: "foo")
    #expect(ids == ["foo"])
  }

  @Test func multipleTokens() {
    let ids = controller.scanIdentifiers(in: "(define my-helper 42)")
    #expect(ids.contains("define"))
    #expect(ids.contains("my-helper"))
    #expect(ids.contains("42"))
    #expect(!ids.contains("("))
    #expect(!ids.contains(")"))
  }

  @Test func tokenAtEndOfString() {
    let ids = controller.scanIdentifiers(in: "(add1")
    #expect(ids.contains("add1"))
  }

  @Test func filtersOutSingleCharTokens() {
    let ids = controller.scanIdentifiers(in: "(+ x y)")
    #expect(ids.isEmpty)
  }

  @Test func racketSpecialChars() {
    let ids = controller.scanIdentifiers(in: "string->number list? set!")
    #expect(ids.contains("string->number"))
    #expect(ids.contains("list?"))
    #expect(ids.contains("set!"))
  }

  @Test func deduplicates() {
    let ids = controller.scanIdentifiers(in: "(define foo (+ foo bar))")
    #expect(ids.contains("foo"))
    #expect(ids.contains("bar"))
    #expect(ids.contains("define"))
  }

  @Test func multilineText() {
    let text = """
      #lang racket/base
      (define helper 10)
      (println helper)
      """
    let ids = controller.scanIdentifiers(in: text)
    #expect(ids.contains("lang"))
    #expect(ids.contains("racket/base"))
    #expect(ids.contains("define"))
    #expect(ids.contains("helper"))
    #expect(ids.contains("println"))
    #expect(ids.contains("10"))
  }

  @Test func onlyDelimiters() {
    let ids = controller.scanIdentifiers(in: "()[]  \n\t")
    #expect(ids.isEmpty)
  }
}
