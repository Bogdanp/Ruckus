import Foundation
import os

enum RacketEnvironment {
  private static let bundleRacketURL = Bundle.main.resourceURL!.appendingPathComponent("racket")

  private static let writableRootURL: URL = {
    FileManager.default
      .urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
      .appendingPathComponent("racket")
  }()

  static let collectsDir = bundleRacketURL.appendingPathComponent("collects").path
  static let configDir = writableRootURL.appendingPathComponent("etc").path

  static func setup() throws {
    let fileManager = FileManager.default
    let writable = writableRootURL

    for sub in ["etc", "pkgs", "share", "doc", "lib"] {
      let dir = writable.appendingPathComponent(sub)
      try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    let linksFile = writable.appendingPathComponent("links.rktd")
    if !fileManager.fileExists(atPath: linksFile.path) {
      try "()\n".write(to: linksFile, atomically: true, encoding: .utf8)
    }

    let config = generateConfig(
      writable: writable.path,
      bundle: bundleRacketURL.path
    )
    let configFile = writable.appendingPathComponent("etc/config.rktd")
    let existing = try? String(contentsOf: configFile, encoding: .utf8)
    if existing != config {
      try config.write(to: configFile, atomically: true, encoding: .utf8)
      Logger.racketEnv.info("Racket environment configured at \(writable.path)")
    }
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
