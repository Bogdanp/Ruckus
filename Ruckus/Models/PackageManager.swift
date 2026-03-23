import Foundation
import os

extension PackageSource {
  var displayString: String {
    switch self {
    case .catalog(let name):
      name
    case .catalogWithSource(_, let source):
      source
    case .url(let url):
      url
    case .git(let url):
      url
    case .file(let path):
      path
    case .dir(let path):
      path
    case .link(let path):
      path
    case .staticLink(let path):
      path
    case .clone(_, let source):
      source
    }
  }
}

@MainActor @Observable
class PackageManager {
  private(set) var installedPackages: [InstalledPackage] = []
  private(set) var searchResults: [CatalogPackage] = []
  private(set) var isLoadingInstalled = false
  private(set) var isSearching = false
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
