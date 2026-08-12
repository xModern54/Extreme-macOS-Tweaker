@preconcurrency import AppKit
import Foundation

final class IconCache: @unchecked Sendable {
  static let shared = IconCache()

  private let applicationIcons = NSCache<NSString, NSImage>()
  private let systemSymbols = NSCache<NSString, NSImage>()

  private init() {
    applicationIcons.countLimit = 256
    systemSymbols.countLimit = 256
  }

  func cachedApplicationIcon(forPath path: String) -> NSImage? {
    applicationIcons.object(forKey: path as NSString)
  }

  func cachedSystemSymbol(named name: String) -> NSImage? {
    systemSymbols.object(forKey: name as NSString)
  }

  func preloadApplicationIcons(forPaths paths: [String]) async {
    await Task.detached(priority: .userInitiated) { [self] in
      for path in paths where applicationIcons.object(forKey: path as NSString) == nil {
        guard !Task.isCancelled else { return }

        let icon = NSWorkspace.shared.icon(forFile: path)
        icon.cacheMode = .always
        applicationIcons.setObject(icon, forKey: path as NSString)
      }
    }.value
  }

  func preloadSystemSymbols(named names: [String]) async {
    await Task.detached(priority: .userInitiated) { [self] in
      for name in names where systemSymbols.object(forKey: name as NSString) == nil {
        guard !Task.isCancelled else { return }

        if let image = NSImage(systemSymbolName: name, accessibilityDescription: nil) {
          image.cacheMode = .always
          systemSymbols.setObject(image, forKey: name as NSString)
        }
      }
    }.value
  }
}
