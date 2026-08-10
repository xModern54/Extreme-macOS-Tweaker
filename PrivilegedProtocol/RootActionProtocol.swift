import Foundation

enum RootActionEventType: String, Codable, Sendable {
  case started
  case progress
  case completed
  case failed
}

struct RootActionEvent: Codable, Sendable {
  let type: RootActionEventType
  let action: String
  let message: String
  let fraction: Double?
  let result: RootActionResult?
  let failure: RootActionFailure?
}

struct RootActionResult: Codable, Sendable {
  let changed: Bool
  let values: [String: String]
}

struct RootActionFailure: Codable, Sendable {
  let code: String
  let details: String?
  let executable: String?
  let arguments: [String]?
  let exitCode: Int32?
  let standardOutput: String?
  let standardError: String?
}
