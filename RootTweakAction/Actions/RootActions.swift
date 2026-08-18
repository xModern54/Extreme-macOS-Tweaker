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

    case .restartSystem(let userID, let appPath):
      return try restartSystem(userID: userID, appPath: appPath, context)
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

      if protection.id == "system-policy" {
        context.events.progress(
          0.92,
          enabled
            ? "Restoring LaunchServices quarantine"
            : "Disabling LaunchServices quarantine"
        )
        try configureUnknownAppProtectionSupport(
          enabled: enabled,
          userID: userID,
          context: context
        )
        changed = true
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

  private static let dequarantineAgentLabel = "com.extrememactweaker.dequarantine"

  private static func configureUnknownAppProtectionSupport(
    enabled: Bool,
    userID: uid_t,
    context: RootActionContext
  ) throws {
    let defaults = "/usr/bin/defaults"
    _ = try context.commands.run(
      "/bin/launchctl",
      [
        "asuser", String(userID), defaults, "write", "com.apple.LaunchServices",
        "LSQuarantine", "-bool", enabled ? "YES" : "NO",
      ]
    )

    guard let home = homeDirectory(for: userID) else {
      throw RootActionError.operationFailed(
        code: "user_home_not_found",
        message: "Unable to locate the user home directory."
      )
    }

    let agentPlist = home
      .appendingPathComponent("Library/LaunchAgents")
      .appendingPathComponent("\(dequarantineAgentLabel).plist")
    let guiTarget = "gui/\(userID)"
    let serviceTarget = "\(guiTarget)/\(dequarantineAgentLabel)"

    _ = try context.commands.run("/bin/launchctl", ["bootout", serviceTarget])

    if enabled {
      try? FileManager.default.removeItem(at: agentPlist)
      return
    }

    let downloads = home.appendingPathComponent("Downloads")
    try FileManager.default.createDirectory(at: downloads, withIntermediateDirectories: true)

    context.events.progress(0.94, "Clearing quarantine on existing Downloads")
    let bundledWatcher = try helperSiblingNamed("dequarantine-watcher")
    _ = try context.commands.requireSuccess(
      bundledWatcher.path,
      ["--once", downloads.path]
    )

    let owner = userName(for: userID)
    let installedWatcher = try installDequarantineWatcher(
      home: home,
      owner: owner,
      context: context
    )
    try writeDequarantineAgentPlist(
      at: agentPlist,
      watcherPath: installedWatcher.path,
      downloadsPath: downloads.path,
      owner: owner,
      context: context
    )

    _ = try context.commands.requireSuccess(
      "/bin/launchctl",
      ["bootstrap", guiTarget, agentPlist.path]
    )
  }

  private static func installDequarantineWatcher(
    home: URL,
    owner: String?,
    context: RootActionContext
  ) throws -> URL {
    let source = try helperSiblingNamed("dequarantine-watcher")
    let tweakerDirectory = home.appendingPathComponent("Library/Application Support/Tweaker")
    let directory = tweakerDirectory.appendingPathComponent("Helpers")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let destination = directory.appendingPathComponent("dequarantine-watcher")
    if FileManager.default.fileExists(atPath: destination.path) {
      try FileManager.default.removeItem(at: destination)
    }
    try FileManager.default.copyItem(at: source, to: destination)
    try FileManager.default.setAttributes(
      [.posixPermissions: 0o755],
      ofItemAtPath: destination.path
    )
    if let owner {
      _ = try context.commands.run("/usr/sbin/chown", ["-R", owner, tweakerDirectory.path])
    }
    return destination
  }

  private static func writeDequarantineAgentPlist(
    at plistURL: URL,
    watcherPath: String,
    downloadsPath: String,
    owner: String?,
    context: RootActionContext
  ) throws {
    try FileManager.default.createDirectory(
      at: plistURL.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    let plist: [String: Any] = [
      "Label": dequarantineAgentLabel,
      "ProgramArguments": [watcherPath, downloadsPath],
      "RunAtLoad": true,
      "KeepAlive": true,
      "ProcessType": "Background",
    ]
    let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
    try data.write(to: plistURL, options: .atomic)
    try FileManager.default.setAttributes(
      [.posixPermissions: 0o644],
      ofItemAtPath: plistURL.path
    )
    if let owner {
      _ = try context.commands.run("/usr/sbin/chown", [owner, plistURL.path])
    }
  }

  private static func helperSiblingNamed(_ name: String) throws -> URL {
    var buffer = [CChar](repeating: 0, count: 4096)
    var size = UInt32(buffer.count)
    guard _NSGetExecutablePath(&buffer, &size) == 0 else {
      throw RootActionError.operationFailed(
        code: "helper_path",
        message: "Unable to locate RootTweakAction."
      )
    }
    let sibling = URL(fileURLWithPath: String(cString: buffer))
      .resolvingSymlinksInPath()
      .deletingLastPathComponent()
      .appendingPathComponent(name)
    guard FileManager.default.isExecutableFile(atPath: sibling.path) else {
      throw RootActionError.operationFailed(
        code: "watcher_missing",
        message: "dequarantine-watcher is missing from the application bundle."
      )
    }
    return sibling
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

  static let openAfterRestartLabel = "com.extrememactweaker.open-after-restart"

  private static func restartSystem(
    userID: uid_t,
    appPath: String?,
    _ context: RootActionContext
  ) throws -> (String, Bool, [String: String]) {
    context.events.progress(0.15, "Disabling reopen of apps after login")
    try prepareCleanLogin(userID: userID, context: context)

    context.events.progress(0.4, "Clearing the saved relaunch list")
    try clearSavedRelaunchState(userID: userID, context: context)

    if let appPath {
      context.events.progress(0.65, "Scheduling Tweaker to open after login")
      try installOpenAfterRestartAgent(appPath: appPath, userID: userID, context: context)
    }

    context.events.progress(0.9, "Restarting macOS")
    try requestDetachedReboot(context: context)
    return ("System restart was requested", true, ["userID": String(userID)])
  }

  private static func installOpenAfterRestartAgent(
    appPath: String,
    userID: uid_t,
    context: RootActionContext
  ) throws {
    let allowed = CharacterSet.urlPathAllowed
    guard
      appPath.hasSuffix(".app"),
      appPath.count <= 1024,
      appPath.unicodeScalars.allSatisfy(allowed.contains),
      FileManager.default.fileExists(atPath: appPath)
    else {
      throw RootActionError.invalidArguments("Invalid Tweaker application path.")
    }

    guard let home = homeDirectory(for: userID) else {
      throw RootActionError.operationFailed(
        code: "missing_home",
        message: "Unable to locate the user home directory."
      )
    }

    let agents = home.appendingPathComponent("Library/LaunchAgents", isDirectory: true)
    try FileManager.default.createDirectory(at: agents, withIntermediateDirectories: true)
    let plistURL = agents.appendingPathComponent("\(openAfterRestartLabel).plist")
    let payload: [String: Any] = [
      "Label": openAfterRestartLabel,
      "LimitLoadToSessionType": "Aqua",
      "RunAtLoad": true,
      "LaunchOnlyOnce": true,
      "ProgramArguments": ["/usr/bin/open", appPath],
    ]
    let data = try PropertyListSerialization.data(fromPropertyList: payload, format: .xml, options: 0)
    try data.write(to: plistURL, options: .atomic)
    if let owner = userName(for: userID) {
      _ = try context.commands.run("/usr/sbin/chown", [owner, plistURL.path])
    }
    _ = try context.commands.run("/bin/chmod", ["644", plistURL.path])
  }

  private static func prepareCleanLogin(userID: uid_t, context: RootActionContext) throws {
    let defaults = "/usr/bin/defaults"
    let systemLoginWindow = "/Library/Preferences/com.apple.loginwindow"
    _ = try context.commands.requireSuccess(
      defaults,
      ["write", systemLoginWindow, "LoginwindowLaunchesRelaunchApps", "-bool", "false"]
    )
    _ = try context.commands.requireSuccess(
      defaults,
      ["write", systemLoginWindow, "TALLogoutSavesState", "-bool", "false"]
    )

    try writeUserDefault(
      userID: userID,
      domain: "com.apple.loginwindow",
      key: "TALLogoutSavesState",
      boolValue: false,
      context: context
    )
    try writeUserDefault(
      userID: userID,
      domain: "com.apple.loginwindow",
      key: "LoginwindowLaunchesRelaunchApps",
      boolValue: false,
      context: context
    )
    try writeUserDefault(
      userID: userID,
      domain: "NSGlobalDomain",
      key: "NSQuitAlwaysKeepsWindows",
      boolValue: false,
      context: context
    )

    _ = try context.commands.run("/usr/bin/killall", ["cfprefsd"])
  }

  private static func clearSavedRelaunchState(
    userID: uid_t,
    context: RootActionContext
  ) throws {
    _ = try context.commands.run(
      "/bin/launchctl",
      [
        "asuser", String(userID), "/usr/bin/defaults",
        "delete", "com.apple.loginwindow", "TALAppsToRelaunchAtLogin",
      ]
    )

    guard let home = homeDirectory(for: userID) else { return }

    let savedState = home.appendingPathComponent("Library/Saved Application State").path
    if FileManager.default.fileExists(atPath: savedState) {
      _ = try context.commands.requireSuccess("/bin/rm", ["-rf", "--", savedState])
    }

    let byHost = home.appendingPathComponent("Library/Preferences/ByHost").path
    if let files = try? FileManager.default.contentsOfDirectory(atPath: byHost) {
      for file in files where file.hasPrefix("com.apple.loginwindow.") && file.hasSuffix(".plist") {
        let domainPath = (byHost as NSString).appendingPathComponent(file)
        _ = try context.commands.run(
          "/usr/bin/defaults",
          ["delete", domainPath, "TALAppsToRelaunchAtLogin"]
        )
      }
    }
  }

  private static func requestDetachedReboot(context: RootActionContext) throws {
    let scriptURL = URL(fileURLWithPath: "/tmp/com.extrememactweaker.clean-restart.sh")
    let script = """
    #!/bin/sh
    sleep 2
    /sbin/shutdown -r now
    rm -f /tmp/com.extrememactweaker.clean-restart.sh
    """
    try script.write(to: scriptURL, atomically: true, encoding: .utf8)
    _ = try context.commands.requireSuccess("/bin/chmod", ["755", scriptURL.path])
    _ = try context.commands.requireSuccess(
      "/bin/sh",
      ["-c", "nohup \(scriptURL.path) >/dev/null 2>&1 &"]
    )
  }

  private static func writeUserDefault(
    userID: uid_t,
    domain: String,
    key: String,
    boolValue: Bool,
    context: RootActionContext
  ) throws {
    _ = try context.commands.requireSuccess(
      "/bin/launchctl",
      [
        "asuser", String(userID), "/usr/bin/defaults",
        "write", domain, key, "-bool", boolValue ? "true" : "false",
      ]
    )
  }

  private static func userName(for userID: uid_t) -> String? {
    guard let password = getpwuid(userID), let name = password.pointee.pw_name else {
      return nil
    }
    return String(cString: name)
  }

  private static func homeDirectory(for userID: uid_t) -> URL? {
    guard let password = getpwuid(userID), let directory = password.pointee.pw_dir else {
      return nil
    }
    return URL(fileURLWithPath: String(cString: directory), isDirectory: true)
  }

  private static func checkSystemIntegrityProtection(
    _ context: RootActionContext
  ) throws -> (String, Bool, [String: String]) {
    context.events.progress(0.5, "Checking System Integrity Protection")
    let sip = try context.commands.requireSuccess("/usr/bin/csrutil", ["status"])
    guard SystemProtectionOutputParser.systemIntegrityProtectionAllowsModifications(
      sip.standardOutput
    ) else {
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
    reportsProgress: Bool = false
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
    var started = false
    if shouldDisable {
      let serviceState = try context.commands.run(launchctl, ["print", serviceTarget])
      wasLoaded = serviceState.exitCode == 0
      if wasLoaded {
        if reportsProgress {
          context.events.progress(0.8, "Stopping the running launchd service")
        }
        _ = try context.commands.requireSuccess(launchctl, ["bootout", serviceTarget])
      }
    } else {
      if reportsProgress {
        context.events.progress(0.8, "Starting the launchd service")
      }
      started = try startLaunchService(
        label: label,
        domain: domain,
        domainTarget: domainTarget,
        serviceTarget: serviceTarget,
        context: context
      )
    }

    let changed = wasDisabled != shouldDisable || wasLoaded || started
    return (
      "\(enabled ? "Enabled" : "Disabled") service \(label)",
      changed,
      [
        "label": label,
        "domain": domain.rawValue,
        "serviceTarget": serviceTarget,
        "enabled": String(enabled),
        "stopped": String(wasLoaded),
        "started": String(started),
      ]
    )
  }

  private static func startLaunchService(
    label: String,
    domain: RootActionRequest.LaunchServiceDomain,
    domainTarget: String,
    serviceTarget: String,
    context: RootActionContext
  ) throws -> Bool {
    let launchctl = "/bin/launchctl"
    let loaded = try context.commands.run(launchctl, ["print", serviceTarget])
    if loaded.exitCode == 0 {
      return false
    }

    if let plistPath = findLaunchdPlist(label: label, domain: domain) {
      _ = try context.commands.requireSuccess(
        launchctl,
        ["bootstrap", domainTarget, plistPath]
      )
      return true
    }

    let kickstart = try context.commands.run(launchctl, ["kickstart", "-k", serviceTarget])
    return kickstart.exitCode == 0
  }

  private static func findLaunchdPlist(
    label: String,
    domain: RootActionRequest.LaunchServiceDomain
  ) -> String? {
    let roots: [String] = switch domain {
    case .system:
      [
        "/System/Library/LaunchDaemons",
        "/Library/LaunchDaemons",
        "/Library/Apple/System/Library/LaunchDaemons",
      ]
    case .user, .gui:
      [
        "/System/Library/LaunchAgents",
        "/Library/LaunchAgents",
        "/Library/Apple/System/Library/LaunchAgents",
      ]
    }

    for root in roots {
      let candidate = URL(fileURLWithPath: root)
        .appendingPathComponent("\(label).plist").path
      if FileManager.default.fileExists(atPath: candidate) {
        return candidate
      }
    }

    for root in roots {
      let rootURL = URL(fileURLWithPath: root, isDirectory: true)
      guard
        let items = try? FileManager.default.contentsOfDirectory(
          at: rootURL,
          includingPropertiesForKeys: nil
        )
      else {
        continue
      }
      for item in items where item.pathExtension == "plist" {
        if plistLabel(at: item.path) == label {
          return item.path
        }
      }
    }
    return nil
  }

  private static func plistLabel(at path: String) -> String? {
    guard
      let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
      let plist = try? PropertyListSerialization.propertyList(from: data, format: nil)
        as? [String: Any]
    else {
      return nil
    }
    return plist["Label"] as? String
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

    guard SystemProtectionOutputParser.systemIntegrityProtectionAllowsModifications(
      sip.standardOutput
    ) else {
      throw RootActionError.prerequisitesNotMet(
        "System Integrity Protection must be disabled from macOS Recovery."
      )
    }
    guard SystemProtectionOutputParser.authenticatedRootIsDisabled(
      authenticatedRoot.standardOutput
    ) else {
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
    let mountPath = try SystemVolume.validatedMountPath(mountPath)
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
    let mountPath = try SystemVolume.validatedMountPath(mountPath)
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
    let source = try SystemVolume.mountedPath(root: mountPath, systemPath: sourcePath)
    let destination = try SystemVolume.mountedPath(root: mountPath, systemPath: destinationPath)
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
    let mountedPath = try SystemVolume.mountedPath(root: mountPath, systemPath: path)
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
    let mountPath = try SystemVolume.validatedMountPath(mountPath)
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
