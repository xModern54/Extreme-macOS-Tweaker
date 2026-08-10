import Foundation
import Security

enum PrivilegedExecutionError: LocalizedError {
  case helperNotFound
  case authorization(OSStatus)
  case launch(OSStatus)
  case invalidHelperOutput(String)
  case missingFinalResult
  case helperFailure(RootActionFailure, String)
  case unsupportedStep(String)

  var errorDescription: String? {
    switch self {
    case .helperNotFound:
      "RootTweakAction is missing from the application bundle."
    case .authorization(let status):
      SecCopyErrorMessageString(status, nil) as String?
        ?? "Authorization failed with status \(status)."
    case .launch(let status):
      SecCopyErrorMessageString(status, nil) as String?
        ?? "Unable to launch RootTweakAction (\(status))."
    case .invalidHelperOutput(let line):
      "RootTweakAction returned invalid output: \(line)"
    case .missingFinalResult:
      "RootTweakAction exited without returning a final result."
    case .helperFailure(_, let message):
      message
    case .unsupportedStep(let description):
      "Execution is not implemented for: \(description)."
    }
  }
}

final class PrivilegedExecutionSession: @unchecked Sendable {
  let helperURL: URL
  private var authorization: AuthorizationRef?

  init() throws {
    guard
      let resourceURL = Bundle.main.resourceURL,
      case let helperURL = resourceURL.appendingPathComponent("Helpers/RootTweakAction"),
      FileManager.default.isExecutableFile(atPath: helperURL.path)
    else {
      throw PrivilegedExecutionError.helperNotFound
    }
    self.helperURL = helperURL

    let status = AuthorizationCreate(nil, nil, [], &authorization)
    guard status == errAuthorizationSuccess else {
      throw PrivilegedExecutionError.authorization(status)
    }
  }

  deinit {
    if let authorization {
      AuthorizationFree(authorization, [])
    }
  }

  func authorize() throws {
    guard let authorization else {
      throw PrivilegedExecutionError.authorization(errAuthorizationInvalidRef)
    }

    let status = kAuthorizationRightExecute.withCString { rightName in
      helperURL.path.withCString { helperPath in
        var item = AuthorizationItem(
          name: rightName,
          valueLength: strlen(helperPath),
          value: UnsafeMutableRawPointer(mutating: helperPath),
          flags: 0
        )

        return withUnsafeMutablePointer(to: &item) { itemPointer in
          var rights = AuthorizationRights(count: 1, items: itemPointer)
          let flags: AuthorizationFlags = [
            .interactionAllowed,
            .extendRights,
            .preAuthorize,
          ]
          return AuthorizationCopyRights(authorization, &rights, nil, flags, nil)
        }
      }
    }

    guard status == errAuthorizationSuccess else {
      throw PrivilegedExecutionError.authorization(status)
    }
  }

  func events(arguments: [String]) -> AsyncThrowingStream<RootActionEvent, Error> {
    AsyncThrowingStream { continuation in
      DispatchQueue.global(qos: .userInitiated).async { [self] in
        do {
          try execute(arguments: arguments, continuation: continuation)
        } catch {
          continuation.finish(throwing: error)
        }
      }
    }
  }

  private func execute(
    arguments: [String],
    continuation: AsyncThrowingStream<RootActionEvent, Error>.Continuation
  ) throws {
    guard let authorization else {
      throw PrivilegedExecutionError.authorization(errAuthorizationInvalidRef)
    }

    var cArguments: [UnsafeMutablePointer<CChar>?] = arguments.map { strdup($0) }
    cArguments.append(nil)
    defer {
      for argument in cArguments where argument != nil { free(argument) }
    }

    var pipe: UnsafeMutablePointer<FILE>?
    let status = helperURL.path.withCString { helperPath in
      cArguments.withUnsafeMutableBufferPointer { buffer in
        EMTAuthorizationExecuteWithPrivileges(
          authorization,
          helperPath,
          UnsafePointer(buffer.baseAddress!),
          &pipe
        )
      }
    }

    guard status == errAuthorizationSuccess, let pipe else {
      throw PrivilegedExecutionError.launch(status)
    }
    defer { fclose(pipe) }

    let decoder = JSONDecoder()
    var linePointer: UnsafeMutablePointer<CChar>?
    var capacity = 0
    var receivedFinalEvent = false
    defer { free(linePointer) }

    while true {
      let length = getline(&linePointer, &capacity, pipe)
      guard length > 0, let linePointer else { break }

      let data = Data(bytes: linePointer, count: length)
      let line = String(decoding: data, as: UTF8.self)
        .trimmingCharacters(in: .whitespacesAndNewlines)
      guard !line.isEmpty else { continue }

      let event: RootActionEvent
      do {
        event = try decoder.decode(RootActionEvent.self, from: Data(line.utf8))
      } catch {
        throw PrivilegedExecutionError.invalidHelperOutput(line)
      }

      continuation.yield(event)
      if event.type == .completed {
        receivedFinalEvent = true
      } else if event.type == .failed, let failure = event.failure {
        throw PrivilegedExecutionError.helperFailure(failure, event.message)
      }
    }

    guard receivedFinalEvent else {
      throw PrivilegedExecutionError.missingFinalResult
    }
    continuation.finish()
  }
}
