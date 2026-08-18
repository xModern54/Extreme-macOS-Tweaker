import Foundation

enum SystemVolume {
  static let allowedMountPath = "/Volumes/SystemRW"
  static let applicationsDirectory = "/System/Applications"
  static let disabledApplicationsDirectory = "/System/Applications/.disabled"
  static let dequarantineBinaryPath = "/usr/libexec/extrememactweaker.dequarantine"
  static let dequarantinePlistPath =
    "/System/Library/LaunchDaemons/com.extrememactweaker.dequarantine.plist"

  static func baseDevice(using commands: CommandRunner) throws -> String {
    let output = try commands.requireSuccess("/usr/sbin/diskutil", ["info", "-plist", "/"])
    let propertyList = try PropertyListSerialization.propertyList(
      from: output.standardOutputData,
      options: [],
      format: nil
    )

    guard
      let information = propertyList as? [String: Any],
      let identifier = information["DeviceIdentifier"] as? String
    else {
      throw RootActionError.operationFailed(
        code: "system_volume_not_found",
        message: "Unable to determine the current system volume."
      )
    }

    let isSnapshot = information["APFSSnapshot"] as? Bool == true
    if isSnapshot,
       let range = identifier.range(of: #"s[0-9]+$"#, options: .regularExpression) {
      return "/dev/" + identifier.replacingCharacters(in: range, with: "")
    }
    return "/dev/" + identifier
  }

  static func validatedMountPath(_ mountPath: String) throws -> String {
    let standardized = standardizedPath(mountPath)
    guard standardized == allowedMountPath else {
      throw RootActionError.invalidArguments("Mount path must be \(allowedMountPath).")
    }
    return standardized
  }

  static func validatedApplicationPath(_ systemPath: String) throws -> String {
    let standardized = standardizedPath(systemPath)
    let url = URL(fileURLWithPath: standardized)
    guard url.pathExtension.caseInsensitiveCompare("app") == .orderedSame else {
      throw RootActionError.invalidArguments("Path must be an application bundle: \(systemPath)")
    }

    let parent = url.deletingLastPathComponent().path
    guard parent == applicationsDirectory || parent == disabledApplicationsDirectory else {
      throw RootActionError.invalidArguments(
        "Application path is outside /System/Applications: \(systemPath)"
      )
    }
    return standardized
  }

  static func mountedPath(root mountPath: String, systemPath: String) throws -> String {
    try mountedAllowedPath(
      root: mountPath,
      systemPath: try validatedApplicationPath(systemPath)
    )
  }

  static func mountedDequarantinePath(
    root mountPath: String,
    systemPath: String
  ) throws -> String {
    let standardized = standardizedPath(systemPath)
    guard standardized == dequarantineBinaryPath || standardized == dequarantinePlistPath else {
      throw RootActionError.invalidArguments(
        "Path is outside the allowed dequarantine locations: \(systemPath)"
      )
    }
    return try mountedAllowedPath(root: mountPath, systemPath: standardized)
  }

  static func validatedDownloadsPath(_ path: String) throws -> String {
    let standardized = standardizedPath(path)
    let parts = standardized.split(separator: "/", omittingEmptySubsequences: true)
    guard parts.count == 3, parts[0] == "Users", parts[2] == "Downloads" else {
      throw RootActionError.invalidArguments("Downloads path must be /Users/<name>/Downloads.")
    }
    return standardized
  }

  private static func mountedAllowedPath(root mountPath: String, systemPath: String) throws -> String {
    let mount = try validatedMountPath(mountPath)
    let relativePath = String(systemPath.dropFirst())
    let mounted = URL(fileURLWithPath: mount, isDirectory: true)
      .appendingPathComponent(relativePath)
      .standardizedFileURL
      .path
    guard mounted.hasPrefix(mount + "/") else {
      throw RootActionError.invalidArguments("Resolved path escaped the mount point.")
    }
    return mounted
  }

  private static func standardizedPath(_ path: String) -> String {
    URL(fileURLWithPath: path).standardizedFileURL.path
  }
}
