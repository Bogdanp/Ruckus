import Foundation
import os

@MainActor @Observable
class PackageManager {
  private(set) var installedPackages: [InstalledPackage] = []
  private(set) var searchResults: [CatalogPackage] = []
  private(set) var isLoadingInstalled = false
  private(set) var isSearching = false
  private(set) var error: String?

  func loadInstalled() async {
    isLoadingInstalled = true
    error = nil
    do {
      installedPackages = try await Backend.shared.listInstalledPackages()
        .sorted { $0.name < $1.name }
    } catch {
      self.error = error.localizedDescription
      Logger.backend.warning("loadInstalled: \(error)")
    }
    isLoadingInstalled = false
  }

  func install(source: String) async throws {
    try await Backend.shared.installPackage(source)
    await loadInstalled()
  }

  func remove(name: String) async throws {
    try await Backend.shared.removePackage(name)
    installedPackages.removeAll { $0.name == name }
  }

  func search(query: String) async {
    guard !query.isEmpty else {
      searchResults = []
      return
    }
    isSearching = true
    do {
      searchResults = try await Backend.shared.searchPackages(query)
    } catch {
      Logger.backend.warning("searchPackages: \(error)")
      searchResults = []
    }
    isSearching = false
  }
}
