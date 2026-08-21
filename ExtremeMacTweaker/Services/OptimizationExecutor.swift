import Foundation

@MainActor
final class OptimizationExecutor {
  private let session: PrivilegedExecutionSession
  private let mountPath = "/Volumes/SystemRW"
  private let userID = getuid()

  init(session: PrivilegedExecutionSession) {
    self.session = session
  }

  func execute(
    plan: ExecutionPlan,
    onStep: (Int, ExecutionStep) -> Void,
    onEvent: (Int, RootActionEvent) -> Void
  ) async throws {
    var volumeIsMounted = false

    do {
      for (index, step) in plan.steps.enumerated() {
        onStep(index, step)

        for try await event in session.events(arguments: try arguments(for: step)) {
          onEvent(index, event)
          if case .mountSystemVolume = step, event.type == .completed {
            volumeIsMounted = true
          }
          if case .unmountSystemVolume = step, event.type == .completed {
            volumeIsMounted = false
          }
        }
      }
    } catch {
      if volumeIsMounted {
        try? await cleanupMountedVolume()
      }
      throw error
    }
  }

  private func arguments(for step: ExecutionStep) throws -> [String] {
    switch step {
    case .verifySystemRequirements:
      ["preflight"]
    case .verifySystemIntegrityProtection:
      ["check-system-integrity-protection"]
    case .mountSystemVolume:
      ["mount-system-volume", "--mount-path", mountPath]
    case .disableSystemApplication(let source, let destination):
      [
        "disable-application",
        "--mount-path", mountPath,
        "--source", source,
        "--destination", destination,
      ]
    case .restoreSystemApplication(let source, let destination):
      [
        "restore-application",
        "--mount-path", mountPath,
        "--source", source,
        "--destination", destination,
      ]
    case .deleteSystemApplication(let path):
      ["delete-application", "--mount-path", mountPath, "--path", path]
    case .relocateDisabledApplications:
      ["relocate-disabled-applications", "--mount-path", mountPath]
    case .hideLaunchPlist(let source, let destination):
      [
        "hide-launch-plist",
        "--mount-path", mountPath,
        "--source", source,
        "--destination", destination,
      ]
    case .restoreLaunchPlist(let source, let destination):
      [
        "restore-launch-plist",
        "--mount-path", mountPath,
        "--source", source,
        "--destination", destination,
      ]
    case .createSystemSnapshot:
      ["create-snapshot", "--mount-path", mountPath]
    case .unmountSystemVolume:
      ["unmount-system-volume", "--mount-path", mountPath]
    case .setLaunchService(_, let label, let domain, let enabled):
      [
        "set-launch-service",
        "--label", label,
        "--domain", domain.rawValue,
        "--user-id", String(userID),
        "--enabled", String(enabled),
      ]
    case .setSecurityFeature(let id, let enabled):
      [
        "set-security-protection",
        "--id", id,
        "--user-id", String(userID),
        "--enabled", String(enabled),
      ]
    case .installSystemDequarantineDaemon(let downloadsPath):
      [
        "install-system-dequarantine",
        "--mount-path", mountPath,
        "--downloads", downloadsPath,
      ]
    case .removeSystemDequarantineDaemon:
      ["remove-system-dequarantine", "--mount-path", mountPath]
    case .removeSystemComponent(let id, _):
      ["remove-system-component", "--id", id]
    }
  }

  private func cleanupMountedVolume() async throws {
    for try await _ in session.events(
      arguments: ["unmount-system-volume", "--mount-path", mountPath]
    ) {}
  }
}
