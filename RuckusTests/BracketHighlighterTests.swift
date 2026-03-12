import Testing

@testable import Ruckus

@Suite
struct BracketHighlighterTests {

  // MARK: - findBrackets

  @Test func emptyString() {
    let brackets = BracketHighlighter().findBrackets(in: "")
    #expect(brackets.isEmpty)
  }

  @Test func noBrackets() {
    let brackets = BracketHighlighter().findBrackets(in: "hello world")
    #expect(brackets.isEmpty)
  }

  @Test func singlePair() {
    let brackets = BracketHighlighter().findBrackets(in: "(x)")
    #expect(brackets.count == 2)
    #expect(brackets[0].position == 0)
    #expect(brackets[0].depth == 0)
    #expect(brackets[0].character == "(")
    #expect(brackets[1].position == 2)
    #expect(brackets[1].depth == 0)
    #expect(brackets[1].character == ")")
  }

  @Test func nestedDepth() {
    let brackets = BracketHighlighter().findBrackets(in: "((()))")
    #expect(brackets.count == 6)
    #expect(brackets[0].depth == 0) // (
    #expect(brackets[1].depth == 1) // (
    #expect(brackets[2].depth == 2) // (
    #expect(brackets[3].depth == 2) // )
    #expect(brackets[4].depth == 1) // )
    #expect(brackets[5].depth == 0) // )
  }

  @Test func mixedBracketTypes() {
    let brackets = BracketHighlighter().findBrackets(in: "([{}])")
    #expect(brackets.count == 6)
    #expect(brackets[0].character == "(")
    #expect(brackets[1].character == "[")
    #expect(brackets[2].character == "{")
    #expect(brackets[3].character == "}")
    #expect(brackets[4].character == "]")
    #expect(brackets[5].character == ")")
  }

  @Test func bracketsInLineComment() {
    let brackets = BracketHighlighter().findBrackets(in: "; (not a bracket)")
    #expect(brackets.isEmpty)
  }

  @Test func bracketsAfterLineComment() {
    let brackets = BracketHighlighter().findBrackets(in: "; comment\n(x)")
    #expect(brackets.count == 2)
    #expect(brackets[0].position == 10)
  }

  @Test func bracketsInString() {
    let brackets = BracketHighlighter().findBrackets(in: #""(not a bracket)""#)
    #expect(brackets.isEmpty)
  }

  @Test func bracketsAfterString() {
    let brackets = BracketHighlighter().findBrackets(in: #""hello" (x)"#)
    #expect(brackets.count == 2)
    #expect(brackets[0].position == 8)
  }

  @Test func escapedQuoteInString() {
    let brackets = BracketHighlighter().findBrackets(in: #""say \"hi\"" (x)"#)
    #expect(brackets.count == 2)
    #expect(brackets[0].character == "(")
  }

  @Test func blockComment() {
    let brackets = BracketHighlighter().findBrackets(in: "#| (not) |# (x)")
    #expect(brackets.count == 2)
    #expect(brackets[0].position == 12)
  }

  @Test func nestedBlockComment() {
    let brackets = BracketHighlighter().findBrackets(in: "#| #| (inner) |# outer |# (x)")
    #expect(brackets.count == 2)
    #expect(brackets[0].position == 26)
  }

  @Test func racketCode() {
    let code = "(define (fib n)\n  (if (<= n 1)\n    n\n    (+ (fib (- n 1)) (fib (- n 2)))))"
    let brackets = BracketHighlighter().findBrackets(in: code)
    // All brackets should be found with correct depths
    #expect(brackets.first?.depth == 0)
    #expect(brackets.first?.character == "(")
    #expect(brackets.last?.depth == 0)
    #expect(brackets.last?.character == ")")
    // Verify no brackets are missed
    let openCount = brackets.filter { "([{".contains($0.character) }.count
    let closeCount = brackets.filter { ")]}".contains($0.character) }.count
    #expect(openCount == closeCount)
  }

  @Test func unmatchedOpen() {
    let brackets = BracketHighlighter().findBrackets(in: "(()")
    #expect(brackets.count == 3)
    #expect(brackets[0].depth == 0)
    #expect(brackets[1].depth == 1)
    #expect(brackets[2].depth == 1) // closes inner
  }

  @Test func unmatchedClose() {
    let brackets = BracketHighlighter().findBrackets(in: "())")
    #expect(brackets.count == 3)
    #expect(brackets[2].depth == 0) // depth clamped at 0
  }

  @Test func depthWrapsAroundColorCount() {
    // 7 levels deep — should cycle through 6 colors
    let code = "(((((((x)))))))"
    let brackets = BracketHighlighter().findBrackets(in: code)
    let maxDepth = brackets.map(\.depth).max() ?? 0
    #expect(maxDepth == 6)
  }

  // MARK: - findMatch

  @Test func matchAtOpenParen() {
    // cursor right after (
    let match = BracketHighlighter().findMatch(in: "(abc)", at: 1)
    #expect(match != nil)
    #expect(match?.open == 0)
    #expect(match?.close == 4)
  }

  @Test func matchAtCloseParen() {
    // cursor right after )
    let match = BracketHighlighter().findMatch(in: "(abc)", at: 5)
    #expect(match != nil)
    #expect(match?.open == 0)
    #expect(match?.close == 4)
  }

  @Test func matchBeforeOpenParen() {
    // cursor right before (
    let match = BracketHighlighter().findMatch(in: "(abc)", at: 0)
    #expect(match != nil)
    #expect(match?.open == 0)
    #expect(match?.close == 4)
  }

  @Test func matchBeforeCloseParen() {
    // cursor right before )
    let match = BracketHighlighter().findMatch(in: "(abc)", at: 4)
    #expect(match != nil)
    #expect(match?.open == 0)
    #expect(match?.close == 4)
  }

  @Test func matchNested() {
    let code = "(a (b) c)"
    // cursor after inner (
    let match = BracketHighlighter().findMatch(in: code, at: 4)
    #expect(match != nil)
    #expect(match?.open == 3)
    #expect(match?.close == 5)
  }

  @Test func matchSquareBrackets() {
    let match = BracketHighlighter().findMatch(in: "[x]", at: 1)
    #expect(match != nil)
    #expect(match?.open == 0)
    #expect(match?.close == 2)
  }

  @Test func matchCurlyBraces() {
    let match = BracketHighlighter().findMatch(in: "{x}", at: 1)
    #expect(match != nil)
    #expect(match?.open == 0)
    #expect(match?.close == 2)
  }

  @Test func noMatchAtNonBracket() {
    let match = BracketHighlighter().findMatch(in: "(abc)", at: 2)
    #expect(match == nil)
  }

  @Test func noMatchUnbalanced() {
    let match = BracketHighlighter().findMatch(in: "(abc", at: 1)
    #expect(match == nil)
  }

  @Test func matchSkipsStringBrackets() {
    // The ) inside the string should not count
    let code = #"(a ")" b)"#
    let match = BracketHighlighter().findMatch(in: code, at: 1)
    #expect(match != nil)
    #expect(match?.open == 0)
    #expect(match?.close == 8)
  }

  @Test func matchSkipsStringBracketsBackward() {
    // Same as above but matching from the closing bracket
    let code = #"(a ")" b)"#
    let match = BracketHighlighter().findMatch(in: code, at: 9)
    #expect(match != nil)
    #expect(match?.open == 0)
    #expect(match?.close == 8)
  }

  @Test func matchSkipsCommentBrackets() {
    let code = "(a ; )\n  b)"
    let match = BracketHighlighter().findMatch(in: code, at: 1)
    #expect(match != nil)
    #expect(match?.open == 0)
    #expect(match?.close == 10)
  }

  @Test func matchSkipsCommentBracketsBackward() {
    let code = "(a ; )\n  b)"
    let match = BracketHighlighter().findMatch(in: code, at: 11)
    #expect(match != nil)
    #expect(match?.open == 0)
    #expect(match?.close == 10)
  }

  @Test func matchFromClosingBackwards() {
    let code = "(define (f x) x)"
    // cursor at final )
    let match = BracketHighlighter().findMatch(in: code, at: 16)
    #expect(match != nil)
    #expect(match?.open == 0)
    #expect(match?.close == 15)
  }

  @Test func matchOutOfBounds() {
    #expect(BracketHighlighter().findMatch(in: "()", at: -1) == nil)
    #expect(BracketHighlighter().findMatch(in: "()", at: 100) == nil)
  }
}
