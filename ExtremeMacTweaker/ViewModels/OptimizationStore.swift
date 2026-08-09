import Combine
import Foundation

@MainActor
final class OptimizationStore: ObservableObject {
  @Published private(set) var pendingChanges: [OptimizationChange] = []
  @Published var isReviewPresented = false

  private let persistenceURL: URL?

  init() {
    let applicationSupport = FileManager.default.urls(
      for: .applicationSupportDirectory,
      in: .userDomainMask
    ).first
    persistenceURL = applicationSupport?
      .appendingPathComponent("Tweaker", isDirectory: true)
      .appendingPathComponent("pending-changes.json")
    restorePendingChanges()
  }

  var pendingCount: Int { pendingChanges.count }
  var canApply: Bool { !pendingChanges.isEmpty }
  var executionPlan: ExecutionPlan { OptimizationInterpreter.compile(pendingChanges) }

  func pendingSystemApplicationAction(for applicationID: String) -> SystemApplicationAction? {
    pendingChanges.lazy.compactMap { change -> SystemApplicationChange? in
      guard case .systemApplication(let application) = change else { return nil }
      return application
    }
    .first(where: { $0.applicationID == applicationID })?
    .action
  }

  func toggle(_ action: SystemApplicationAction, for application: SystemApplication) {
    let change = OptimizationChange.systemApplication(
      SystemApplicationChange(
        applicationID: application.id,
        name: application.name,
        sourcePath: application.url.path,
        action: action
      )
    )

    if pendingSystemApplicationAction(for: application.id) == action {
      removeChange(withID: change.id)
    } else {
      upsert(change)
    }
  }

  func removeChange(withID id: String) {
    pendingChanges.removeAll { $0.id == id }
    persistPendingChanges()
  }

  func clearPendingChanges() {
    pendingChanges.removeAll()
    persistPendingChanges()
  }

  private func upsert(_ change: OptimizationChange) {
    if let index = pendingChanges.firstIndex(where: { $0.id == change.id }) {
      pendingChanges[index] = change
    } else {
      pendingChanges.append(change)
    }
    persistPendingChanges()
  }

  private func restorePendingChanges() {
    guard
      let persistenceURL,
      let data = try? Data(contentsOf: persistenceURL),
      let decoded = try? JSONDecoder().decode([OptimizationChange].self, from: data)
    else {
      return
    }
    pendingChanges = decoded
  }

  private func persistPendingChanges() {
    guard let persistenceURL else { return }

    do {
      try FileManager.default.createDirectory(
        at: persistenceURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )
      let data = try JSONEncoder().encode(pendingChanges)
      try data.write(to: persistenceURL, options: .atomic)
    } catch {
      // Pending state is useful across launches, but persistence must never block editing.
    }
  }
}
