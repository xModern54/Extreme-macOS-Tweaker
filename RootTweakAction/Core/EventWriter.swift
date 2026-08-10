import Foundation

final class EventWriter {
  private let encoder = JSONEncoder()
  private let output = FileHandle.standardOutput
  private(set) var action = "unknown"

  func started(action: String, message: String) {
    self.action = action
    write(type: .started, message: message)
  }

  func progress(_ fraction: Double? = nil, _ message: String) {
    write(type: .progress, message: message, fraction: fraction)
  }

  func completed(message: String, changed: Bool, values: [String: String] = [:]) {
    write(
      type: .completed,
      message: message,
      result: RootActionResult(changed: changed, values: values)
    )
  }

  func failed(_ error: RootActionError) {
    write(type: .failed, message: error.message, failure: error.failure)
  }

  private func write(
    type: RootActionEventType,
    message: String,
    fraction: Double? = nil,
    result: RootActionResult? = nil,
    failure: RootActionFailure? = nil
  ) {
    let event = RootActionEvent(
      type: type,
      action: action,
      message: message,
      fraction: fraction,
      result: result,
      failure: failure
    )

    guard let data = try? encoder.encode(event) else { return }
    output.write(data)
    output.write(Data([0x0A]))
    fflush(stdout)
  }
}
