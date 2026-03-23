import Foundation
import os

enum RacketEnvironment {
  private static let logger = Logger(subsystem: "com.ruckus.app", category: "racket-env")

  static let bundleRacketURL = Bundle.main.resourceURL!.appendingPathComponent("racket")

  static let writableRootURL: URL = {
    FileManager.default
      .urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
      .appendingPathComponent("racket")
  }()

  static var collectsDir: String {
    bundleRacketURL.appendingPathComponent("collects").path
  }

  static var configDir: String {
    writableRootURL.appendingPathComponent("etc").path
  }

  static func setup() throws {
    let fileManager = FileManager.default
    let writable = writableRootURL

    // Create writable directories.
    for sub in ["etc", "pkgs", "share", "doc", "lib"] {
      let dir = writable.appendingPathComponent(sub)
      try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    // Seed an empty links.rktd if it doesn't exist yet.
    let linksFile = writable.appendingPathComponent("links.rktd")
    if !fileManager.fileExists(atPath: linksFile.path) {
      try "()\n".write(to: linksFile, atomically: true, encoding: .utf8)
    }

    // Always regenerate config.rktd so paths stay correct across updates.
    let config = generateConfig(
      writable: writable.path,
      bundle: bundleRacketURL.path
    )
    let configFile = writable.appendingPathComponent("etc/config.rktd")
    try config.write(to: configFile, atomically: true, encoding: .utf8)
    logger.info("Racket environment configured at \(writable.path)")
  }

  private static func generateConfig(writable: String, bundle: String) -> String {
    """
    #hash(
      (pkgs-dir . "\(writable)/pkgs")
      (links-file . "\(writable)/links.rktd")
      (share-dir . "\(writable)/share")
      (doc-dir . "\(writable)/doc")
      (lib-dir . "\(writable)/lib")
      (pkgs-search-dirs . (#f "\(bundle)/share/pkgs"))
      (links-search-files . (#f "\(bundle)/share/links.rktd"))
      (share-search-dirs . (#f "\(bundle)/share"))
      (collects-search-dirs . (#f "\(bundle)/collects"))
      (doc-search-dirs . (#f "\(bundle)/doc"))
      (lib-search-dirs . (#f "\(bundle)/lib"))
      (default-scope . "installation")
      (installation-name . "Ruckus")
      (catalogs . (#f)))
    """
  }
}
