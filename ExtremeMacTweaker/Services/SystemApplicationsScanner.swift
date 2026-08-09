import Foundation

enum SystemApplicationsScanner {
  static let applicationsDirectory = URL(
    fileURLWithPath: "/System/Applications",
    isDirectory: true
  )
  static let disabledApplicationsDirectory = applicationsDirectory
    .appendingPathComponent(".disabled", isDirectory: true)

  static func discoverApplications() throws -> [SystemApplication] {
    let installed = try discoverApplications(in: applicationsDirectory, state: .installed)
    let disabled = (try? discoverApplications(in: disabledApplicationsDirectory, state: .disabled)) ?? []
    return (installed + disabled)
      .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
  }

  private static func discoverApplications(
    in directory: URL,
    state: SystemApplicationState
  ) throws -> [SystemApplication] {
    let fileManager = FileManager.default
    let urls = try fileManager.contentsOfDirectory(
      at: directory,
      includingPropertiesForKeys: [.isDirectoryKey, .isPackageKey],
      options: [.skipsHiddenFiles]
    )

    return urls.compactMap { url in
      guard
        url.pathExtension.caseInsensitiveCompare("app") == .orderedSame,
        (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
      else {
        return nil
      }

      let bundle = Bundle(url: url)
      let name =
        bundle?.localizedInfoDictionary?["CFBundleDisplayName"] as? String
        ?? bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? url.deletingPathExtension().lastPathComponent

      return SystemApplication(
        url: url,
        name: name,
        bundleIdentifier: bundle?.bundleIdentifier,
        state: state,
        sizeInBytes: nil
      )
    }
  }

  static func allocatedSize(of applicationURL: URL) -> Int64? {
    let fileManager = FileManager.default
    let keys: [URLResourceKey] = [
      .isRegularFileKey,
      .fileAllocatedSizeKey,
      .totalFileAllocatedSizeKey,
      .fileSizeKey,
    ]

    guard
      let enumerator = fileManager.enumerator(
        at: applicationURL,
        includingPropertiesForKeys: keys,
        options: [],
        errorHandler: { _, _ in true }
      )
    else {
      return nil
    }

    var total: Int64 = 0

    for case let fileURL as URL in enumerator {
      guard
        let values = try? fileURL.resourceValues(forKeys: Set(keys)),
        values.isRegularFile == true
      else {
        continue
      }

      let size =
        values.totalFileAllocatedSize
        ?? values.fileAllocatedSize
        ?? values.fileSize
        ?? 0
      total += Int64(size)
    }

    return total
  }
}
