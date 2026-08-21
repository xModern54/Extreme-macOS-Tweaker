import Foundation

public struct ExtractedJobs: Equatable {
  public static let schemaVersion = 1

  public let jobs: [CacheJob]

  public init(jobs: [CacheJob]) {
    self.jobs = jobs
  }

  public var isEmpty: Bool { jobs.isEmpty }
  public var cacheKeys: [String] { jobs.map(\.cacheKey) }
  public var labels: [String] { jobs.map(\.label) }

  public static func load(data: Data) throws -> ExtractedJobs {
    let object: Any
    do {
      object = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
    } catch {
      throw CleanSweepError.invalidStash("Unable to parse stash: \(error.localizedDescription)")
    }

    guard let root = object as? NSDictionary else {
      throw CleanSweepError.invalidStash("Root object must be a dictionary.")
    }

    let version = (root["schemaVersion"] as? NSNumber)?.intValue
    guard version == schemaVersion else {
      throw CleanSweepError.invalidStash(
        "Unsupported stash schemaVersion \(version.map(String.init) ?? "missing")."
      )
    }

    guard let items = root["jobs"] as? NSArray else {
      throw CleanSweepError.invalidStash("Missing jobs array.")
    }

    var jobs: [CacheJob] = []
    jobs.reserveCapacity(items.count)
    for case let item as NSDictionary in items {
      guard let cacheKey = item["cacheKey"] as? String, !cacheKey.isEmpty else {
        throw CleanSweepError.invalidStash("Job is missing cacheKey.")
      }
      guard let label = item["label"] as? String, !label.isEmpty else {
        throw CleanSweepError.invalidStash("Job \(cacheKey) is missing label.")
      }
      guard let entry = item["entry"] as? NSDictionary else {
        throw CleanSweepError.invalidStash("Job \(cacheKey) is missing entry.")
      }
      jobs.append(CacheJob(cacheKey: cacheKey, label: label, entry: entry))
    }

    if jobs.count != items.count {
      throw CleanSweepError.invalidStash("jobs array contains a non-dictionary item.")
    }

    return ExtractedJobs(jobs: jobs)
  }

  public init(contentsOf url: URL) throws {
    self = try ExtractedJobs.load(data: Data(contentsOf: url))
  }

  public func writeAtomically(to url: URL) throws {
    let data = try serialized()
    let directory = url.deletingLastPathComponent()
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let temporary = directory.appendingPathComponent(
      ".\(url.lastPathComponent).\(UUID().uuidString).tmp"
    )
    try data.write(to: temporary, options: .withoutOverwriting)
    if FileManager.default.fileExists(atPath: url.path) {
      _ = try FileManager.default.replaceItemAt(url, withItemAt: temporary)
    } else {
      try FileManager.default.moveItem(at: temporary, to: url)
    }
  }

  public func serialized() throws -> Data {
    let items: [NSDictionary] = jobs.map { job in
      [
        "cacheKey": job.cacheKey,
        "label": job.label,
        "entry": job.entry,
      ] as NSDictionary
    }
    let root: NSDictionary = [
      "schemaVersion": Self.schemaVersion,
      "jobs": items,
    ]
    return try PropertyListSerialization.data(
      fromPropertyList: root,
      format: .binary,
      options: 0
    )
  }

  public static func == (lhs: ExtractedJobs, rhs: ExtractedJobs) -> Bool {
    lhs.jobs == rhs.jobs
  }
}
