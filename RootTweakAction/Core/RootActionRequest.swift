import Foundation

enum RootActionRequest {
  case identity
  case preflight
  case mountSystemVolume(mountPath: String)
  case unmountSystemVolume(mountPath: String)
  case disableApplication(mountPath: String, sourcePath: String, destinationPath: String)
  case restoreApplication(mountPath: String, sourcePath: String, destinationPath: String)
  case deleteApplication(mountPath: String, path: String)
  case createSnapshot(mountPath: String)

  var name: String {
    switch self {
    case .identity: "identity"
    case .preflight: "preflight"
    case .mountSystemVolume: "mount-system-volume"
    case .unmountSystemVolume: "unmount-system-volume"
    case .disableApplication: "disable-application"
    case .restoreApplication: "restore-application"
    case .deleteApplication: "delete-application"
    case .createSnapshot: "create-snapshot"
    }
  }

  var startMessage: String {
    switch self {
    case .identity: "Checking privileged execution"
    case .preflight: "Checking system requirements"
    case .mountSystemVolume: "Mounting the writable system volume"
    case .unmountSystemVolume: "Unmounting the writable system volume"
    case .disableApplication(_, let source, _): "Disabling \(appName(source))"
    case .restoreApplication(_, let source, _): "Restoring \(appName(source))"
    case .deleteApplication(_, let path): "Deleting \(appName(path))"
    case .createSnapshot: "Creating a bootable system snapshot"
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
