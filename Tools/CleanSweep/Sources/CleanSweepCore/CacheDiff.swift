import Foundation

public struct CacheDiff: Equatable {
  public let removed: [CacheJob]
  public let added: [CacheJob]
  public let changed: [ChangedJob]
  public let mutatedTopLevelKeys: [String]

  public struct ChangedJob: Equatable {
    public let cacheKey: String
    public let label: String
    public let before: NSDictionary
    public let after: NSDictionary

    public static func == (lhs: ChangedJob, rhs: ChangedJob) -> Bool {
      lhs.cacheKey == rhs.cacheKey
        && lhs.label == rhs.label
        && lhs.before.isEqual(rhs.before)
        && lhs.after.isEqual(rhs.after)
    }
  }

  public var isEmpty: Bool {
    removed.isEmpty && added.isEmpty && changed.isEmpty && mutatedTopLevelKeys.isEmpty
  }

  public var summary: String {
    var lines: [String] = []
    lines.append("removed \(removed.count)")
    lines.append("added \(added.count)")
    lines.append("changed \(changed.count)")
    if !mutatedTopLevelKeys.isEmpty {
      lines.append("mutated top-level keys: \(mutatedTopLevelKeys.joined(separator: ", "))")
    }
    for job in removed.sorted(by: { $0.cacheKey < $1.cacheKey }) {
      lines.append("- \(job.label)  \(job.cacheKey)")
    }
    for job in added.sorted(by: { $0.cacheKey < $1.cacheKey }) {
      lines.append("+ \(job.label)  \(job.cacheKey)")
    }
    for job in changed.sorted(by: { $0.cacheKey < $1.cacheKey }) {
      lines.append("~ \(job.label)  \(job.cacheKey)")
    }
    return lines.joined(separator: "\n")
  }

  public static func compare(before: LaunchdServiceCache, after: LaunchdServiceCache) -> CacheDiff {
    let beforeJobs = Dictionary(uniqueKeysWithValues: before.allJobs.map { ($0.cacheKey, $0) })
    let afterJobs = Dictionary(uniqueKeysWithValues: after.allJobs.map { ($0.cacheKey, $0) })
    let beforeKeys = Set(beforeJobs.keys)
    let afterKeys = Set(afterJobs.keys)

    let removed = beforeKeys.subtracting(afterKeys).sorted().compactMap { beforeJobs[$0] }
    let added = afterKeys.subtracting(beforeKeys).sorted().compactMap { afterJobs[$0] }

    var changed: [ChangedJob] = []
    for key in beforeKeys.intersection(afterKeys).sorted() {
      guard let left = beforeJobs[key], let right = afterJobs[key] else { continue }
      if !left.entry.isEqual(right.entry) || left.label != right.label {
        changed.append(
          ChangedJob(
            cacheKey: key,
            label: right.label,
            before: left.entry,
            after: right.entry
          )
        )
      }
    }

    var mutatedTopLevelKeys: [String] = []
    let keys = Set(before.root.allKeys.compactMap { $0 as? String })
      .union(after.root.allKeys.compactMap { $0 as? String })
    for key in keys.sorted() where key != LaunchdServiceCache.launchDaemonsKey {
      let left = before.root[key] as? NSObject
      let right = after.root[key] as? NSObject
      if left == nil && right == nil { continue }
      if let left, let right, left.isEqual(right) { continue }
      mutatedTopLevelKeys.append(key)
    }

    return CacheDiff(
      removed: removed,
      added: added,
      changed: changed,
      mutatedTopLevelKeys: mutatedTopLevelKeys
    )
  }
}
