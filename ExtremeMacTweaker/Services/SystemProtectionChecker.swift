import Foundation

struct SystemProtectionStatus: Equatable, Sendable {
  let systemIntegrityProtectionDisabled: Bool
  let authenticatedRootDisabled: Bool

  var requirementsSatisfied: Bool {
    systemIntegrityProtectionDisabled && authenticatedRootDisabled
  }
}

enum SystemProtectionCheckState: Equatable, Sendable {
  case notRequired
  case checking
  case checked(SystemProtectionStatus)
  case failed(String)
}

enum SystemProtectionChecker {
  static func check() async -> SystemProtectionCheckState {
    await Task.detached(priority: .userInitiated) {
      do {
        let sip = try output(of: "/usr/bin/csrutil", arguments: ["status"])
        let authenticatedRoot = try output(
          of: "/usr/bin/csrutil",
          arguments: ["authenticated-root", "status"]
        )
        return .checked(
          SystemProtectionStatus(
            systemIntegrityProtectionDisabled: sip.localizedCaseInsensitiveContains("disabled"),
            authenticatedRootDisabled: authenticatedRoot.localizedCaseInsensitiveContains(
              "disabled"
            )
          )
        )
      } catch {
        return .failed(error.localizedDescription)
      }
    }.value
  }

  private static func output(of executable: String, arguments: [String]) throws -> String {
    let process = Process()
    let outputPipe = Pipe()
    let errorPipe = Pipe()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    process.standardOutput = outputPipe
    process.standardError = errorPipe

    try process.run()
    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
      let details = String(decoding: errorData, as: UTF8.self)
        .trimmingCharacters(in: .whitespacesAndNewlines)
      throw SystemProtectionCheckError.commandFailed(
        details.isEmpty ? "csrutil exited with status \(process.terminationStatus)." : details
      )
    }
    return String(decoding: outputData, as: UTF8.self)
  }
}

private enum SystemProtectionCheckError: LocalizedError {
  case commandFailed(String)

  var errorDescription: String? {
    switch self {
    case .commandFailed(let message): message
    }
  }
}
