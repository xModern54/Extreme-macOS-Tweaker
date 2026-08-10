import Foundation

enum SystemVolume {
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

  static func mountedPath(root mountPath: String, systemPath: String) -> String {
    let relativePath = systemPath.hasPrefix("/") ? String(systemPath.dropFirst()) : systemPath
    return URL(fileURLWithPath: mountPath, isDirectory: true)
      .appendingPathComponent(relativePath).path
  }
}
