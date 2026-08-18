import Foundation

struct SavedStorageLedger: Codable, Sendable, Equatable {
  var deletedApplications: [String: Int64]
  var deblobBytes: Int64

  static let empty = SavedStorageLedger(deletedApplications: [:], deblobBytes: 0)

  var totalBytes: Int64 {
    deletedApplications.values.reduce(0, +) + deblobBytes
  }

  mutating func recordDeletedApplication(id: String, bytes: Int64) {
    guard bytes > 0, deletedApplications[id] == nil else { return }
    deletedApplications[id] = bytes
  }

  mutating func recordRemovedDebloat(bytes: Int64) {
    guard bytes > 0 else { return }
    deblobBytes += bytes
  }
}
