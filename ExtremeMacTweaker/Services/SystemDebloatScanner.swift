import Foundation

enum SystemDebloatScanner {
  private struct SizeScan {
    let bytes: Int64
    let fullDiskAccessDenied: Bool
    let permissionDenied: Bool

    var sizeIsIncomplete: Bool {
      fullDiskAccessDenied || permissionDenied
    }
  }

  static func scan() -> [SystemDebloatItem] {
    SystemDebloatCatalog.components.compactMap { component in
      let scan = sizeScan(of: component)
      guard scan.bytes > 0 || scan.sizeIsIncomplete else { return nil }
      return SystemDebloatItem(
        component: component,
        sizeInBytes: scan.bytes,
        sizeIsIncomplete: scan.sizeIsIncomplete,
        requiresFullDiskAccess: scan.fullDiskAccessDenied
      )
    }
  }

  static func allocatedSize(of component: SystemDebloatComponent) -> Int64 {
    sizeScan(of: component).bytes
  }

  private static func sizeScan(of component: SystemDebloatComponent) -> SizeScan {
    SystemDebloatCatalog.resolvedPaths(
      for: component,
      homeDirectory: FileManager.default.homeDirectoryForCurrentUser
    ).reduce(
      SizeScan(bytes: 0, fullDiskAccessDenied: false, permissionDenied: false)
    ) { total, path in
      let pathScan = allocatedSize(atPath: path)
      return SizeScan(
        bytes: total.bytes + pathScan.bytes,
        fullDiskAccessDenied: total.fullDiskAccessDenied || pathScan.fullDiskAccessDenied,
        permissionDenied: total.permissionDenied || pathScan.permissionDenied
      )
    }
  }

  static func allocatedSize(ofComponentID componentID: String) -> Int64 {
    guard let component = SystemDebloatCatalog.component(withID: componentID) else { return 0 }
    return allocatedSize(of: component)
  }

  private static func allocatedSize(atPath path: String) -> SizeScan {
    guard FileManager.default.fileExists(atPath: path) else {
      return SizeScan(bytes: 0, fullDiskAccessDenied: false, permissionDenied: false)
    }

    let process = Process()
    let combinedOutput = Pipe()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/du")
    process.arguments = ["-sk", path]
    process.standardOutput = combinedOutput
    process.standardError = combinedOutput

    do {
      try process.run()
      let data = combinedOutput.fileHandleForReading.readDataToEndOfFile()
      process.waitUntilExit()
      let output = String(decoding: data, as: UTF8.self)
      guard process.terminationStatus == 0 else {
        return SizeScan(
          bytes: 0,
          fullDiskAccessDenied: output.localizedCaseInsensitiveContains(
            "operation not permitted"
          ),
          permissionDenied: output.localizedCaseInsensitiveContains("permission denied")
        )
      }

      let firstField = output
        .split(whereSeparator: { $0 == " " || $0 == "\t" || $0 == "\n" })
        .first
      return SizeScan(
        bytes: (Int64(firstField ?? "") ?? 0) * 1_024,
        fullDiskAccessDenied: false,
        permissionDenied: false
      )
    } catch {
      return SizeScan(bytes: 0, fullDiskAccessDenied: false, permissionDenied: false)
    }
  }
}
