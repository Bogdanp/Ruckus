import Foundation

struct OutputBuffer {
  private var pending = Data()
  private(set) var decoded = ""

  mutating func decode(_ data: Data) -> String {
    pending.append(data)
    guard !pending.isEmpty else { return "" }
    let trailingCount = incompleteTrailingByteCount(pending)
    if trailingCount == pending.count {
      return ""
    }
    let decodableEnd = pending.count - trailingCount
    let decodable = pending[pending.startIndex..<pending.index(pending.startIndex, offsetBy: decodableEnd)]
    let result = String(decoding: decodable, as: UTF8.self)
    pending = Data(pending.suffix(trailingCount))
    decoded += result
    return result
  }

  mutating func flush() -> String {
    guard !pending.isEmpty else { return "" }
    let result = String(decoding: pending, as: UTF8.self)
    pending = Data()
    decoded += result
    return result
  }

  private func incompleteTrailingByteCount(_ data: Data) -> Int {
    guard !data.isEmpty else { return 0 }
    // Scan backwards from the end to find the start of the last UTF-8
    // sequence. Continuation bytes have the form 10xxxxxx. Leading bytes
    // start with 0xxxxxxx (ASCII), 110xxxxx (2-byte), 1110xxxx (3-byte),
    // or 11110xxx (4-byte).
    var trailing = 0
    var idx = data.endIndex
    // Count continuation bytes at the end (up to 3).
    while trailing < 3, idx > data.startIndex {
      idx = data.index(before: idx)
      if data[idx] & 0xC0 == 0x80 {
        trailing += 1
      } else {
        break
      }
    }
    // idx now points at the last non-continuation byte.
    let lead = data[idx]
    if lead & 0x80 == 0 {
      return 0 // ASCII — sequence is complete.
    }
    let expected: Int
    switch lead {
    case let lead where lead & 0xE0 == 0xC0: expected = 2
    case let lead where lead & 0xF0 == 0xE0: expected = 3
    case let lead where lead & 0xF8 == 0xF0: expected = 4
    default: return 0 // Invalid leading byte — not an incomplete sequence.
    }
    let available = trailing + 1 // leading byte + continuation bytes after it
    if available < expected {
      return available
    }
    return 0
  }
}
