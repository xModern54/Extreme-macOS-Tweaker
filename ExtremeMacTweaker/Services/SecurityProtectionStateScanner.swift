import Foundation

enum SecurityProtectionStateScanner {
  static func scan(userID: uid_t) async -> [String: Bool] {
    await Task.detached(priority: .utility) {
      var states: [String: Bool] = [:]

      for protection in SecurityProtectionCatalog.protections {
        switch protection.kind {
        case .gatekeeper:
          if let output = commandOutput(
            "/usr/sbin/spctl",
            ["--status"],
            acceptedExitCodes: [0, 1]
          ) {
            states[protection.id] = output.localizedCaseInsensitiveContains("enabled")
          }

        case .launchServices:
          let serviceStates = scanServices(protection.services, userID: userID)
          if !serviceStates.isEmpty {
            states[protection.id] = serviceStates.contains(true)
          }
        }
      }

      return states
    }.value
  }

  private static func scanServices(
    _ services: [SecurityProtectionService],
    userID: uid_t
  ) -> [Bool] {
    let servicesByDomain = Dictionary(grouping: services, by: \.domain)
    var states: [Bool] = []

    for (domain, domainServices) in servicesByDomain {
      let target = domainTarget(domain, userID: userID)
      guard
        let disabledOutput = commandOutput("/bin/launchctl", ["print-disabled", target]),
        let domainOutput = commandOutput("/bin/launchctl", ["print", target])
      else {
        continue
      }

      let disabledLabels = parseDisabledLabels(disabledOutput)
      let loadedLabels = parseLoadedLabels(domainOutput)
      states.append(contentsOf: domainServices.map { service in
        !disabledLabels.contains(service.label) || loadedLabels.contains(service.label)
      })
    }
    return states
  }

  private static func domainTarget(
    _ domain: SecurityProtectionService.Domain,
    userID: uid_t
  ) -> String {
    switch domain {
    case .system: "system"
    case .user: "user/\(userID)"
    case .gui: "gui/\(userID)"
    }
  }

  private static func commandOutput(
    _ executable: String,
    _ arguments: [String],
    acceptedExitCodes: Set<Int32> = [0]
  ) -> String? {
    let process = Process()
    let outputPipe = Pipe()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    process.standardOutput = outputPipe
    process.standardError = outputPipe

    do {
      try process.run()
      let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
      process.waitUntilExit()
      guard acceptedExitCodes.contains(process.terminationStatus) else { return nil }
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

  private static func parseLoadedLabels(_ output: String) -> Set<String> {
    Set(output.split(separator: "\n").compactMap { line in
      let fields = line.split(whereSeparator: \.isWhitespace)
      guard fields.count >= 3, Int32(fields[0]) != nil, let label = fields.last else {
        return nil
      }
      return label.contains(".") ? String(label) : nil
    })
  }
}
