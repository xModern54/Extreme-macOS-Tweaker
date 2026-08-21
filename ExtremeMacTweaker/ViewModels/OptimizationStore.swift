import AppKit
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
  @Published var shouldOpenRecoveryGuide = false
  @Published private(set) var executionPhase: OptimizationExecutionPhase = .idle
  @Published private(set) var executionProgress = 0.0
  @Published private(set) var executionMessage = ""
  @Published private(set) var executionLog: [String] = []
  @Published private(set) var executionError: String?
  @Published private(set) var executionRequiresReboot = false
  @Published private(set) var appliedLaunchServiceStates: [String: Bool] = [:]
  @Published private(set) var systemProtectionCheck: SystemProtectionCheckState = .notRequired
  @Published private(set) var restartInProgress = false
  @Published private(set) var observedLaunchServiceStates: [String: LaunchServiceRuntimeState] = [:]
  @Published private(set) var observedSecurityProtectionStates: [String: Bool] = [:]
  @Published private(set) var gatekeeperConfirmationRequired = false
  @Published private(set) var savedStorage = SavedStorageLedger.empty

  private let persistenceURL: URL?
  private let launchServiceStatesURL: URL?
  private let savedStorageURL: URL?
  private let dequarantineStateURL: URL?
  private var recordedDequarantineState: Bool?
  private var privilegedSession: PrivilegedExecutionSession?

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
    savedStorageURL = tweakerDirectory?.appendingPathComponent("saved-storage.json")
    dequarantineStateURL = tweakerDirectory?.appendingPathComponent("dequarantine-state.json")
    restoreAppliedLaunchServiceStates()
    restorePendingChanges()
    restoreSavedStorage()
    restoreDequarantineState()
  }

  var savedStorageBytes: Int64 { savedStorage.totalBytes }

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

  func presentRecoveryGuide() {
    isReviewPresented = false
    shouldOpenRecoveryGuide = true
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
    gatekeeperConfirmationRequired = false
    privilegedSession = nil

    do {
      let session = try PrivilegedExecutionSession()
      try await Task.detached(priority: .userInitiated) {
        try session.authorize()
      }.value

      executionPhase = .running
      executionMessage = "Authorization granted"
      executionLog.append("Authorization granted")

      let storageSavings = await resolvedStorageSavings(from: plan.changes)
      let executor = OptimizationExecutor(session: session)
      try await executor.execute(
        plan: plan,
        onStep: { [weak self] index, step in
          guard let self else { return }
          executionMessage = step.description
          if case .setLaunchService = step {
            executionLog.append(step.description)
          }
          executionProgress = Double(index) / Double(max(plan.steps.count, 1))
        },
        onEvent: { [weak self] index, event in
          guard let self else { return }
          let isLaunchServiceStep: Bool
          if case .setLaunchService = plan.steps[index] {
            isLaunchServiceStep = true
          } else {
            isLaunchServiceStep = false
          }

          if isLaunchServiceStep {
            if event.type == .failed {
              executionMessage = event.message
              executionLog.append(event.message)
            }
          } else {
            executionMessage = event.message
            executionLog.append(event.message)
          }

          if event.result?.values["requiresConfirmation"] == "true" {
            gatekeeperConfirmationRequired = true
          }

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
      recordAppliedSecurityFeatureChanges(plan.changes)
      recordAppliedStorageSavings(storageSavings)
      if plan.changes.contains(where: { change in
        if case .systemApplication = change { return true }
        return false
      }) {
        if let applications = try? SystemApplicationsScanner.discoverApplications() {
          HiddenApplicationLaunchCleanup.retract(applications: applications)
        }
      }
      clearPendingChanges()
      executionProgress = 1
      executionMessage = gatekeeperConfirmationRequired
        ? "Confirmation is required in Privacy & Security"
        : "Changes were applied successfully"
      privilegedSession = session
      executionRequiresReboot = true
      executionLog.append(
        plan.requiresReboot
          ? "Restart macOS to boot from the new system snapshot"
          : "Restart macOS to finish applying these changes"
      )
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
    gatekeeperConfirmationRequired = false
    restartInProgress = false
    privilegedSession = nil
  }

  func restartSystemWithoutReopeningApplications() async {
    guard executionPhase == .succeeded, !restartInProgress else { return }
    guard let session = privilegedSession else {
      executionError = "The administrator authorization from Apply is no longer available."
      executionMessage = "Unable to restart macOS"
      executionLog.append(executionError ?? "")
      return
    }

    restartInProgress = true
    executionMessage = "Restarting macOS with a clean login"

    do {
      for try await event in session.events(
        arguments: [
          "restart-system",
          "--user-id", String(getuid()),
          "--app-path", Bundle.main.bundlePath,
        ]
      ) {
        executionMessage = event.message
      }
      executionMessage = "Tweaker will open again after login"
      NSApplication.shared.terminate(nil)
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
        action: action,
        sizeInBytes: application.sizeInBytes ?? 0
      )
    )

    if pendingSystemApplicationAction(for: application.id) == action {
      removeChange(withID: change.id)
    } else {
      upsert(change)
    }
  }

  func securityProtectionIsEnabled(_ protection: SecurityProtection) -> Bool {
    if let pending = pendingSecurityChange(for: protection.id) {
      return pending.action == .enable
    }
    return observedSecurityProtectionStates[protection.id]
      ?? (protection.kind == .dequarantine ? false : true)
  }

  func securityTweakIsApplied(_ protection: SecurityProtection) -> Bool {
    if protection.kind == .dequarantine {
      return securityProtectionIsEnabled(protection)
    }
    return !securityProtectionIsEnabled(protection)
  }

  func setSecurityProtection(_ protection: SecurityProtection, enabled: Bool) {
    let observedEnabled = observedSecurityProtectionStates[protection.id]
      ?? (protection.kind == .dequarantine ? false : true)
    if enabled == observedEnabled {
      removeChange(withID: "security-feature:\(protection.id)")
      return
    }

    upsert(
      .securityFeature(
        SecurityFeatureChange(
          featureID: protection.id,
          action: enabled ? .enable : .disable
        )
      )
    )
  }

  func setSecurityTweak(_ protection: SecurityProtection, applied: Bool) {
    setSecurityTweak(protection, applied: applied, propagates: true)
  }

  private func setSecurityTweak(
    _ protection: SecurityProtection,
    applied: Bool,
    propagates: Bool
  ) {
    if protection.kind == .dequarantine {
      setSecurityProtection(protection, enabled: applied)
    } else {
      setSecurityProtection(protection, enabled: !applied)
    }

    guard
      propagates,
      protection.id == "system-policy",
      let whitelist = SecurityProtectionCatalog.protection(withID: "download-whitelist")
    else {
      return
    }
    setSecurityTweak(whitelist, applied: applied, propagates: false)
  }

  private func pendingSecurityChange(for featureID: String) -> SecurityFeatureChange? {
    pendingChanges.lazy.compactMap { change -> SecurityFeatureChange? in
      guard case .securityFeature(let feature) = change else { return nil }
      return feature
    }
    .first(where: { $0.featureID == featureID })
  }

  private func recordAppliedSecurityFeatureChanges(_ changes: [OptimizationChange]) {
    for change in changes {
      guard case .securityFeature(let feature) = change else { continue }
      let isEnabled = feature.action == .enable
      observedSecurityProtectionStates[feature.featureID] = isEnabled
      if feature.featureID == "download-whitelist" {
        recordedDequarantineState = isEnabled
        persistDequarantineState()
      }
    }
  }

  private func restoreDequarantineState() {
    guard
      let dequarantineStateURL,
      let data = try? Data(contentsOf: dequarantineStateURL),
      let decoded = try? JSONDecoder().decode(Bool.self, from: data)
    else {
      return
    }
    recordedDequarantineState = decoded
    observedSecurityProtectionStates["download-whitelist"] = decoded
  }

  private func persistDequarantineState() {
    guard let dequarantineStateURL, let recordedDequarantineState else { return }

    do {
      try FileManager.default.createDirectory(
        at: dequarantineStateURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )
      let data = try JSONEncoder().encode(recordedDequarantineState)
      try data.write(to: dequarantineStateURL, options: .atomic)
    } catch {
      // The next scan falls back to the live binary if this cache cannot be saved.
    }
  }

  func refreshSecurityProtectionStates() async {
    var scanned = await SecurityProtectionStateScanner.scan(userID: getuid())
    if let recordedWhitelist = recordedDequarantineState {
      scanned["download-whitelist"] = recordedWhitelist
    }
    observedSecurityProtectionStates = scanned
  }

  func isSystemComponentSelected(_ componentID: String) -> Bool {
    pendingChanges.contains { change in
      guard case .systemComponent(let component) = change else { return false }
      return component.componentID == componentID
    }
  }

  func setSystemComponent(
    _ component: SystemDebloatComponent,
    sizeInBytes: Int64,
    selected: Bool
  ) {
    let change = OptimizationChange.systemComponent(
      SystemComponentChange(
        componentID: component.id,
        title: component.title,
        sizeInBytes: sizeInBytes
      )
    )
    if selected {
      upsert(change)
    } else {
      removeChange(withID: change.id)
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
      let baselineEnabled = observedLaunchServiceStates[service.id]?.isEffectivelyActive
        ?? appliedLaunchServiceStates[service.id]
        ?? defaultEnabled
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
              action: action,
              plistPath: service.plistPath
            )
          ),
          persist: false
        )
      }
    }
    persistPendingChanges()
  }

  func canQueueRestoreAppliedLaunchTweaks(
    catalog: TweakCatalog?,
    store: TweakCatalogStore
  ) -> Bool {
    guard let catalog else { return false }
    return catalog.features.contains { feature in
      let services = store.services(for: feature)
      guard !services.isEmpty else { return false }
      let currentlyEnabled = launchServicesAreCurrentlyEnabled(
        services,
        defaultEnabled: feature.defaultEnabled
      )
      let effectiveEnabled = launchServicesAreEnabled(
        services,
        defaultEnabled: feature.defaultEnabled
      )
      return !currentlyEnabled && !effectiveEnabled
    }
  }

  func queueRestoreAppliedLaunchTweaks(using store: TweakCatalogStore) {
    guard let catalog = store.catalog else { return }
    for feature in catalog.features {
      let services = store.services(for: feature)
      guard !services.isEmpty else { continue }
      let currentlyEnabled = launchServicesAreCurrentlyEnabled(
        services,
        defaultEnabled: feature.defaultEnabled
      )
      guard !currentlyEnabled else { continue }
      setLaunchServices(
        services,
        enabled: true,
        defaultEnabled: feature.defaultEnabled,
        featureID: feature.id,
        featureTitle: feature.localizedTitle
      )
    }
  }

  func appliedTweakProgress(catalog: TweakCatalog?, store: TweakCatalogStore) -> (applied: Int, total: Int) {
    guard let catalog else { return (0, 0) }
    return (appliedFeatures(in: catalog, store: store).count, catalog.features.count)
  }

  func appliedTweakSavings(catalog: TweakCatalog?, store: TweakCatalogStore) -> (memoryMB: Int, processes: Int) {
    guard let catalog else { return (0, 0) }
    return appliedFeatures(in: catalog, store: store).reduce(into: (0, 0)) { total, feature in
      total.memoryMB += feature.impact.estimatedMemoryMB
      total.processes += feature.impact.estimatedProcessReduction
    }
  }

  private func appliedFeatures(in catalog: TweakCatalog, store: TweakCatalogStore) -> [TweakCatalogFeature] {
    catalog.features.filter { feature in
      !launchServicesAreCurrentlyEnabled(
        store.services(for: feature),
        defaultEnabled: feature.defaultEnabled
      )
    }
  }

  func launchServicesAreCurrentlyEnabled(
    _ services: [TweakCatalogService],
    defaultEnabled: Bool
  ) -> Bool {
    guard !services.isEmpty else { return defaultEnabled }
    return services.contains { service in
      observedLaunchServiceStates[service.id]?.isEffectivelyActive
        ?? appliedLaunchServiceStates[service.id]
        ?? defaultEnabled
    }
  }

  func launchServicesAreEnabled(
    _ services: [TweakCatalogService],
    defaultEnabled: Bool
  ) -> Bool {
    guard !services.isEmpty else { return defaultEnabled }

    let pendingStates = pendingChanges.reduce(into: [String: Bool]()) { states, change in
      guard case .launchService(let service) = change else { return }
      states[service.serviceID] = service.action == .enable
    }
    let effectiveStates = services.map { service in
      pendingStates[service.id]
        ?? observedLaunchServiceStates[service.id]?.isEffectivelyActive
        ?? appliedLaunchServiceStates[service.id]
        ?? defaultEnabled
    }
    return effectiveStates.contains(true)
  }

  func refreshLaunchServiceStates(_ services: [TweakCatalogService]) async {
    guard !services.isEmpty else {
      observedLaunchServiceStates = [:]
      return
    }
    observedLaunchServiceStates = await LaunchServiceStateScanner.scan(
      services: services,
      userID: getuid()
    )
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
          action: pendingService.action,
          plistPath: service.plistPath
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
    pendingChanges = decoded.filter { change in
      guard case .launchService(let service) = change else { return true }
      return service.featureID != "xprotect" && service.featureID != "gatekeeper"
    }
    if pendingChanges.count != decoded.count {
      persistPendingChanges()
    }
  }

  private func recordAppliedLaunchServiceChanges(_ changes: [OptimizationChange]) {
    var changed = false
    for change in changes {
      guard case .launchService(let service) = change else { continue }
      appliedLaunchServiceStates[service.serviceID] = service.action == .enable
      observedLaunchServiceStates.removeValue(forKey: service.serviceID)
      changed = true
    }
    if changed {
      persistAppliedLaunchServiceStates()
    }
  }

  private struct PreparedStorageSavings {
    var deletedApplications: [String: Int64] = [:]
    var deblobBytes: Int64 = 0

    var isEmpty: Bool { deletedApplications.isEmpty && deblobBytes == 0 }
  }

  private func resolvedStorageSavings(
    from changes: [OptimizationChange]
  ) async -> PreparedStorageSavings {
    var savings = PreparedStorageSavings()

    for change in changes {
      switch change {
      case .systemApplication(let application) where application.action == .delete:
        let bytes = await resolvedApplicationSize(application)
        if bytes > 0 {
          savings.deletedApplications[application.applicationID] = bytes
        }
      case .systemComponent(let component):
        savings.deblobBytes += await resolvedComponentSize(component)
      default:
        continue
      }
    }

    return savings
  }

  private func recordAppliedStorageSavings(_ savings: PreparedStorageSavings) {
    guard !savings.isEmpty else { return }

    var ledger = savedStorage
    for (applicationID, bytes) in savings.deletedApplications {
      ledger.recordDeletedApplication(id: applicationID, bytes: bytes)
    }
    ledger.recordRemovedDebloat(bytes: savings.deblobBytes)

    guard ledger != savedStorage else { return }
    savedStorage = ledger
    persistSavedStorage()
  }

  private func resolvedApplicationSize(_ application: SystemApplicationChange) async -> Int64 {
    if application.sizeInBytes > 0 {
      return application.sizeInBytes
    }

    let url = URL(fileURLWithPath: application.sourcePath)
    return await Task.detached(priority: .utility) {
      SystemApplicationsScanner.allocatedSize(of: url) ?? 0
    }.value
  }

  private func resolvedComponentSize(_ component: SystemComponentChange) async -> Int64 {
    if component.sizeInBytes > 0 {
      return component.sizeInBytes
    }

    let componentID = component.componentID
    return await Task.detached(priority: .utility) {
      SystemDebloatScanner.allocatedSize(ofComponentID: componentID)
    }.value
  }

  private func restoreSavedStorage() {
    guard
      let savedStorageURL,
      let data = try? Data(contentsOf: savedStorageURL),
      let decoded = try? JSONDecoder().decode(SavedStorageLedger.self, from: data)
    else {
      return
    }
    savedStorage = decoded
  }

  private func persistSavedStorage() {
    guard let savedStorageURL else { return }

    do {
      try FileManager.default.createDirectory(
        at: savedStorageURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )
      let data = try JSONEncoder().encode(savedStorage)
      try data.write(to: savedStorageURL, options: .atomic)
    } catch {
      // Dashboard savings stay in memory if the cache cannot be written.
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
