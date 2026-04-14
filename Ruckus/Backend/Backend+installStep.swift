import NoiseBackend

extension Backend {
  private static let installStepReady: Future<String, Void> = {
    Backend.shared.installCallback(onInstallStep: { installId in
      Task { @MainActor in
        InstallStepper.shared.notify(installId: installId)
      }
    }).andThen { _ in
      Backend.shared.markOnInstallStepInstalled()
    }
  }()

  static func ensureInstallStepInstalled() async throws {
    try await FutureUtil.asyncify(installStepReady)
  }
}
