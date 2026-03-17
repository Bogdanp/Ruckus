import Foundation
import Testing

@testable import Ruckus

@Suite
struct OutputBufferTests {
  @Test
  func asciiPassesThrough() {
    var buf = OutputBuffer()
    let text = buf.decode(Data("hello world".utf8))
    #expect(text == "hello world")
  }

  @Test
  func validMultiBytePassesThrough() {
    var buf = OutputBuffer()
    let text = buf.decode(Data("café 日本語 🎉".utf8))
    #expect(text == "café 日本語 🎉")
  }

  @Test
  func splitTwoByteCharacter() {
    var buf = OutputBuffer()
    // "é" is U+00E9, encoded as [0xC3, 0xA9]
    let first = buf.decode(Data([0x63, 0x61, 0x66, 0xC3])) // "caf" + first byte of é
    #expect(first == "caf")
    let second = buf.decode(Data([0xA9])) // second byte of é
    #expect(second == "é")
  }

  @Test
  func splitThreeByteCharacter() {
    var buf = OutputBuffer()
    // "日" is U+65E5, encoded as [0xE6, 0x97, 0xA5]
    let first = buf.decode(Data([0xE6, 0x97])) // first two bytes
    #expect(first == "")
    let second = buf.decode(Data([0xA5])) // final byte
    #expect(second == "日")
  }

  @Test
  func splitFourByteCharacter() {
    var buf = OutputBuffer()
    // "🎉" is U+1F389, encoded as [0xF0, 0x9F, 0x8E, 0x89]
    let first = buf.decode(Data([0x41, 0xF0, 0x9F])) // "A" + first two bytes
    #expect(first == "A")
    let second = buf.decode(Data([0x8E, 0x89])) // last two bytes
    #expect(second == "🎉")
  }

  @Test
  func invalidBytesProduceReplacementCharacter() {
    var buf = OutputBuffer()
    // 0xFF is never valid in UTF-8
    let text = buf.decode(Data([0x68, 0x69, 0xFF, 0x21])) // "hi" + invalid + "!"
    #expect(text == "hi\u{FFFD}!")
  }

  @Test
  func flushDecodesRemainingPendingBytes() {
    var buf = OutputBuffer()
    // Send an incomplete sequence then flush
    let first = buf.decode(Data([0x41, 0xC3])) // "A" + first byte of é
    #expect(first == "A")
    let flushed = buf.flush()
    #expect(flushed == "\u{FFFD}")
  }

  @Test
  func flushOnEmptyBufferReturnsEmpty() {
    var buf = OutputBuffer()
    #expect(buf.flush() == "")
  }

  @Test
  func emptyInputReturnsEmpty() {
    var buf = OutputBuffer()
    #expect(buf.decode(Data()) == "")
  }

  @Test
  func multipleChunksAccumulate() {
    var buf = OutputBuffer()
    // "é" split across chunks with surrounding ASCII
    let first = buf.decode(Data([0x68, 0x65, 0x6C, 0x6C, 0x6F, 0xC3])) // "hello" + 0xC3
    #expect(first == "hello")
    let second = buf.decode(Data([0xA9, 0x20, 0x77, 0x6F, 0x72, 0x6C, 0x64])) // 0xA9 + " world"
    #expect(second == "é world")
  }
}
