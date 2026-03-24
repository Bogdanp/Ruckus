import Foundation
import os

@MainActor @Observable
class PackageManager {
  static let shared = PackageManager()

  private(set) var installedPackages: [InstalledPackage] = []
  private(set) var searchResults: [CatalogPackage] = []
  private(set) var isLoadingInstalled = false
  private(set) var isSearching = false
  private(set) var activeOperations: Set<String> = []
  var alertMessage: String?

  var manualPackages: [InstalledPackage] {
    installedPackages.filter { !$0.autoHuh }
  }

  var autoPackages: [InstalledPackage] {
    installedPackages.filter(\.autoHuh)
  }

  var installedNames: Set<String> {
    Set(installedPackages.map(\.name))
  }

  func isOperationActive(for name: String) -> Bool {
    activeOperations.contains(name)
  }

  func loadInstalled() async {
    guard !isLoadingInstalled else { return }
    isLoadingInstalled = true
    do {
      installedPackages = try await Backend.shared.listInstalledPackages()
        .sorted { $0.name < $1.name }
    } catch is CancellationError {
      // View disappeared during load — not an error.
    } catch {
      alertMessage = "Failed to load packages: \(error.localizedDescription)"
      Logger.backend.warning("loadInstalled: \(error)")
    }
    isLoadingInstalled = false
  }

  func install(source: String) async {
    activeOperations.insert(source)
    defer { activeOperations.remove(source) }
    do {
      try await Backend.shared.installPackage(source)
      await loadInstalled()
    } catch {
      alertMessage = "Failed to install \(source): \(error.localizedDescription)"
      Logger.backend.warning("installPackage: \(error)")
    }
  }

  func remove(name: String) async {
    activeOperations.insert(name)
    defer { activeOperations.remove(name) }
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
    defer { isSearching = false }
    do {
      searchResults = try await Backend.shared.searchPackages(query)
    } catch {
      Logger.backend.warning("searchPackages: \(error)")
      searchResults = []
    }
  }
}
