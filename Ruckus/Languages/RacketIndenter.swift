struct RacketIndenter {
  func indentForNewline(in text: String, at offset: Int) -> String {
    let chars = Array(text.prefix(offset))
    guard let (parenCol, parenIdx) = lastUnmatchedOpenParen(in: chars) else {
      return ""
    }
    // Find end of the line containing the open paren.
    var lineEnd = parenIdx + 1
    while lineEnd < chars.count && !chars[lineEnd].isNewline {
      lineEnd += 1
    }
    // Skip whitespace to find the first token after the paren.
    var pos = parenIdx + 1
    while pos < lineEnd && chars[pos].isWhitespace {
      pos += 1
    }
    guard pos < lineEnd else {
      return String(repeating: " ", count: parenCol + 1)
    }
    let firstCol = parenCol + (pos - parenIdx)
    // If the first character is an open paren, align with it.
    if chars[pos] == "(" || chars[pos] == "[" || chars[pos] == "{" {
      return String(repeating: " ", count: firstCol)
    }
    // Read the symbol name.
    let symbolStart = pos
    while pos < lineEnd && isSymbolChar(chars[pos]) {
      pos += 1
    }
    let symbol = String(chars[symbolStart..<pos])
    if isDefineLike(symbol) {
      return String(repeating: " ", count: parenCol + 2)
    }
    // Skip whitespace to find the second token.
    while pos < lineEnd && chars[pos].isWhitespace {
      pos += 1
    }
    if pos < lineEnd {
      return String(repeating: " ", count: parenCol + (pos - parenIdx))
    }
    return String(repeating: " ", count: firstCol)
  }

  // swiftlint:disable:next cyclomatic_complexity function_body_length
  private func lastUnmatchedOpenParen(
    in chars: [Character]
  ) -> (column: Int, index: Int)? {
    var stack: [(column: Int, index: Int)] = []
    var inString = false
    var escaped = false
    var inLineComment = false
    var blockCommentDepth = 0
    var prevChar: Character = "\0"
    var col = 0
    for (idx, char) in chars.enumerated() {
      let charCol = col
      if char.isNewline { col = 0 } else { col += 1 }
      if escaped { escaped = false; prevChar = char; continue }
      if blockCommentDepth > 0 {
        if char.isNewline { prevChar = char; continue }
        if prevChar == "|" && char == "#" {
          blockCommentDepth -= 1
          prevChar = "\0"
          continue
        }
        if prevChar == "#" && char == "|" {
          blockCommentDepth += 1
          prevChar = "\0"
          continue
        }
        prevChar = char
        continue
      }
      if inLineComment {
        if char.isNewline { inLineComment = false }
        prevChar = char
        continue
      }
      if inString {
        switch char {
        case "\\": escaped = true
        case "\"": inString = false
        default: break
        }
        prevChar = char
        continue
      }
      if prevChar == "#" && char == "|" {
        blockCommentDepth += 1
        prevChar = "\0"
        continue
      }
      switch char {
      case "\"": inString = true
      case ";": inLineComment = true
      case "(", "[", "{":
        stack.append((column: charCol, index: idx))
      case ")", "]", "}":
        if !stack.isEmpty { stack.removeLast() }
      default: break
      }
      prevChar = char
    }
    return stack.last
  }

  private func isSymbolChar(_ char: Character) -> Bool {
    !char.isWhitespace && char != "(" && char != ")" && char != "["
      && char != "]" && char != "{" && char != "}" && char != "\""
      && char != ";"
  }

  private func isDefineLike(_ symbol: String) -> Bool {
    if symbol.isEmpty { return false }
    if symbol.hasPrefix("define") { return true }
    if symbol == "for" || symbol.hasPrefix("for/") || symbol.hasPrefix("for*") {
      return true
    }
    return defineLikeForms.contains(symbol)
  }

  private let defineLikeForms: Set<String> = [
    "let", "let*", "letrec", "let-values", "let-syntax", "letrec-syntax",
    "lambda", "λ", "case-lambda",
    "if", "when", "unless",
    "cond", "case", "match", "match*", "match-let",
    "begin", "begin0",
    "with-handlers", "with-handlers*",
    "struct", "class", "class*",
    "module", "module+", "module*",
    "parameterize", "with-syntax",
    "syntax-case", "syntax-rules", "syntax-parse",
    "provide", "require"
  ]
}
