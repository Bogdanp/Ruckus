import UIKit

struct BracketHighlighter {
  struct Bracket {
    let position: Int
    let depth: Int
    let character: Character
  }

  struct MatchedPair {
    let open: Int
    let close: Int
  }

  static let defaultColors: [UIColor] = [
    UIColor(hex: 0xE06C75, alpha: 0.15),
    UIColor(hex: 0xD19A66, alpha: 0.15),
    UIColor(hex: 0xE5C07B, alpha: 0.15),
    UIColor(hex: 0x98C379, alpha: 0.15),
    UIColor(hex: 0x61AFEF, alpha: 0.15),
    UIColor(hex: 0xC678DD, alpha: 0.15)
  ]

  static let matchColor = UIColor.systemYellow.withAlphaComponent(0.4)

  private static let openers: Set<Character> = ["(", "[", "{"]
  private static let closers: Set<Character> = [")", "]", "}"]

  static func findBrackets(in text: String) -> [Bracket] {
    let chars = Array(text)
    var brackets: [Bracket] = []
    var depth = 0
    var idx = 0

    while idx < chars.count {
      if chars[idx] == ";" {
        idx += 1
        while idx < chars.count && chars[idx] != "\n" { idx += 1 }
        continue
      }

      if chars[idx] == "#" && idx + 1 < chars.count && chars[idx + 1] == "|" {
        idx += 2
        var nesting = 1
        while idx + 1 < chars.count && nesting > 0 {
          if chars[idx] == "#" && chars[idx + 1] == "|" {
            nesting += 1
            idx += 2
          } else if chars[idx] == "|" && chars[idx + 1] == "#" {
            nesting -= 1
            idx += 2
          } else {
            idx += 1
          }
        }
        continue
      }

      if chars[idx] == "\"" {
        idx += 1
        while idx < chars.count && chars[idx] != "\"" {
          if chars[idx] == "\\" { idx += 1 }
          idx += 1
        }
        idx += 1
        continue
      }

      if openers.contains(chars[idx]) {
        brackets.append(Bracket(position: idx, depth: depth, character: chars[idx]))
        depth += 1
      } else if closers.contains(chars[idx]) {
        depth = max(0, depth - 1)
        brackets.append(Bracket(position: idx, depth: depth, character: chars[idx]))
      }

      idx += 1
    }

    return brackets
  }

  static func findMatch(in text: String, at cursorPosition: Int) -> MatchedPair? {
    let chars = Array(text)
    guard cursorPosition >= 0, cursorPosition <= chars.count else { return nil }

    let positions = [cursorPosition - 1, cursorPosition]
    for pos in positions {
      guard pos >= 0, pos < chars.count else { continue }
      let char = chars[pos]

      if openers.contains(char) {
        if let closePos = findMatchingClose(in: chars, from: pos) {
          return MatchedPair(open: pos, close: closePos)
        }
      } else if closers.contains(char) {
        if let openPos = findMatchingOpen(in: chars, from: pos) {
          return MatchedPair(open: openPos, close: pos)
        }
      }
    }

    return nil
  }

  private static func findMatchingClose(in chars: [Character], from start: Int) -> Int? {
    let opener = chars[start]
    let closer = matchingCloser(for: opener)
    var depth = 0
    var idx = start

    while idx < chars.count {
      if chars[idx] == ";" {
        idx += 1
        while idx < chars.count && chars[idx] != "\n" { idx += 1 }
        continue
      }

      if chars[idx] == "#" && idx + 1 < chars.count && chars[idx + 1] == "|" {
        idx += 2
        var nesting = 1
        while idx + 1 < chars.count && nesting > 0 {
          if chars[idx] == "#" && chars[idx + 1] == "|" {
            nesting += 1
            idx += 2
          } else if chars[idx] == "|" && chars[idx + 1] == "#" {
            nesting -= 1
            idx += 2
          } else {
            idx += 1
          }
        }
        continue
      }

      if chars[idx] == "\"" {
        idx += 1
        while idx < chars.count && chars[idx] != "\"" {
          if chars[idx] == "\\" { idx += 1 }
          idx += 1
        }
        idx += 1
        continue
      }

      if chars[idx] == opener { depth += 1 }
      else if chars[idx] == closer {
        depth -= 1
        if depth == 0 { return idx }
      }

      idx += 1
    }

    return nil
  }

  private static func findMatchingOpen(in chars: [Character], from start: Int) -> Int? {
    let closer = chars[start]
    let opener = matchingOpener(for: closer)
    var stack: [Int] = []
    var idx = 0

    while idx <= start {
      if chars[idx] == ";" {
        idx += 1
        while idx <= start && chars[idx] != "\n" { idx += 1 }
        continue
      }

      if chars[idx] == "#" && idx + 1 < chars.count && chars[idx + 1] == "|" {
        idx += 2
        var nesting = 1
        while idx + 1 < chars.count && nesting > 0 {
          if chars[idx] == "#" && chars[idx + 1] == "|" {
            nesting += 1
            idx += 2
          } else if chars[idx] == "|" && chars[idx + 1] == "#" {
            nesting -= 1
            idx += 2
          } else {
            idx += 1
          }
        }
        continue
      }

      if chars[idx] == "\"" {
        idx += 1
        while idx < chars.count && chars[idx] != "\"" {
          if chars[idx] == "\\" { idx += 1 }
          idx += 1
        }
        idx += 1
        continue
      }

      if chars[idx] == opener {
        stack.append(idx)
      } else if chars[idx] == closer {
        if idx == start {
          return stack.popLast()
        }
        _ = stack.popLast()
      }

      idx += 1
    }

    return nil
  }

  private static func matchingCloser(for opener: Character) -> Character {
    switch opener {
    case "(": return ")"
    case "[": return "]"
    case "{": return "}"
    default: return ")"
    }
  }

  private static func matchingOpener(for closer: Character) -> Character {
    switch closer {
    case ")": return "("
    case "]": return "["
    case "}": return "{"
    default: return "("
    }
  }
}
