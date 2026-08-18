import Foundation

struct LaunchServiceRuntimeState: Equatable, Sendable {
  let isPersistentlyDisabled: Bool
  let isLoaded: Bool
  let isRunning: Bool
  let kind: TweakCatalogService.Kind

  var isEffectivelyActive: Bool {
    if kind == .xpcService {
      return !isPersistentlyDisabled || isRunning
    }
    return !isPersistentlyDisabled || isLoaded
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
        guard let disabledOutput = commandOutput(["print-disabled", target]) else {
          continue
        }

        let disabledLabels = parseDisabledLabels(disabledOutput)
        for service in domainServices {
          let printOutput = commandOutput(["print", "\(target)/\(service.label)"])
          let processID = printOutput.flatMap(parseProcessID)
          states[service.id] = LaunchServiceRuntimeState(
            isPersistentlyDisabled: disabledLabels.contains(service.label),
            isLoaded: printOutput != nil,
            isRunning: (processID ?? 0) > 0,
            kind: service.kind
          )
        }
      }
      return states
    }.value
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
