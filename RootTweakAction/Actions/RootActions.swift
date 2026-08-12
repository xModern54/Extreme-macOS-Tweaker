import Darwin
import Foundation

struct RootActionContext {
  let events: EventWriter
  let commands: CommandRunner
}

enum RootActions {
  static func execute(_ request: RootActionRequest, context: RootActionContext) throws -> (String, Bool, [String: String]) {
    switch request {
    case .identity:
      return (
        "Privileged execution is working",
        false,
        [
          "uid": String(getuid()),
          "effectiveUID": String(geteuid()),
          "pid": String(getpid()),
        ]
      )

    case .preflight:
      return try preflight(context)

    case .checkSystemIntegrityProtection:
      return try checkSystemIntegrityProtection(context)

    case .mountSystemVolume(let mountPath):
      return try mountSystemVolume(mountPath, context)

    case .unmountSystemVolume(let mountPath):
      return try unmountSystemVolume(mountPath, context)

    case .disableApplication(let mountPath, let source, let destination):
      return try moveApplication(
        action: "disabled",
        mountPath: mountPath,
        sourcePath: source,
        destinationPath: destination,
        context: context
      )

    case .restoreApplication(let mountPath, let source, let destination):
      return try moveApplication(
        action: "restored",
        mountPath: mountPath,
        sourcePath: source,
        destinationPath: destination,
        context: context
      )

    case .deleteApplication(let mountPath, let path):
      return try deleteApplication(mountPath: mountPath, path: path, context: context)

    case .createSnapshot(let mountPath):
      return try createSnapshot(mountPath, context)

    case .setLaunchService(let label, let domain, let userID, let enabled):
      return try setLaunchService(
        label: label,
        domain: domain,
        userID: userID,
        enabled: enabled,
        context: context
      )

    case .removeSystemComponent(let id):
      return try removeSystemComponent(id: id, context: context)

    case .setSecurityProtection(let id, let userID, let enabled):
      return try setSecurityProtection(
        id: id,
        userID: userID,
        enabled: enabled,
        context: context
      )

    case .restartSystem:
      return try restartSystem(context)
    }
  }

  private static func setSecurityProtection(
    id: String,
    userID: uid_t,
    enabled: Bool,
    context: RootActionContext
  ) throws -> (String, Bool, [String: String]) {
    guard let protection = SecurityProtectionCatalog.protection(withID: id) else {
      throw RootActionError.invalidArguments("Unknown security protection: \(id)")
    }

    switch protection.kind {
    case .gatekeeper:
      context.events.progress(0.35, "Updating the global Gatekeeper policy")
      _ = try context.commands.requireSuccess(
        "/usr/sbin/spctl",
        [enabled ? "--global-enable" : "--global-disable"]
      )

      context.events.progress(0.75, "Verifying the Gatekeeper policy")
      let status = try context.commands.run("/usr/sbin/spctl", ["--status"])
      guard status.exitCode == 0 || status.exitCode == 1 else {
        throw RootActionError.commandFailed(status)
      }
      let isEnabled = status.standardOutput.localizedCaseInsensitiveContains("enabled")
      if !enabled, isEnabled {
        return (
          "Confirm Allow applications from anywhere in Privacy & Security",
          true,
          [
            "protectionID": protection.id,
            "enabled": "false",
            "requiresConfirmation": "true",
          ]
        )
      }
      guard isEnabled == enabled else {
        throw RootActionError.operationFailed(
          code: "gatekeeper_verification_failed",
          message: "Gatekeeper did not change to the requested state."
        )
      }
      return (
        "Gatekeeper was \(enabled ? "enabled" : "disabled")",
        true,
        [
          "protectionID": protection.id,
          "enabled": String(enabled),
          "requiresConfirmation": "false",
        ]
      )

    case .launchServices:
      var changed = false
      for (index, service) in protection.services.enumerated() {
        context.events.progress(
          0.1 + 0.8 * Double(index) / Double(max(protection.services.count, 1)),
          "\(enabled ? "Enabling" : "Disabling") \(service.label)"
        )
        let domain: RootActionRequest.LaunchServiceDomain = switch service.domain {
        case .system: .system
        case .user: .user
        case .gui: .gui
        }
        let result = try setLaunchService(
          label: service.label,
          domain: domain,
          userID: userID,
          enabled: enabled,
          context: context,
          reportsProgress: false
        )
        changed = changed || result.1

        if enabled,
          let plistPath = service.launchdPlistPath,
          FileManager.default.fileExists(atPath: plistPath)
        {
          let domainTarget = switch domain {
          case .system: "system"
          case .user: "user/\(userID)"
          case .gui: "gui/\(userID)"
          }
          let serviceTarget = "\(domainTarget)/\(service.label)"
          let state = try context.commands.run("/bin/launchctl", ["print", serviceTarget])
          if state.exitCode != 0 {
            _ = try context.commands.requireSuccess(
              "/bin/launchctl",
              ["bootstrap", domainTarget, plistPath]
            )
            changed = true
          }
        }
      }
      return (
        "\(protection.title) was \(enabled ? "enabled" : "disabled")",
        changed,
        [
          "protectionID": protection.id,
          "enabled": String(enabled),
          "services": String(protection.services.count),
        ]
      )
    }
  }

  private static func removeSystemComponent(
    id: String,
    context: RootActionContext
  ) throws -> (String, Bool, [String: String]) {
    guard let component = SystemDebloatCatalog.component(withID: id) else {
      throw RootActionError.invalidArguments("Unknown system component: \(id)")
    }
    guard component.paths.allSatisfy(SystemDebloatCatalog.isAllowedAssetPath) else {
      throw RootActionError.operationFailed(
        code: "unsafe_component_path",
        message: "The component catalog contains a path outside the allowed asset root."
      )
    }

    let existingPaths = component.paths.filter {
      FileManager.default.fileExists(atPath: $0)
    }
    guard !existingPaths.isEmpty else {
      return (
        "\(component.title) is already absent",
        false,
        ["componentID": component.id, "removedPaths": "0"]
      )
    }

    for (index, path) in existingPaths.enumerated() {
      let fraction = 0.15 + 0.7 * Double(index) / Double(max(existingPaths.count, 1))
      context.events.progress(fraction, "Removing \(URL(fileURLWithPath: path).lastPathComponent)")
      _ = try context.commands.requireSuccess("/bin/rm", ["-rf", "--", path])
      guard !FileManager.default.fileExists(atPath: path) else {
        throw RootActionError.operationFailed(
          code: "deletion_verification_failed",
          message: "A component asset still exists after the delete operation."
        )
      }
    }

    return (
      "\(component.title) was removed",
      true,
      [
        "componentID": component.id,
        "removedPaths": String(existingPaths.count),
      ]
    )
  }

  private static func restartSystem(
    _ context: RootActionContext
  ) throws -> (String, Bool, [String: String]) {
    context.events.progress(0.4, "Requesting a clean system restart")
    _ = try context.commands.requireSuccess("/sbin/shutdown", ["-r", "now"])
    return ("System restart was requested", true, [:])
  }

  private static func checkSystemIntegrityProtection(
    _ context: RootActionContext
  ) throws -> (String, Bool, [String: String]) {
    context.events.progress(0.5, "Checking System Integrity Protection")
    let sip = try context.commands.requireSuccess("/usr/bin/csrutil", ["status"])
    guard sip.standardOutput.localizedCaseInsensitiveContains("disabled") else {
      throw RootActionError.prerequisitesNotMet(
        "System Integrity Protection must be disabled from macOS Recovery."
      )
    }
    return ("System Integrity Protection is disabled", false, [:])
  }

  private static func setLaunchService(
    label: String,
    domain: RootActionRequest.LaunchServiceDomain,
    userID: uid_t,
    enabled: Bool,
    context: RootActionContext,
    reportsProgress: Bool = true
  ) throws -> (String, Bool, [String: String]) {
    let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._-"))
    guard
      !label.isEmpty,
      label.count <= 255,
      label.unicodeScalars.allSatisfy(allowedCharacters.contains)
    else {
      throw RootActionError.invalidArguments("Invalid launch service label: \(label)")
    }

    let domainTarget = switch domain {
    case .system: "system"
    case .user: "user/\(userID)"
    case .gui: "gui/\(userID)"
    }
    let serviceTarget = "\(domainTarget)/\(label)"
    let launchctl = "/bin/launchctl"

    if reportsProgress {
      context.events.progress(0.2, "Checking the current launchd override")
    }
    let disabledServices = try context.commands.requireSuccess(
      launchctl, ["print-disabled", domainTarget]
    )
    let wasDisabled = disabledOverride(for: label, in: disabledServices.standardOutput)
    let shouldDisable = !enabled

    if reportsProgress {
      context.events.progress(0.5, "Updating the persistent launchd override")
    }
    _ = try context.commands.requireSuccess(
      launchctl, [enabled ? "enable" : "disable", serviceTarget]
    )

    var wasLoaded = false
    if shouldDisable {
      let serviceState = try context.commands.run(launchctl, ["print", serviceTarget])
      wasLoaded = serviceState.exitCode == 0
      if wasLoaded {
        if reportsProgress {
          context.events.progress(0.8, "Stopping the running launchd service")
        }
        _ = try context.commands.requireSuccess(launchctl, ["bootout", serviceTarget])
      }
    }

    let changed = wasDisabled != shouldDisable || wasLoaded
    return (
      "Launch service was \(enabled ? "enabled" : "disabled")",
      changed,
      [
        "label": label,
        "domain": domain.rawValue,
        "serviceTarget": serviceTarget,
        "enabled": String(enabled),
        "stopped": String(wasLoaded),
      ]
    )
  }

  private static func disabledOverride(for label: String, in output: String) -> Bool {
    let quotedLabel = "\"\(label)\""
    return output.split(separator: "\n").contains { line in
      line.contains(quotedLabel)
        && (line.contains("=> disabled") || line.contains("=> true"))
    }
  }

  private static func preflight(_ context: RootActionContext) throws -> (String, Bool, [String: String]) {
    context.events.progress(0.25, "Checking System Integrity Protection")
    let sip = try context.commands.requireSuccess("/usr/bin/csrutil", ["status"])
    context.events.progress(0.55, "Checking Authenticated Root")
    let authenticatedRoot = try context.commands.requireSuccess(
      "/usr/bin/csrutil", ["authenticated-root", "status"]
    )

    guard sip.standardOutput.localizedCaseInsensitiveContains("disabled") else {
      throw RootActionError.prerequisitesNotMet(
        "System Integrity Protection must be disabled from macOS Recovery."
      )
    }
    guard authenticatedRoot.standardOutput.localizedCaseInsensitiveContains("disabled") else {
      throw RootActionError.prerequisitesNotMet(
        "Authenticated Root must be disabled from macOS Recovery."
      )
    }

    context.events.progress(0.8, "Locating the base system volume")
    let device = try SystemVolume.baseDevice(using: context.commands)
    return (
      "System requirements are satisfied",
      false,
      ["systemDevice": device]
    )
  }

  private static func mountSystemVolume(
    _ mountPath: String,
    _ context: RootActionContext
  ) throws -> (String, Bool, [String: String]) {
    context.events.progress(0.15, "Locating the base system volume")
    let device = try SystemVolume.baseDevice(using: context.commands)

    let mounts = try context.commands.requireSuccess("/sbin/mount", [])
    if mounts.standardOutput.contains(" on \(mountPath) ") {
      return (
        "System volume is already mounted",
        false,
        ["mountPath": mountPath, "systemDevice": device]
      )
    }

    context.events.progress(0.4, "Creating the mount point")
    _ = try context.commands.requireSuccess("/bin/mkdir", ["-p", mountPath])

    context.events.progress(0.65, "Mounting \(device)")
    _ = try context.commands.requireSuccess(
      "/sbin/mount",
      ["-t", "apfs", "-o", "nobrowse", device, mountPath]
    )

    return (
      "Writable system volume was mounted",
      true,
      ["mountPath": mountPath, "systemDevice": device]
    )
  }

  private static func unmountSystemVolume(
    _ mountPath: String,
    _ context: RootActionContext
  ) throws -> (String, Bool, [String: String]) {
    let mounts = try context.commands.requireSuccess("/sbin/mount", [])
    guard mounts.standardOutput.contains(" on \(mountPath) ") else {
      return ("System volume is already unmounted", false, ["mountPath": mountPath])
    }

    context.events.progress(0.5, "Unmounting the system volume")
    _ = try context.commands.requireSuccess("/sbin/umount", [mountPath])
    return ("System volume was unmounted", true, ["mountPath": mountPath])
  }

  private static func moveApplication(
    action: String,
    mountPath: String,
    sourcePath: String,
    destinationPath: String,
    context: RootActionContext
  ) throws -> (String, Bool, [String: String]) {
    let source = SystemVolume.mountedPath(root: mountPath, systemPath: sourcePath)
    let destination = SystemVolume.mountedPath(root: mountPath, systemPath: destinationPath)
    let fileManager = FileManager.default

    if !fileManager.fileExists(atPath: source), fileManager.fileExists(atPath: destination) {
      return ("Application is already \(action)", false, ["path": destinationPath])
    }
    guard fileManager.fileExists(atPath: source) else {
      throw RootActionError.operationFailed(
        code: "application_not_found",
        message: "Application does not exist at \(sourcePath)."
      )
    }
    guard !fileManager.fileExists(atPath: destination) else {
      throw RootActionError.operationFailed(
        code: "destination_exists",
        message: "Destination already exists at \(destinationPath)."
      )
    }

    context.events.progress(0.3, "Preparing the destination directory")
    let destinationDirectory = URL(fileURLWithPath: destination).deletingLastPathComponent().path
    _ = try context.commands.requireSuccess("/bin/mkdir", ["-p", destinationDirectory])

    context.events.progress(0.65, "Moving the application")
    _ = try context.commands.requireSuccess("/bin/mv", [source, destination])
    return ("Application was \(action)", true, ["path": destinationPath])
  }

  private static func deleteApplication(
    mountPath: String,
    path: String,
    context: RootActionContext
  ) throws -> (String, Bool, [String: String]) {
    let mountedPath = SystemVolume.mountedPath(root: mountPath, systemPath: path)
    guard FileManager.default.fileExists(atPath: mountedPath) else {
      return ("Application is already absent", false, ["path": path])
    }

    context.events.progress(0.5, "Removing the application from the system volume")
    _ = try context.commands.requireSuccess("/bin/rm", ["-rf", "--", mountedPath])
    guard !FileManager.default.fileExists(atPath: mountedPath) else {
      throw RootActionError.operationFailed(
        code: "deletion_verification_failed",
        message: "Application still exists after the delete operation."
      )
    }
    return ("Application was deleted", true, ["path": path])
  }

  private static func createSnapshot(
    _ mountPath: String,
    _ context: RootActionContext
  ) throws -> (String, Bool, [String: String]) {
    context.events.progress(0.35, "Asking bless to create a bootable snapshot")
    let output = try context.commands.requireSuccess(
      "/usr/sbin/bless",
      ["--mount", mountPath, "--create-snapshot"]
    )
    return (
      "Bootable system snapshot was created",
      true,
      ["blessOutput": output.standardOutput]
    )
  }
}
