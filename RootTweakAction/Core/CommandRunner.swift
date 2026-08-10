import Foundation

struct CommandOutput: Sendable {
  let executable: String
  let arguments: [String]
  let exitCode: Int32
  let standardOutput: String
  let standardError: String
  let standardOutputData: Data
}

struct CommandRunner: Sendable {
  func run(_ executable: String, _ arguments: [String]) throws -> CommandOutput {
    let process = Process()
    let standardOutputPipe = Pipe()
    let standardErrorPipe = Pipe()

    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    process.standardOutput = standardOutputPipe
    process.standardError = standardErrorPipe

    do {
      try process.run()
    } catch {
      throw RootActionError.operationFailed(
        code: "process_launch_failed",
        message: "Unable to launch \(executable): \(error.localizedDescription)"
      )
    }

    let outputData = standardOutputPipe.fileHandleForReading.readDataToEndOfFile()
    let errorData = standardErrorPipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()

    return CommandOutput(
      executable: executable,
      arguments: arguments,
      exitCode: process.terminationStatus,
      standardOutput: String(decoding: outputData, as: UTF8.self)
        .trimmingCharacters(in: .whitespacesAndNewlines),
      standardError: String(decoding: errorData, as: UTF8.self)
        .trimmingCharacters(in: .whitespacesAndNewlines),
      standardOutputData: outputData
    )
  }

  func requireSuccess(_ executable: String, _ arguments: [String]) throws -> CommandOutput {
    let output = try run(executable, arguments)
    guard output.exitCode == 0 else {
      throw RootActionError.commandFailed(output)
    }
    return output
  }
}
