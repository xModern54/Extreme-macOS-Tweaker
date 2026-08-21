import Foundation

public struct LaunchdServiceCache {
  public static let expectedVersionNumber = 7
  public static let launchDaemonsKey = "LaunchDaemons"
  public static let requiredTopLevelKeys = [
    "AppExtensions",
    "LaunchDaemons",
    "AppRemovalServices",
    "SystemLibraryTreeState",
    "Symlinks",
    "VersionNumber",
  ]

  public let root: NSDictionary

  public init(data: Data) throws {
    let object: Any
    do {
      object = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
    } catch {
      throw CleanSweepError.invalidCache("Unable to parse property list: \(error.localizedDescription)")
    }
    guard let dictionary = object as? NSDictionary else {
      throw CleanSweepError.invalidCache("Root node of launchd.plist is not a dictionary.")
    }
    try Self.validate(dictionary)
    root = dictionary
  }

  public init(root: NSDictionary) throws {
    try Self.validate(root)
    self.root = root
  }

  public var versionNumber: Int {
    (root["VersionNumber"] as? NSNumber)?.intValue ?? -1
  }

  public var launchDaemons: NSDictionary {
    root[Self.launchDaemonsKey] as? NSDictionary ?? [:]
  }

  public var jobCount: Int { launchDaemons.count }

  public var allJobs: [CacheJob] {
    var jobs: [CacheJob] = []
    jobs.reserveCapacity(launchDaemons.count)
    for (key, value) in launchDaemons {
      guard let cacheKey = key as? String, let entry = value as? NSDictionary else {
        continue
      }
      let label = entry["Label"] as? String ?? ""
      jobs.append(CacheJob(cacheKey: cacheKey, label: label, entry: entry))
    }
    return jobs.sorted { $0.cacheKey < $1.cacheKey }
  }

  public func jobs(label: String) -> [CacheJob] {
    allJobs.filter { $0.label == label }
  }

  public func job(cacheKey: String) -> CacheJob? {
    guard let entry = launchDaemons[cacheKey] as? NSDictionary else {
      return nil
    }
    let label = entry["Label"] as? String ?? ""
    return CacheJob(cacheKey: cacheKey, label: label, entry: entry)
  }

  public func serialized() throws -> Data {
    try PropertyListSerialization.data(fromPropertyList: root, format: .binary, options: 0)
  }

  public init(contentsOf url: URL) throws {
    try self.init(data: Data(contentsOf: url))
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

  public var uniqueLabelCount: Int {
    Set(allJobs.map(\.label)).count
  }

  public var pathPrefixCounts: [(prefix: String, count: Int)] {
    var counts: [String: Int] = [:]
    for job in allJobs {
      let parts = job.cacheKey.split(separator: "/", omittingEmptySubsequences: true)
      let prefix = parts.prefix(3).map(String.init).joined(separator: "/")
      let key = prefix.isEmpty ? job.cacheKey : "/" + prefix
      counts[key, default: 0] += 1
    }
    return counts.sorted { lhs, rhs in
      if lhs.value != rhs.value { return lhs.value > rhs.value }
      return lhs.key < rhs.key
    }.map { (prefix: $0.key, count: $0.value) }
  }

  public func neutralize(
    selectors: [JobSelector],
    enforcePolicy: Bool = true
  ) throws -> (LaunchdServiceCache, ExtractedJobs) {
    guard !selectors.isEmpty else {
      throw CleanSweepError.invalidSelector("At least one job selector is required.")
    }

    var selected: [String: CacheJob] = [:]
    for selector in selectors {
      let matches = try resolve(selector)
      for job in matches {
        if enforcePolicy, CleanSweepPolicy.forbids(label: job.label) {
          throw CleanSweepError.forbiddenLabel(job.label)
        }
        selected[job.cacheKey] = job
      }
    }

    let extracted = ExtractedJobs(
      jobs: selected.values.sorted { $0.cacheKey < $1.cacheKey }
    )

    let nextDaemons = launchDaemons.mutableCopy() as! NSMutableDictionary
    for key in selected.keys {
      nextDaemons.removeObject(forKey: key)
    }

    let nextRoot = root.mutableCopy() as! NSMutableDictionary
    nextRoot[Self.launchDaemonsKey] = nextDaemons
    let next = try LaunchdServiceCache(root: nextRoot)
    try next.validateUntouchedSections(relativeTo: self, ignoring: [Self.launchDaemonsKey])
    return (next, extracted)
  }

  public func restore(_ extracted: ExtractedJobs) throws -> LaunchdServiceCache {
    let nextDaemons = launchDaemons.mutableCopy() as! NSMutableDictionary
    for job in extracted.jobs {
      if nextDaemons.object(forKey: job.cacheKey) != nil {
        throw CleanSweepError.restoreCollision(job.cacheKey)
      }
      nextDaemons[job.cacheKey] = job.entry
    }

    let nextRoot = root.mutableCopy() as! NSMutableDictionary
    nextRoot[Self.launchDaemonsKey] = nextDaemons
    let next = try LaunchdServiceCache(root: nextRoot)
    try next.validateUntouchedSections(relativeTo: self, ignoring: [Self.launchDaemonsKey])
    return next
  }

  public func validateUntouchedSections(
    relativeTo other: LaunchdServiceCache,
    ignoring ignoredKeys: Set<String>
  ) throws {
    let keys = Set(root.allKeys.compactMap { $0 as? String })
      .union(other.root.allKeys.compactMap { $0 as? String })
    for key in keys where !ignoredKeys.contains(key) {
      let left = root[key] as? NSObject
      let right = other.root[key] as? NSObject
      switch (left, right) {
      case (nil, nil):
        continue
      case let (left?, right?) where left.isEqual(right):
        continue
      default:
        throw CleanSweepError.invalidCache("Top-level key \(key) changed during a surgical edit.")
      }
    }
  }

  public static func validate(_ root: NSDictionary) throws {
    let keys = root.allKeys.compactMap { $0 as? String }
    for required in requiredTopLevelKeys {
      guard keys.contains(required) else {
        throw CleanSweepError.invalidCache("Missing top-level key \(required).")
      }
    }

    guard (root["VersionNumber"] as? NSNumber)?.intValue == expectedVersionNumber else {
      let value = root["VersionNumber"].map { String(describing: $0) } ?? "missing"
      throw CleanSweepError.invalidCache(
        "Unsupported VersionNumber \(value); expected \(expectedVersionNumber)."
      )
    }

    guard let launchDaemons = root[launchDaemonsKey] as? NSDictionary else {
      throw CleanSweepError.invalidCache("LaunchDaemons must be a dictionary.")
    }

    for (key, value) in launchDaemons {
      guard let cacheKey = key as? String, !cacheKey.isEmpty else {
        throw CleanSweepError.invalidCache("LaunchDaemons contains a non-string key.")
      }
      guard let entry = value as? NSDictionary else {
        throw CleanSweepError.invalidCache("Job at \(cacheKey) is not a dictionary.")
      }
      guard let label = entry["Label"] as? String, !label.isEmpty else {
        throw CleanSweepError.invalidCache("Job at \(cacheKey) is missing Label.")
      }
    }

    for section in ["AppExtensions", "SystemLibraryTreeState", "Symlinks", "AppRemovalServices"] {
      guard root[section] is NSDictionary else {
        throw CleanSweepError.invalidCache("\(section) must be a dictionary.")
      }
    }
  }

  private func resolve(_ selector: JobSelector) throws -> [CacheJob] {
    let matches: [CacheJob]
    switch selector {
    case .label(let label):
      guard !label.isEmpty else {
        throw CleanSweepError.invalidSelector("Label must not be empty.")
      }
      matches = jobs(label: label)
    case .cacheKey(let key):
      guard !key.isEmpty else {
        throw CleanSweepError.invalidSelector("Cache key must not be empty.")
      }
      matches = job(cacheKey: key).map { [$0] } ?? []
    }
    guard !matches.isEmpty else {
      throw CleanSweepError.jobNotFound(selector.description)
    }
    return matches
  }
}
