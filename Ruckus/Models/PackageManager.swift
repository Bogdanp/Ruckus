import Foundation
import os

@MainActor @Observable
class PackageManager {
  private(set) var installedPackages: [InstalledPackage] = []
  private(set) var searchResults: [CatalogPackage] = []
  private(set) var isLoadingInstalled = false
  private(set) var isSearching = false
  var alertMessage: String?

  var installedNames: Set<String> {
    Set(installedPackages.map(\.name))
  }

  func loadInstalled() async {
    isLoadingInstalled = true
    do {
      installedPackages = try await Backend.shared.listInstalledPackages()
        .sorted { $0.name < $1.name }
    } catch {
      alertMessage = "Failed to load packages: \(error.localizedDescription)"
      Logger.backend.warning("loadInstalled: \(error)")
    }
    isLoadingInstalled = false
  }

  func install(source: String) async {
    do {
      try await Backend.shared.installPackage(source)
      await loadInstalled()
    } catch {
      alertMessage = "Failed to install \(source): \(error.localizedDescription)"
      Logger.backend.warning("installPackage: \(error)")
    }
  }

  func remove(name: String) async {
    do {
      try await Backend.shared.removePackage(name)
      installedPackages.removeAll { $0.name == name }
    } catch {
      alertMessage = "Failed to remove \(name): \(error.localizedDescription)"
      Logger.backend.warning("removePackage: \(error)")
    }
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
