import Foundation

enum SystemVolume {
  static let allowedMountPath = "/Volumes/SystemRW"
  static let applicationsDirectory = "/System/Applications"
  static let disabledApplicationsDirectory = "/System/Library/TweakerDisabledApplications"
  static let legacyDisabledApplicationsDirectory = "/System/Applications/.disabled"
  static let dequarantineBinaryPath = "/usr/libexec/dqd"
  static let legacyDequarantineBinaryPath = "/usr/libexec/extrememactweaker.dequarantine"
  static let dequarantinePlistPath =
    "/System/Library/LaunchDaemons/com.extrememactweaker.dequarantine.plist"
  static let cleanSweepDirectory = "/System/Library/CleanSweep"
  static let launchDaemonsDirectory = "/System/Library/LaunchDaemons"
  static let launchAgentsDirectory = "/System/Library/LaunchAgents"
  static let hiddenLaunchDaemonsDirectory = cleanSweepDirectory + "/LaunchDaemons"
  static let hiddenLaunchAgentsDirectory = cleanSweepDirectory + "/LaunchAgents"

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
    guard
      parent == applicationsDirectory
        || parent == disabledApplicationsDirectory
        || parent == legacyDisabledApplicationsDirectory
    else {
      throw RootActionError.invalidArguments(
        "Application path is outside the allowed system application locations: \(systemPath)"
      )
    }
    return standardized
  }

  static func mountedDisabledApplicationsDirectory(root mountPath: String) throws -> String {
    try mountedAllowedPath(root: mountPath, systemPath: disabledApplicationsDirectory)
  }

  static func mountedLegacyDisabledApplicationsDirectory(root mountPath: String) throws -> String {
    try mountedAllowedPath(root: mountPath, systemPath: legacyDisabledApplicationsDirectory)
  }

  static func mountedPath(root mountPath: String, systemPath: String) throws -> String {
    try mountedAllowedPath(
      root: mountPath,
      systemPath: try validatedApplicationPath(systemPath)
    )
  }

  static func validatedLaunchPlistPath(_ systemPath: String) throws -> String {
    try validatedSweepPath(systemPath)
  }

  static func validatedSweepPath(_ systemPath: String) throws -> String {
    let standardized = standardizedPath(systemPath)
    guard isAllowedSweepPath(standardized) else {
      throw RootActionError.invalidArguments(
        "Path is outside the allowed Clean Sweep locations: \(systemPath)"
      )
    }
    return standardized
  }

  static func mountedLaunchPlistPath(root mountPath: String, systemPath: String) throws -> String {
    try mountedAllowedPath(
      root: mountPath,
      systemPath: try validatedSweepPath(systemPath)
    )
  }

  static func isAllowedSweepPath(_ systemPath: String) -> Bool {
    let url = URL(fileURLWithPath: systemPath)
    let parent = url.deletingLastPathComponent().path

    if url.pathExtension.caseInsensitiveCompare("plist") == .orderedSame {
      return parent == launchDaemonsDirectory
        || parent == launchAgentsDirectory
        || parent == hiddenLaunchDaemonsDirectory
        || parent == hiddenLaunchAgentsDirectory
    }

    if url.pathExtension.caseInsensitiveCompare("xpc") == .orderedSame,
      url.deletingLastPathComponent().lastPathComponent == "XPCServices"
    {
      if systemPath.hasPrefix("/System/Library/"),
        !systemPath.hasPrefix(cleanSweepDirectory + "/")
      {
        return true
      }
      let hiddenPrefix = cleanSweepDirectory + "/Library/"
      return systemPath.hasPrefix(hiddenPrefix)
    }

    return false
  }

  static func mountedDequarantinePath(
    root mountPath: String,
    systemPath: String
  ) throws -> String {
    let standardized = standardizedPath(systemPath)
    guard
      standardized == dequarantineBinaryPath
        || standardized == legacyDequarantineBinaryPath
        || standardized == dequarantinePlistPath
    else {
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
