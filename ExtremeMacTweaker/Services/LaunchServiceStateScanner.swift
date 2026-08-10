import Foundation

struct LaunchServiceRuntimeState: Equatable, Sendable {
  let isPersistentlyDisabled: Bool
  let isLoaded: Bool
  let isRunning: Bool

  var isEffectivelyActive: Bool {
    !isPersistentlyDisabled || isLoaded
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
        guard
          let disabledOutput = commandOutput(["print-disabled", target]),
          let domainOutput = commandOutput(["print", target])
        else {
          continue
        }

        let disabledLabels = parseDisabledLabels(disabledOutput)
        let loadedServices = parseLoadedServices(domainOutput)
        for service in domainServices {
          let processID = loadedServices[service.label]
          states[service.id] = LaunchServiceRuntimeState(
            isPersistentlyDisabled: disabledLabels.contains(service.label),
            isLoaded: processID != nil,
            isRunning: (processID ?? 0) > 0
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

  private static func parseLoadedServices(_ output: String) -> [String: Int32] {
    var services: [String: Int32] = [:]
    for line in output.split(separator: "\n") {
      let fields = line.split(whereSeparator: \.isWhitespace)
      guard
        fields.count >= 3,
        let processID = Int32(fields[0]),
        let label = fields.last,
        label.contains(".")
      else {
        continue
      }
      services[String(label)] = processID
    }
    return services
  }
}
