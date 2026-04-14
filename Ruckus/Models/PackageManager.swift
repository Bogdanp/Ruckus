import Foundation
import UIKit
import os

@MainActor @Observable
class PackageManager {
  static let shared = PackageManager()

  private(set) var installedPackages: [InstalledPackage] = []
  private(set) var searchResults: [CatalogPackage] = []
  private(set) var isLoadingInstalled = false
  private(set) var isSearching = false
  private(set) var activeOperations: Set<String> = []
  private(set) var installSource: String?
  private(set) var installLog: NSMutableAttributedString = NSMutableAttributedString()
  private(set) var installLogVersion: UInt64 = 0
  private var installId: UInt64?
  private var installStdoutBuffer = OutputBuffer()
  private var installStderrBuffer = OutputBuffer()
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
    } catch {
      alertMessage = "Failed to load packages: \(error.localizedDescription)"
      Logger.backend.warning("loadInstalled: \(error)")
    }
    isLoadingInstalled = false
  }

  func install(source: String) async {
    activeOperations.insert(source)
    installSource = source
    installLog = NSMutableAttributedString()
    installLogVersion = 0
    installStdoutBuffer = OutputBuffer()
    installStderrBuffer = OutputBuffer()
    defer {
      activeOperations.remove(source)
      installSource = nil
      installId = nil
    }
    do {
      let id = try await Backend.shared.startInstallPackage(source)
      installId = id
      var failureMessage: String?
      for try await step in InstallStepper.shared.steps(for: id) {
        appendChunk(installStdoutBuffer.decode(step.output.stdout), stream: .stdout)
        appendChunk(installStderrBuffer.decode(step.output.stderr), stream: .stderr)
        if case .failed(_, let message) = step {
          failureMessage = message
        }
        if step.isTerminal {
          appendChunk(installStdoutBuffer.flush(), stream: .stdout)
          appendChunk(installStderrBuffer.flush(), stream: .stderr)
        }
      }
      if let failureMessage {
        alertMessage = "Failed to install \(source): \(failureMessage)"
      } else {
        await loadInstalled()
      }
    } catch is CancellationError {
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

  private enum LogStream { case stdout, stderr }

  private func appendChunk(_ text: String, stream: LogStream) {
    guard !text.isEmpty else { return }
    let color: UIColor = switch stream {
    case .stdout: .label
    case .stderr: .systemRed
    }
    let attrs: [NSAttributedString.Key: Any] = [
      .foregroundColor: color,
      .font: UIFont.monospacedSystemFont(ofSize: UIFont.smallSystemFontSize, weight: .regular)
    ]
    installLog.append(NSAttributedString(string: text, attributes: attrs))
    installLogVersion &+= 1
  }
}
