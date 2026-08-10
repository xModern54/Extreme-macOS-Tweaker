import Darwin
import Foundation

let events = EventWriter()

do {
  guard geteuid() == 0 else {
    throw RootActionError.rootPrivilegesRequired
  }

  let request = try RootActionRequest.parse(Array(CommandLine.arguments.dropFirst()))
  events.started(action: request.name, message: request.startMessage)
  let context = RootActionContext(events: events, commands: CommandRunner())
  let result = try RootActions.execute(request, context: context)
  events.completed(message: result.0, changed: result.1, values: result.2)
  exit(EXIT_SUCCESS)
} catch let error as RootActionError {
  events.failed(error)
  exit(error.exitCode)
} catch {
  let wrapped = RootActionError.operationFailed(
    code: "unexpected_error",
    message: error.localizedDescription
  )
  events.failed(wrapped)
  exit(wrapped.exitCode)
}
