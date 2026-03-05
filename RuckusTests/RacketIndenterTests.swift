import Testing

@testable import Ruckus

@Suite
struct RacketIndenterTests {
  let indenter = RacketIndenter()

  private func indent(_ text: String) -> String {
    indenter.indentForNewline(in: text, at: text.count)
  }

  // MARK: - Define-like forms

  @Test func defineLike() {
    #expect(indent("(define (f x)") == "  ")
  }

  @Test func definePublic() {
    #expect(indent("(define/public (f x)") == "  ")
  }

  @Test func defineStruct() {
    #expect(indent("(define-struct point") == "  ")
  }

  @Test func defineValues() {
    #expect(indent("(define-values (a b)") == "  ")
  }

  // MARK: - Let forms

  @Test func letBody() {
    #expect(indent("(let ([x 1])") == "  ")
  }

  @Test func letBinderAlignment() {
    #expect(indent("(let ([x 1]") == "      ")
  }

  @Test func letStar() {
    #expect(indent("(let* ([x 1])") == "  ")
  }

  @Test func letrec() {
    #expect(indent("(letrec ([f (lambda (x) x)])") == "  ")
  }

  // MARK: - For forms

  @Test func forSlashList() {
    #expect(indent("(for/list ([x xs])") == "  ")
  }

  @Test func forStar() {
    #expect(indent("(for* ([x xs])") == "  ")
  }

  @Test func plainFor() {
    #expect(indent("(for ([x xs])") == "  ")
  }

  // MARK: - Other define-like keywords

  @Test func lambda() {
    #expect(indent("(lambda (x)") == "  ")
  }

  @Test func lambdaUnicode() {
    #expect(indent("(λ (x)") == "  ")
  }

  @Test func ifForm() {
    #expect(indent("(if (> x 0)") == "  ")
  }

  @Test func whenForm() {
    #expect(indent("(when condition") == "  ")
  }

  @Test func condForm() {
    #expect(indent("(cond") == "  ")
  }

  @Test func matchForm() {
    #expect(indent("(match x") == "  ")
  }

  @Test func beginForm() {
    #expect(indent("(begin") == "  ")
  }

  @Test func moduleForm() {
    #expect(indent("(module+ test") == "  ")
  }

  @Test func withHandlers() {
    #expect(indent("(with-handlers ([exn:fail? handler])") == "  ")
  }

  @Test func syntaxParse() {
    #expect(indent("(syntax-parse stx") == "  ")
  }

  @Test func provide() {
    #expect(indent("(provide") == "  ")
  }

  @Test func require() {
    #expect(indent("(require") == "  ")
  }

  // MARK: - Multi-symbol alignment

  @Test func multiSymbolAlignment() {
    #expect(indent("(foo bar") == "     ")
  }

  @Test func multiSymbolAlignmentWithArg() {
    #expect(indent("(+ 1 2") == "   ")
  }

  // MARK: - Single symbol

  @Test func singleSymbol() {
    #expect(indent("(foo") == " ")
  }

  @Test func singleSymbolWithTrailingSpace() {
    // Trailing space only, no token visible after paren — treated as empty paren.
    #expect(indent("(foo ") == " ")
  }

  // MARK: - Empty paren

  @Test func emptyParen() {
    #expect(indent("(") == " ")
  }

  @Test func emptyBracket() {
    #expect(indent("[") == " ")
  }

  @Test func emptyBrace() {
    #expect(indent("{") == " ")
  }

  // MARK: - Nested parens

  @Test func nestedParens() {
    #expect(indent("(define (f x)\n  (let ([y 1]") == "        ")
  }

  @Test func nestedParensBody() {
    #expect(indent("(define (f x)\n  (let ([y 1])") == "    ")
  }

  @Test func deeplyNested() {
    // Innermost unmatched paren is at col 6, `c` is at col 7.
    #expect(indent("(a (b (c") == "       ")
  }

  // MARK: - Strings (parens inside strings ignored)

  @Test func parensInsideString() {
    #expect(indent("(define x \"(not a paren)\"") == "  ")
  }

  @Test func unmatchedParenInsideString() {
    #expect(indent("(foo \"(\"") == "     ")
  }

  // MARK: - Comments (parens inside comments ignored)

  @Test func parensInsideComment() {
    #expect(indent("(define x ; (not a paren)") == "  ")
  }

  @Test func commentAfterCode() {
    #expect(indent("(foo bar ; baz") == "     ")
  }

  // MARK: - Top level (no unmatched paren)

  @Test func topLevel() {
    #expect(indent("(define x 1)") == "")
  }

  @Test func emptyText() {
    #expect(indent("") == "")
  }

  @Test func noParens() {
    #expect(indent("hello world") == "")
  }

  // MARK: - Sub-paren alignment

  @Test func subParenAlignment() {
    #expect(indent("(list (+ 1 2)") == "      ")
  }

  // MARK: - Offset within text

  @Test func offsetInMiddle() {
    let text = "(define (f x)\n  (+ x 1))"
    // Offset at end of first line (before newline)
    let offset = 14
    #expect(indenter.indentForNewline(in: text, at: offset) == "  ")
  }
}
