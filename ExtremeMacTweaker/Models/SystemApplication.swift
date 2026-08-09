import Foundation

struct SystemApplication: Identifiable, Sendable {
  let url: URL
  let name: String
  let bundleIdentifier: String?
  var sizeInBytes: Int64?

  var id: String { url.path }

  var formattedSize: String? {
    guard let sizeInBytes else { return nil }
    return ByteCountFormatter.string(fromByteCount: sizeInBytes, countStyle: .file)
  }
}
