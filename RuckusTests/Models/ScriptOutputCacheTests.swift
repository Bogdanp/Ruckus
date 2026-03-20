import Foundation
import Testing

@testable import Ruckus

@Suite
struct ScriptOutputCacheTests {

  @Test
  func saveLoadRoundTrip() {
    let id = UUID().uuidString
    defer { ScriptOutputCache.remove(for: id) }

    ScriptOutputCache.save(output: "hello world", for: id)
    let result = ScriptOutputCache.load(for: id)

    #expect(result != nil)
    #expect(result?.output == "hello world")
    #expect(result!.date.timeIntervalSinceNow > -5)
  }

  @Test
  func loadReturnsNilForMissingKey() {
    let id = UUID().uuidString
    let result = ScriptOutputCache.load(for: id)
    #expect(result == nil)
  }

  @Test
  func removeDeletesSavedEntry() {
    let id = UUID().uuidString
    defer { ScriptOutputCache.remove(for: id) }

    ScriptOutputCache.save(output: "hello", for: id)
    ScriptOutputCache.remove(for: id)

    let result = ScriptOutputCache.load(for: id)
    #expect(result == nil)
  }

  @Test
  func overwriteReplacesValue() {
    let id = UUID().uuidString
    defer { ScriptOutputCache.remove(for: id) }

    ScriptOutputCache.save(output: "first", for: id)
    ScriptOutputCache.save(output: "second", for: id)

    let result = ScriptOutputCache.load(for: id)
    #expect(result?.output == "second")
  }
}
