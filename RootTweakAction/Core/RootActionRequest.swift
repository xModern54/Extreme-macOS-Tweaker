import Foundation

enum RootActionRequest {
  enum LaunchServiceDomain: String {
    case system
    case user
    case gui
  }

  case identity
  case preflight
  case checkSystemIntegrityProtection
  case mountSystemVolume(mountPath: String)
  case unmountSystemVolume(mountPath: String)
  case disableApplication(mountPath: String, sourcePath: String, destinationPath: String)
  case restoreApplication(mountPath: String, sourcePath: String, destinationPath: String)
  case deleteApplication(mountPath: String, path: String)
  case createSnapshot(mountPath: String)
  case setLaunchService(
    label: String,
    domain: LaunchServiceDomain,
    userID: uid_t,
    enabled: Bool
  )
  case removeSystemComponent(id: String)
  case setSecurityProtection(id: String, userID: uid_t, enabled: Bool)
  case installSystemDequarantine(mountPath: String, downloadsPath: String)
  case removeSystemDequarantine(mountPath: String)
  case restartSystem(userID: uid_t, appPath: String?)

  var name: String {
    switch self {
    case .identity: "identity"
    case .preflight: "preflight"
    case .checkSystemIntegrityProtection: "check-system-integrity-protection"
    case .mountSystemVolume: "mount-system-volume"
    case .unmountSystemVolume: "unmount-system-volume"
    case .disableApplication: "disable-application"
    case .restoreApplication: "restore-application"
    case .deleteApplication: "delete-application"
    case .createSnapshot: "create-snapshot"
    case .setLaunchService: "set-launch-service"
    case .removeSystemComponent: "remove-system-component"
    case .setSecurityProtection: "set-security-protection"
    case .installSystemDequarantine: "install-system-dequarantine"
    case .removeSystemDequarantine: "remove-system-dequarantine"
    case .restartSystem: "restart-system"
    }
  }

  var startMessage: String {
    switch self {
    case .identity: "Checking privileged execution"
    case .preflight: "Checking system requirements"
    case .checkSystemIntegrityProtection: "Checking System Integrity Protection"
    case .mountSystemVolume: "Mounting the writable system volume"
    case .unmountSystemVolume: "Unmounting the writable system volume"
    case .disableApplication(_, let source, _): "Disabling \(appName(source))"
    case .restoreApplication(_, let source, _): "Restoring \(appName(source))"
    case .deleteApplication(_, let path): "Deleting \(appName(path))"
    case .createSnapshot: "Creating a bootable system snapshot"
    case .setLaunchService(let label, _, _, let enabled):
      "\(enabled ? "Enabling" : "Disabling") service \(label)"
    case .removeSystemComponent(let id):
      "Removing \(SystemDebloatCatalog.component(withID: id)?.title ?? "system component")"
    case .setSecurityProtection(let id, _, let enabled):
      "\(enabled ? "Enabling" : "Disabling") "
        + (SecurityProtectionCatalog.protection(withID: id)?.title ?? "security protection")
    case .installSystemDequarantine:
      "Installing the system dequarantine daemon"
    case .removeSystemDequarantine:
      "Removing the system dequarantine daemon"
    case .restartSystem: "Restarting macOS"
    }
  }

  static func parse(_ arguments: [String]) throws -> RootActionRequest {
    guard let command = arguments.first else {
      throw RootActionError.invalidArguments("No action was specified.")
    }

    let options = try parseOptions(Array(arguments.dropFirst()))
    switch command {
    case "identity": return .identity
    case "preflight": return .preflight
    case "check-system-integrity-protection": return .checkSystemIntegrityProtection
    case "mount-system-volume":
      return .mountSystemVolume(mountPath: options["mount-path"] ?? "/Volumes/SystemRW")
    case "unmount-system-volume":
      return .unmountSystemVolume(mountPath: try required("mount-path", in: options))
    case "disable-application":
      return .disableApplication(
        mountPath: try required("mount-path", in: options),
        sourcePath: try required("source", in: options),
        destinationPath: try required("destination", in: options)
      )
    case "restore-application":
      return .restoreApplication(
        mountPath: try required("mount-path", in: options),
        sourcePath: try required("source", in: options),
        destinationPath: try required("destination", in: options)
      )
    case "delete-application":
      return .deleteApplication(
        mountPath: try required("mount-path", in: options),
        path: try required("path", in: options)
      )
    case "create-snapshot":
      return .createSnapshot(mountPath: try required("mount-path", in: options))
    case "set-launch-service":
      let domainValue = try required("domain", in: options)
      guard let domain = LaunchServiceDomain(rawValue: domainValue) else {
        throw RootActionError.invalidArguments("Invalid launch service domain: \(domainValue)")
      }
      let userIDValue = try required("user-id", in: options)
      guard let userID = uid_t(userIDValue) else {
        throw RootActionError.invalidArguments("Invalid user ID: \(userIDValue)")
      }
      let enabledValue = try required("enabled", in: options)
      guard let enabled = Bool(enabledValue) else {
        throw RootActionError.invalidArguments("Invalid enabled value: \(enabledValue)")
      }
      return .setLaunchService(
        label: try required("label", in: options),
        domain: domain,
        userID: userID,
        enabled: enabled
      )
    case "remove-system-component":
      return .removeSystemComponent(id: try required("id", in: options))
    case "set-security-protection":
      let userIDValue = try required("user-id", in: options)
      guard let userID = uid_t(userIDValue) else {
        throw RootActionError.invalidArguments("Invalid user ID: \(userIDValue)")
      }
      let enabledValue = try required("enabled", in: options)
      guard let enabled = Bool(enabledValue) else {
        throw RootActionError.invalidArguments("Invalid enabled value: \(enabledValue)")
      }
      return .setSecurityProtection(
        id: try required("id", in: options),
        userID: userID,
        enabled: enabled
      )
    case "install-system-dequarantine":
      return .installSystemDequarantine(
        mountPath: try required("mount-path", in: options),
        downloadsPath: try required("downloads", in: options)
      )
    case "remove-system-dequarantine":
      return .removeSystemDequarantine(mountPath: try required("mount-path", in: options))
    case "restart-system":
      let userIDValue = try required("user-id", in: options)
      guard let userID = uid_t(userIDValue) else {
        throw RootActionError.invalidArguments("Invalid user ID: \(userIDValue)")
      }
      return .restartSystem(userID: userID, appPath: options["app-path"])
    default:
      throw RootActionError.invalidArguments("Unknown action: \(command)")
    }
  }

  private static func parseOptions(_ arguments: [String]) throws -> [String: String] {
    guard arguments.count.isMultiple(of: 2) else {
      throw RootActionError.invalidArguments("Every option must have a value.")
    }

    var options: [String: String] = [:]
    var index = 0
    while index < arguments.count {
      let option = arguments[index]
      guard option.hasPrefix("--") else {
        throw RootActionError.invalidArguments("Invalid option: \(option)")
      }
      options[String(option.dropFirst(2))] = arguments[index + 1]
      index += 2
    }
    return options
  }

  private static func required(_ name: String, in options: [String: String]) throws -> String {
    guard let value = options[name], !value.isEmpty else {
      throw RootActionError.invalidArguments("Missing --\(name) option.")
    }
    return value
  }

  private func appName(_ path: String) -> String {
    URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
  }
}
