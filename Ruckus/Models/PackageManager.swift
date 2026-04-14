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
  private(set) var installLog: String = ""
  private(set) var installingSource: String?
  private var installId: UInt64?
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
    installingSource = source
    installLog = ""
    defer {
      activeOperations.remove(source)
      installingSource = nil
      installId = nil
    }
    do {
      let id = try await Backend.shared.startInstallPackage(source)
      installId = id
      var failureMessage: String?
      for try await step in InstallStepper.shared.steps(for: id) {
        appendOutput(step.output)
        if case .failed(_, let message) = step {
          failureMessage = message
        }
      }
      if let failureMessage {
        throw InstallError.failed(failureMessage)
      }
      await loadInstalled()
    } catch is CancellationError {
      // User cancelled — not an error.
    } catch {
      alertMessage = "Failed to install \(source): \(error.localizedDescription)"
      Logger.backend.warning("installPackage: \(error)")
    }
  }

  func cancelInstall() async {
    guard let id = installId else { return }
    do {
      try await Backend.shared.stopInstall(id)
    } catch {
      Logger.backend.warning("stopInstall: \(error)")
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

  func removeOrphans() async {
    activeOperations.insert("__orphans__")
    defer { activeOperations.remove("__orphans__") }
    do {
      try await Backend.shared.removeOrphanedPackages()
      await loadInstalled()
    } catch {
      alertMessage = "Failed to clean orphaned packages: \(error.localizedDescription)"
      Logger.backend.warning("removeOrphanedPackages: \(error)")
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

  private func appendOutput(_ output: InstallOutput) {
    if !output.stdout.isEmpty, let chunk = String(data: output.stdout, encoding: .utf8) {
      installLog += chunk
    }
    if !output.stderr.isEmpty, let chunk = String(data: output.stderr, encoding: .utf8) {
      installLog += chunk
    }
  }
}

enum InstallError: LocalizedError {
  case failed(String)

  var errorDescription: String? {
    switch self {
    case .failed(let message): return message
    }
  }
}
