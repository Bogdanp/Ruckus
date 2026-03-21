import Foundation
import SwiftUI
import Testing

@testable import Ruckus

@Suite
struct FolderBrowserTests {

  // Use concrete type aliases to avoid specifying generic parameters.
  private typealias Browser = FolderBrowser<EmptyView, EmptyView>

  // MARK: - navigationTitle

  @Test
  func navigationTitleShowsRootTitleAtRoot() {
    let title = Browser.navigationTitle(
      currentDirectory: "/root", rootPath: "/root", rootTitle: "Open")
    #expect(title == "Open")
  }

  @Test
  func navigationTitleShowsLastComponentInSubdirectory() {
    let title = Browser.navigationTitle(
      currentDirectory: "/root/Examples", rootPath: "/root", rootTitle: "Open")
    #expect(title == "Examples")
  }

  // MARK: - sanitizeFolderName

  @Test
  func sanitizeFolderNameTrimsWhitespace() {
    #expect(Browser.sanitizeFolderName("  my-folder  ") == "my-folder")
  }

  @Test
  func sanitizeFolderNameRejectsEmpty() {
    #expect(Browser.sanitizeFolderName("   ") == nil)
  }

  @Test
  func sanitizeFolderNameRejectsCompletelyEmpty() {
    #expect(Browser.sanitizeFolderName("") == nil)
  }

  // MARK: - Backend operations

  @Test
  func createDirectoryAppearsInListing() async throws {
    let root = try await Backend.shared.getRootPath()
    let name = "test-\(UUID().uuidString)"
    let path = root.appendingPathComponent(name)
    try await Backend.shared.createDirectory(atPath: path)
    defer { Task { try? await Backend.shared.deleteDirectory(atPath: path) } }

    let entries = try await Backend.shared.listFiles(atPath: root)
    let names = entries.toBrowserEntries().map(\.name)
    #expect(names.contains(name))
  }

  @Test
  func deleteFileRemovesFromListing() async throws {
    let root = try await Backend.shared.getRootPath()
    let name = "test-\(UUID().uuidString).rkt"
    let path = root.appendingPathComponent(name)
    try await Backend.shared.save("", to: path)

    try await Backend.shared.deleteFile(atPath: path)

    let entries = try await Backend.shared.listFiles(atPath: root)
    let names = entries.toBrowserEntries().map(\.name)
    #expect(!names.contains(name))
  }

  @Test
  func deleteDirectoryRemovesFromListing() async throws {
    let root = try await Backend.shared.getRootPath()
    let name = "test-\(UUID().uuidString)"
    let path = root.appendingPathComponent(name)
    try await Backend.shared.createDirectory(atPath: path)

    try await Backend.shared.deleteDirectory(atPath: path)

    let entries = try await Backend.shared.listFiles(atPath: root)
    let names = entries.toBrowserEntries().map(\.name)
    #expect(!names.contains(name))
  }
}
