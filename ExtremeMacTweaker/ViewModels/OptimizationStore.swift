import Combine
import Foundation

enum OptimizationExecutionPhase: Equatable {
  case idle
  case authorizing
  case running
  case succeeded
  case failed
}

struct PendingChangeSummary: Identifiable {
  let id: String
  let title: String
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
  @Published private(set) var appliedLaunchServiceStates: [String: Bool] = [:]
  @Published private(set) var systemProtectionCheck: SystemProtectionCheckState = .notRequired
  @Published private(set) var restartInProgress = false

  private let persistenceURL: URL?
  private let launchServiceStatesURL: URL?

  init() {
    let applicationSupport = FileManager.default.urls(
      for: .applicationSupportDirectory,
      in: .userDomainMask
    ).first
    let tweakerDirectory = applicationSupport?
      .appendingPathComponent("Tweaker", isDirectory: true)
    persistenceURL = tweakerDirectory?.appendingPathComponent("pending-changes.json")
    launchServiceStatesURL = tweakerDirectory?
      .appendingPathComponent("launch-service-states.json")
    restoreAppliedLaunchServiceStates()
    restorePendingChanges()
  }

  var pendingCount: Int { pendingChangeSummaries.count }
  var canApply: Bool { !pendingChanges.isEmpty && !isExecuting }
  var canStartExecution: Bool {
    guard canApply else { return false }
    let plan = executionPlan
    guard plan.requiresSystemProtectionCheck else { return true }
    guard case .checked(let status) = systemProtectionCheck else { return false }
    if plan.requiresSystemIntegrityProtectionDisabled,
      !status.systemIntegrityProtectionDisabled
    {
      return false
    }
    if plan.requiresAuthenticatedRootDisabled,
      !status.authenticatedRootDisabled
    {
      return false
    }
    return true
  }
  var executionPlan: ExecutionPlan { OptimizationInterpreter.compile(pendingChanges) }
  var isExecuting: Bool { executionPhase == .authorizing || executionPhase == .running }
  var pendingChangeSummaries: [PendingChangeSummary] {
    var summaries: [PendingChangeSummary] = []
    var includedIDs: Set<String> = []

    for change in pendingChanges {
      let summary: PendingChangeSummary
      if case .launchService(let service) = change, let featureID = service.featureID {
        summary = PendingChangeSummary(
          id: "launch-feature:\(featureID)",
          title: "\(service.action == .enable ? "Enable" : "Disable") "
            + (service.featureTitle ?? featureID)
        )
      } else {
        summary = PendingChangeSummary(id: change.id, title: change.title)
      }

      if includedIDs.insert(summary.id).inserted {
        summaries.append(summary)
      }
    }
    return summaries
  }

  func presentReview() {
    resetExecution()
    systemProtectionCheck = executionPlan.requiresSystemProtectionCheck ? .checking : .notRequired
    isReviewPresented = true
    Task { await refreshSystemProtectionStatus() }
  }

  func refreshSystemProtectionStatus() async {
    guard executionPlan.requiresSystemProtectionCheck else {
      systemProtectionCheck = .notRequired
      return
    }
    systemProtectionCheck = .checking
    systemProtectionCheck = await SystemProtectionChecker.check()
  }

  func applyPendingChanges() async {
    guard canStartExecution else { return }

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

      recordAppliedLaunchServiceChanges(plan.changes)
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
    restartInProgress = false
  }

  func restartSystemWithoutReopeningApplications() async {
    guard executionPhase == .succeeded, !restartInProgress else { return }
    restartInProgress = true
    executionMessage = "Waiting for administrator authorization to restart"

    let loginWindowDefaults = UserDefaults(suiteName: "com.apple.loginwindow")
    loginWindowDefaults?.set(false, forKey: "TALLogoutSavesState")
    loginWindowDefaults?.set(false, forKey: "LoginwindowLaunchesRelaunchApps")
    loginWindowDefaults?.synchronize()

    do {
      let session = try PrivilegedExecutionSession()
      try await Task.detached(priority: .userInitiated) {
        try session.authorize()
      }.value
      for try await event in session.events(arguments: ["restart-system"]) {
        executionMessage = event.message
      }
    } catch {
      restartInProgress = false
      executionError = error.localizedDescription
      executionMessage = "Unable to restart macOS"
      executionLog.append(error.localizedDescription)
    }
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

  func setLaunchServices(
    _ services: [TweakCatalogService],
    enabled: Bool,
    defaultEnabled: Bool,
    featureID: String,
    featureTitle: String
  ) {
    let action: LaunchServiceChange.Action = enabled ? .enable : .disable
    for service in services {
      let baselineEnabled = appliedLaunchServiceStates[service.id] ?? defaultEnabled
      if enabled == baselineEnabled {
        pendingChanges.removeAll { $0.id == "launch-service:\(service.id)" }
      } else {
        upsert(
          .launchService(
            LaunchServiceChange(
              serviceID: service.id,
              label: service.label,
              domain: service.domain,
              featureID: featureID,
              featureTitle: featureTitle,
              action: action
            )
          ),
          persist: false
        )
      }
    }
    persistPendingChanges()
  }

  func launchServicesAreEnabled(
    _ services: [TweakCatalogService],
    defaultEnabled: Bool
  ) -> Bool {
    let serviceIDs = Set(services.map(\.id))
    guard !serviceIDs.isEmpty else { return defaultEnabled }

    let pendingStates = pendingChanges.compactMap { change -> Bool? in
      guard
        case .launchService(let service) = change,
        serviceIDs.contains(service.serviceID)
      else {
        return nil
      }
      return service.action == .enable
    }
    if pendingStates.count == serviceIDs.count, let first = pendingStates.first,
      pendingStates.allSatisfy({ $0 == first })
    {
      return first
    }

    let baselineStates = services.map {
      appliedLaunchServiceStates[$0.id] ?? defaultEnabled
    }
    return baselineStates.allSatisfy { $0 }
  }

  func reconcileLegacyLaunchFeature(
    _ feature: TweakCatalogFeature,
    services: [TweakCatalogService]
  ) {
    let serviceIDs = Set(services.map(\.id))
    let hasLegacyChanges = pendingChanges.contains { change in
      guard case .launchService(let service) = change else { return false }
      return serviceIDs.contains(service.serviceID) && service.featureID == nil
    }
    guard hasLegacyChanges else { return }

    let userID = getuid()
    var disabledLabelsByDomain: [TweakCatalogService.Domain: Set<String>] = [:]
    for domain in Set(services.map(\.domain)) {
      let target = switch domain {
      case .system: "system"
      case .user: "user/\(userID)"
      case .gui: "gui/\(userID)"
      }
      if let labels = launchdDisabledLabels(in: target) {
        disabledLabelsByDomain[domain] = labels
      }
    }

    for service in services {
      guard
        let index = pendingChanges.firstIndex(where: { change in
          guard case .launchService(let pendingService) = change else { return false }
          return pendingService.serviceID == service.id && pendingService.featureID == nil
        }),
        case .launchService(let pendingService) = pendingChanges[index]
      else {
        continue
      }

      if let disabledLabels = disabledLabelsByDomain[service.domain] {
        let currentlyEnabled = !disabledLabels.contains(service.label)
        appliedLaunchServiceStates[service.id] = currentlyEnabled
        if (pendingService.action == .enable) == currentlyEnabled {
          pendingChanges.remove(at: index)
          continue
        }
      }

      pendingChanges[index] = .launchService(
        LaunchServiceChange(
          serviceID: service.id,
          label: service.label,
          domain: service.domain,
          featureID: feature.id,
          featureTitle: feature.localizedTitle,
          action: pendingService.action
        )
      )
    }
    persistPendingChanges()
    persistAppliedLaunchServiceStates()
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

  private func recordAppliedLaunchServiceChanges(_ changes: [OptimizationChange]) {
    var changed = false
    for change in changes {
      guard case .launchService(let service) = change else { continue }
      appliedLaunchServiceStates[service.serviceID] = service.action == .enable
      changed = true
    }
    if changed {
      persistAppliedLaunchServiceStates()
    }
  }

  private func restoreAppliedLaunchServiceStates() {
    guard
      let launchServiceStatesURL,
      let data = try? Data(contentsOf: launchServiceStatesURL),
      let decoded = try? JSONDecoder().decode([String: Bool].self, from: data)
    else {
      return
    }
    appliedLaunchServiceStates = decoded
  }

  private func persistAppliedLaunchServiceStates() {
    guard let launchServiceStatesURL else { return }

    do {
      try FileManager.default.createDirectory(
        at: launchServiceStatesURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )
      let data = try JSONEncoder().encode(appliedLaunchServiceStates)
      try data.write(to: launchServiceStatesURL, options: .atomic)
    } catch {
      // The next launch falls back to catalog defaults if this cache cannot be saved.
    }
  }

  private func launchdDisabledLabels(in domainTarget: String) -> Set<String>? {
    let process = Process()
    let outputPipe = Pipe()
    process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
    process.arguments = ["print-disabled", domainTarget]
    process.standardOutput = outputPipe
    process.standardError = FileHandle.nullDevice

    do {
      try process.run()
      let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
      process.waitUntilExit()
      guard process.terminationStatus == 0 else { return nil }

      let output = String(decoding: data, as: UTF8.self)
      return Set(output.split(separator: "\n").compactMap { line in
        guard line.contains("=> disabled") else { return nil }
        let parts = line.split(separator: "\"")
        return parts.count >= 2 ? String(parts[1]) : nil
      })
    } catch {
      return nil
    }
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
