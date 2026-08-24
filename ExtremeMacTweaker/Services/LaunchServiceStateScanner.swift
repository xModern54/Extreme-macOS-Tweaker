import Foundation

struct LaunchServiceRuntimeState: Equatable, Sendable {
  let launchctlDisabled: Bool
  let cleanSweepHidden: Bool
  let isLoaded: Bool
  let isRunning: Bool
  let kind: TweakCatalogService.Kind

  var isPersistentlyDisabled: Bool { launchctlDisabled || cleanSweepHidden }

  var isEffectivelyActive: Bool {
    if cleanSweepHidden {
      return isRunning
    }
    if kind == .xpcService || kind == .binary {
      return !launchctlDisabled || isRunning
    }
    return !launchctlDisabled || isLoaded
  }
}

enum LaunchServiceStateScanner {
  static func scan(
    services: [TweakCatalogService],
    userID: uid_t
  ) async -> [String: LaunchServiceRuntimeState] {
    await Task.detached(priority: .utility) {
      var states: [String: LaunchServiceRuntimeState] = [:]
      let servicesByDomain = Dictionary(grouping: services, by: \.domain)

      for (domain, domainServices) in servicesByDomain {
        let target = switch domain {
        case .system: "system"
        case .user: "user/\(userID)"
        case .gui: "gui/\(userID)"
        }
        let disabledLabels = commandOutput(["print-disabled", target]).map(parseDisabledLabels)
          ?? []
        for service in domainServices {
          let printOutput = commandOutput(["print", "\(target)/\(service.label)"])
          let processID = printOutput.flatMap(parseProcessID)
          states[service.id] = LaunchServiceRuntimeState(
            launchctlDisabled: disabledLabels.contains(service.label),
            cleanSweepHidden: isHiddenByCleanSweep(service),
            isLoaded: printOutput != nil,
            isRunning: (processID ?? 0) > 0,
            kind: service.kind
          )
        }
      }
      return states
    }.value
  }

  private static func isHiddenByCleanSweep(_ service: TweakCatalogService) -> Bool {
    let paths = service.sweepPaths.filter(CleanSweepLayout.isSweepable)
    guard !paths.isEmpty else { return false }
    return paths.contains { !FileManager.default.fileExists(atPath: $0) }
  }

  private static func commandOutput(_ arguments: [String]) -> String? {
    let process = Process()
    let outputPipe = Pipe()
    process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
    process.arguments = arguments
    process.standardOutput = outputPipe
    process.standardError = FileHandle.nullDevice

    do {
      try process.run()
      let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
      process.waitUntilExit()
      guard process.terminationStatus == 0 else { return nil }
      return String(decoding: data, as: UTF8.self)
    } catch {
      return nil
    }
  }

  private static func parseDisabledLabels(_ output: String) -> Set<String> {
    Set(output.split(separator: "\n").compactMap { line in
      guard line.contains("=> disabled") || line.contains("=> true") else { return nil }
      let parts = line.split(separator: "\"")
      return parts.count >= 2 ? String(parts[1]) : nil
    })
  }

  private static func parseProcessID(_ output: String) -> Int32? {
    for line in output.split(separator: "\n") {
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      guard trimmed.range(of: #"^pid\s*="#, options: [.regularExpression, .caseInsensitive]) != nil
      else {
        continue
      }
      let value = trimmed.split(separator: "=", maxSplits: 1).last?
        .trimmingCharacters(in: .whitespaces)
      if let value, let processID = Int32(value) {
        return processID
      }
    }
    return nil
  }
}
