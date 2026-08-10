import Combine
import Foundation

enum OptimizationExecutionPhase: Equatable {
  case idle
  case authorizing
  case running
  case succeeded
  case failed
}

@MainActor
final class OptimizationStore: ObservableObject {
  @Published private(set) var pendingChanges: [OptimizationChange] = []
  @Published var isReviewPresented = false
  @Published private(set) var executionPhase: OptimizationExecutionPhase = .idle
  @Published private(set) var executionProgress = 0.0
  @Published private(set) var executionMessage = ""
  @Published private(set) var executionLog: [String] = []
  @Published private(set) var executionError: String?
  @Published private(set) var executionRequiresReboot = false

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
  var canApply: Bool { !pendingChanges.isEmpty && !isExecuting }
  var executionPlan: ExecutionPlan { OptimizationInterpreter.compile(pendingChanges) }
  var isExecuting: Bool { executionPhase == .authorizing || executionPhase == .running }

  func presentReview() {
    resetExecution()
    isReviewPresented = true
  }

  func applyPendingChanges() async {
    guard canApply else { return }

    let plan = executionPlan
    executionRequiresReboot = plan.requiresReboot
    executionPhase = .authorizing
    executionProgress = 0
    executionMessage = "Waiting for administrator authorization"
    executionLog = ["Waiting for administrator authorization"]
    executionError = nil

    do {
      let session = try PrivilegedExecutionSession()
      try await Task.detached(priority: .userInitiated) {
        try session.authorize()
      }.value

      executionPhase = .running
      executionMessage = "Authorization granted"
      executionLog.append("Authorization granted")

      let executor = OptimizationExecutor(session: session)
      try await executor.execute(
        plan: plan,
        onStep: { [weak self] index, step in
          guard let self else { return }
          executionMessage = step.description
          executionProgress = Double(index) / Double(max(plan.steps.count, 1))
        },
        onEvent: { [weak self] index, event in
          guard let self else { return }
          executionMessage = event.message
          executionLog.append(event.message)

          let stepFraction: Double
          if event.type == .completed {
            stepFraction = 1
          } else {
            stepFraction = event.fraction ?? 0
          }
          executionProgress = (
            Double(index) + min(max(stepFraction, 0), 1)
          ) / Double(max(plan.steps.count, 1))
        }
      )

      clearPendingChanges()
      executionProgress = 1
      executionMessage = "Changes were applied successfully"
      if plan.requiresReboot {
        executionLog.append("Restart macOS to boot from the new system snapshot")
      }
      executionPhase = .succeeded
    } catch {
      executionError = error.localizedDescription
      executionMessage = "Unable to apply changes"
      executionLog.append(error.localizedDescription)
      executionPhase = .failed
    }
  }

  func resetExecution() {
    guard !isExecuting else { return }
    executionPhase = .idle
    executionProgress = 0
    executionMessage = ""
    executionLog = []
    executionError = nil
    executionRequiresReboot = false
  }

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

  func setLaunchServices(_ services: [TweakCatalogService], enabled: Bool) {
    let action: LaunchServiceChange.Action = enabled ? .enable : .disable
    for service in services {
      upsert(
        .launchService(
          LaunchServiceChange(
            serviceID: service.id,
            label: service.label,
            domain: service.domain,
            action: action
          )
        ),
        persist: false
      )
    }
    persistPendingChanges()
  }

  func pendingLaunchServiceAction(
    for services: [TweakCatalogService]
  ) -> LaunchServiceChange.Action? {
    let serviceIDs = Set(services.map(\.id))
    guard !serviceIDs.isEmpty else { return nil }

    let actions = pendingChanges.compactMap { change -> LaunchServiceChange.Action? in
      guard
        case .launchService(let service) = change,
        serviceIDs.contains(service.serviceID)
      else {
        return nil
      }
      return service.action
    }
    guard actions.count == serviceIDs.count, let first = actions.first else { return nil }
    return actions.allSatisfy { $0 == first } ? first : nil
  }

  func removeChange(withID id: String) {
    pendingChanges.removeAll { $0.id == id }
    persistPendingChanges()
  }

  func clearPendingChanges() {
    pendingChanges.removeAll()
    persistPendingChanges()
  }

  private func upsert(_ change: OptimizationChange, persist: Bool = true) {
    if let index = pendingChanges.firstIndex(where: { $0.id == change.id }) {
      pendingChanges[index] = change
    } else {
      pendingChanges.append(change)
    }
    if persist {
      persistPendingChanges()
    }
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
