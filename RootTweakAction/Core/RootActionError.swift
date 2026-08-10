import Foundation

enum RootActionError: Error {
  case rootPrivilegesRequired
  case invalidArguments(String)
  case prerequisitesNotMet(String)
  case commandFailed(CommandOutput)
  case operationFailed(code: String, message: String)

  var code: String {
    switch self {
    case .rootPrivilegesRequired: "root_privileges_required"
    case .invalidArguments: "invalid_arguments"
    case .prerequisitesNotMet: "prerequisites_not_met"
    case .commandFailed: "command_failed"
    case .operationFailed(let code, _): code
    }
  }

  var message: String {
    switch self {
    case .rootPrivilegesRequired:
      "RootTweakAction must be executed with root privileges."
    case .invalidArguments(let message), .prerequisitesNotMet(let message):
      message
    case .commandFailed(let output):
      "\(output.executable) exited with status \(output.exitCode)."
    case .operationFailed(_, let message):
      message
    }
  }

  var exitCode: Int32 {
    switch self {
    case .invalidArguments: 2
    case .rootPrivilegesRequired: 3
    case .prerequisitesNotMet: 10
    case .commandFailed, .operationFailed: 20
    }
  }

  var failure: RootActionFailure {
    if case .commandFailed(let output) = self {
      return RootActionFailure(
        code: code,
        details: message,
        executable: output.executable,
        arguments: output.arguments,
        exitCode: output.exitCode,
        standardOutput: output.standardOutput,
        standardError: output.standardError
      )
    }

    return RootActionFailure(
      code: code,
      details: message,
      executable: nil,
      arguments: nil,
      exitCode: nil,
      standardOutput: nil,
      standardError: nil
    )
  }
}
