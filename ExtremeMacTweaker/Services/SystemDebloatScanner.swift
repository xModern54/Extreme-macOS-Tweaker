import Foundation

enum SystemDebloatScanner {
  static func scan() -> [SystemDebloatItem] {
    SystemDebloatCatalog.components.compactMap { component in
      let size = allocatedSize(of: component)
      guard size > 0 else { return nil }
      return SystemDebloatItem(component: component, sizeInBytes: size)
    }
  }

  static func allocatedSize(of component: SystemDebloatComponent) -> Int64 {
    SystemDebloatCatalog.resolvedPaths(
      for: component,
      homeDirectory: FileManager.default.homeDirectoryForCurrentUser
    ).reduce(Int64(0)) { total, path in
      total + allocatedSize(atPath: path)
    }
  }

  static func allocatedSize(ofComponentID componentID: String) -> Int64 {
    guard let component = SystemDebloatCatalog.component(withID: componentID) else { return 0 }
    return allocatedSize(of: component)
  }

  private static func allocatedSize(atPath path: String) -> Int64 {
    guard FileManager.default.fileExists(atPath: path) else { return 0 }

    let process = Process()
    let output = Pipe()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/du")
    process.arguments = ["-sk", path]
    process.standardOutput = output
    process.standardError = FileHandle.nullDevice

    do {
      try process.run()
      let data = output.fileHandleForReading.readDataToEndOfFile()
      process.waitUntilExit()
      guard process.terminationStatus == 0 else { return 0 }

      let firstField = String(decoding: data, as: UTF8.self)
        .split(whereSeparator: { $0 == " " || $0 == "\t" || $0 == "\n" })
        .first
      return (Int64(firstField ?? "") ?? 0) * 1_024
    } catch {
      return 0
    }
  }
}
