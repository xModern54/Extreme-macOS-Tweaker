import CleanSweepCore
import XCTest

final class CleanSweepTests: XCTestCase {
  private var fixture: LaunchdServiceCache!
  private var scratch: URL!

  override func setUpWithError() throws {
    try super.setUpWithError()
    fixture = try LaunchdServiceCache(contentsOf: Self.fixtureURL)
    scratch = FileManager.default.temporaryDirectory
      .appendingPathComponent("CleanSweepTests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
  }

  override func tearDownWithError() throws {
    if let scratch {
      try? FileManager.default.removeItem(at: scratch)
    }
    try super.tearDownWithError()
  }

  func testFixtureLoadsWithExpectedSchema() throws {
    XCTAssertEqual(fixture.versionNumber, 7)
    XCTAssertEqual(fixture.jobCount, 918)
    XCTAssertEqual(fixture.uniqueLabelCount, 903)
    XCTAssertNotNil(fixture.job(cacheKey: "/System/Library/LaunchDaemons/com.apple.CSCSupportd.plist"))
    XCTAssertEqual(fixture.jobs(label: "com.apple.cloudd").count, 2)
  }

  func testRoundTripRewritePreservesStructure() throws {
    let rewritten = try LaunchdServiceCache(data: fixture.serialized())
    XCTAssertTrue(fixture.launchDaemons.isEqual(rewritten.launchDaemons))
    XCTAssertTrue(untouchedSectionsEqual(fixture, rewritten))
    XCTAssertEqual(CacheDiff.compare(before: fixture, after: rewritten).isEmpty, true)
  }

  func testNeutralizeCSCSupportdRemovesOnlyThatJob() throws {
    let (after, extracted) = try fixture.neutralize(selectors: [.label("com.apple.CSCSupportd")])
    XCTAssertEqual(extracted.jobs.count, 1)
    XCTAssertEqual(extracted.jobs[0].label, "com.apple.CSCSupportd")
    XCTAssertEqual(
      extracted.jobs[0].cacheKey,
      "/System/Library/LaunchDaemons/com.apple.CSCSupportd.plist"
    )
    XCTAssertEqual(after.jobCount, fixture.jobCount - 1)
    XCTAssertTrue(after.jobs(label: "com.apple.CSCSupportd").isEmpty)
    XCTAssertTrue(untouchedSectionsEqual(fixture, after))

    let diff = CacheDiff.compare(before: fixture, after: after)
    XCTAssertEqual(diff.removed.map(\.label), ["com.apple.CSCSupportd"])
    XCTAssertTrue(diff.added.isEmpty)
    XCTAssertTrue(diff.changed.isEmpty)
    XCTAssertTrue(diff.mutatedTopLevelKeys.isEmpty)
  }

  func testNeutralizeThenRestoreMatchesOriginalJobs() throws {
    let (cut, extracted) = try fixture.neutralize(selectors: [.label("com.apple.CSCSupportd")])
    let restored = try cut.restore(extracted)
    XCTAssertTrue(fixture.launchDaemons.isEqual(restored.launchDaemons))
    XCTAssertTrue(untouchedSectionsEqual(fixture, restored))
    XCTAssertTrue(CacheDiff.compare(before: fixture, after: restored).isEmpty)
  }

  func testNeutralizeDuplicateLabelRemovesBothCacheKeys() throws {
    let (after, extracted) = try fixture.neutralize(selectors: [.label("com.apple.cloudd")])
    XCTAssertEqual(extracted.jobs.count, 2)
    XCTAssertEqual(Set(extracted.jobs.map(\.label)), ["com.apple.cloudd"])
    XCTAssertEqual(after.jobCount, fixture.jobCount - 2)
    XCTAssertTrue(after.jobs(label: "com.apple.cloudd").isEmpty)

    let restored = try after.restore(extracted)
    XCTAssertTrue(fixture.launchDaemons.isEqual(restored.launchDaemons))
  }

  func testNeutralizeBatchIsOnePass() throws {
    let selectors: [JobSelector] = [
      .label("com.apple.CSCSupportd"),
      .label("com.apple.cloudd"),
      .label("com.apple.backgroundtaskmanagementd"),
    ]
    let (after, extracted) = try fixture.neutralize(selectors: selectors)
    XCTAssertEqual(extracted.jobs.count, 4)
    XCTAssertEqual(after.jobCount, fixture.jobCount - 4)

    let diff = CacheDiff.compare(before: fixture, after: after)
    XCTAssertEqual(diff.removed.count, 4)
    XCTAssertTrue(diff.added.isEmpty)
    XCTAssertTrue(diff.changed.isEmpty)
    XCTAssertTrue(diff.mutatedTopLevelKeys.isEmpty)
    XCTAssertTrue(untouchedSectionsEqual(fixture, after))
  }

  func testNeutralizeByCacheKeyIsSurgical() throws {
    let key = "/System/Library/LaunchAgents/com.apple.cloudd.plist"
    let (after, extracted) = try fixture.neutralize(selectors: [.cacheKey(key)])
    XCTAssertEqual(extracted.jobs.count, 1)
    XCTAssertEqual(extracted.jobs[0].cacheKey, key)
    XCTAssertEqual(after.jobs(label: "com.apple.cloudd").count, 1)
    XCTAssertNotNil(
      after.job(cacheKey: "/System/Library/LaunchDaemons/com.apple.cloudd.plist")
    )
  }

  func testMissingLabelThrows() {
    XCTAssertThrowsError(
      try fixture.neutralize(selectors: [.label("com.example.does-not-exist")])
    ) { error in
      guard case CleanSweepError.jobNotFound = error else {
        return XCTFail("expected jobNotFound, got \(error)")
      }
    }
  }

  func testForbiddenLabelThrows() {
    XCTAssertThrowsError(
      try fixture.neutralize(selectors: [.label("com.apple.WindowServer")])
    ) { error in
      guard case CleanSweepError.forbiddenLabel(let label) = error else {
        return XCTFail("expected forbiddenLabel, got \(error)")
      }
      XCTAssertEqual(label, "com.apple.WindowServer")
    }
    XCTAssertEqual(fixture.jobs(label: "com.apple.WindowServer").count, 1)
  }

  func testRestoreCollisionThrows() throws {
    let (_, extracted) = try fixture.neutralize(selectors: [.label("com.apple.CSCSupportd")])
    XCTAssertThrowsError(try fixture.restore(extracted)) { error in
      guard case CleanSweepError.restoreCollision = error else {
        return XCTFail("expected restoreCollision, got \(error)")
      }
    }
  }

  func testStashRoundTripPreservesJobDictionaries() throws {
    let (_, extracted) = try fixture.neutralize(
      selectors: [.label("com.apple.CSCSupportd"), .label("com.apple.cloudd")]
    )
    let stashURL = scratch.appendingPathComponent("stash.plist")
    try extracted.writeAtomically(to: stashURL)
    let loaded = try ExtractedJobs(contentsOf: stashURL)
    XCTAssertEqual(extracted, loaded)
    XCTAssertTrue(extracted.jobs[0].entry.isEqual(loaded.jobs[0].entry))
  }

  func testWrittenCacheReloadsAndDiffsCleanly() throws {
    let (after, extracted) = try fixture.neutralize(selectors: [.label("com.apple.CSCSupportd")])
    let outURL = scratch.appendingPathComponent("launchd.cut.plist")
    let stashURL = scratch.appendingPathComponent("stash.plist")
    try after.writeAtomically(to: outURL)
    try extracted.writeAtomically(to: stashURL)

    let reloaded = try LaunchdServiceCache(contentsOf: outURL)
    let diff = CacheDiff.compare(before: fixture, after: reloaded)
    XCTAssertEqual(diff.removed.map(\.label), ["com.apple.CSCSupportd"])
    XCTAssertTrue(diff.mutatedTopLevelKeys.isEmpty)

    let restored = try reloaded.restore(try ExtractedJobs(contentsOf: stashURL))
    XCTAssertTrue(fixture.launchDaemons.isEqual(restored.launchDaemons))
  }

  func testEmptySelectorThrows() {
    XCTAssertThrowsError(try fixture.neutralize(selectors: [])) { error in
      guard case CleanSweepError.invalidSelector = error else {
        return XCTFail("expected invalidSelector, got \(error)")
      }
    }
  }

  private func untouchedSectionsEqual(_ lhs: LaunchdServiceCache, _ rhs: LaunchdServiceCache) -> Bool {
    for key in LaunchdServiceCache.requiredTopLevelKeys where key != LaunchdServiceCache.launchDaemonsKey {
      let left = lhs.root[key] as? NSObject
      let right = rhs.root[key] as? NSObject
      guard let left, let right, left.isEqual(right) else {
        return false
      }
    }
    return true
  }

  private static var fixtureURL: URL {
    URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appendingPathComponent("Fixtures/launchd.macos27.plist")
  }
}
