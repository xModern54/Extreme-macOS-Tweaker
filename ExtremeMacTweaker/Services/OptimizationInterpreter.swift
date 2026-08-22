import Foundation

enum OptimizationInterpreter {
  static func compile(_ changes: [OptimizationChange]) -> ExecutionPlan {
    guard !changes.isEmpty else {
      return ExecutionPlan(changes: [], steps: [])
    }

    var systemVolumeSteps: [ExecutionStep] = []
    var launchctlDisableSteps: [ExecutionStep] = []
    var launchctlEnableSteps: [ExecutionStep] = []
    var securitySteps: [ExecutionStep] = []
    var componentSteps: [ExecutionStep] = []
    let downloadsPath = FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent("Downloads", isDirectory: true)
      .path

    for change in changes {
      switch change {
      case .systemApplication(let application):
        let fileName = URL(fileURLWithPath: application.sourcePath).lastPathComponent

        switch application.action {
        case .disable:
          systemVolumeSteps.append(
            .disableSystemApplication(
              sourcePath: application.sourcePath,
              destinationPath: SystemApplicationsScanner.disabledApplicationsDirectory
                .appendingPathComponent(fileName).path
            )
          )
        case .restore:
          systemVolumeSteps.append(
            .restoreSystemApplication(
              sourcePath: application.sourcePath,
              destinationPath: SystemApplicationsScanner.applicationsDirectory
                .appendingPathComponent(fileName).path
            )
          )
        case .delete:
          systemVolumeSteps.append(.deleteSystemApplication(path: application.sourcePath))
        }

      case .launchService(let service):
        let sweepPairs = service.sweepPaths.compactMap { path -> (String, String)? in
          guard let hiddenPath = CleanSweepLayout.hiddenPath(for: path) else { return nil }
          return (path, hiddenPath)
        }
        let launchctlStep = ExecutionStep.setLaunchService(
          id: service.serviceID,
          label: service.label,
          domain: service.domain,
          enabled: service.action == .enable
        )

        switch service.action {
        case .disable:
          if service.disableMethod == .cleanSweep {
            for (livePath, hiddenPath) in sweepPairs {
              systemVolumeSteps.append(
                .hideLaunchPlist(sourcePath: livePath, destinationPath: hiddenPath)
              )
            }
          } else {
            launchctlDisableSteps.append(launchctlStep)
          }

        case .enable:
          if service.disableMethod == .cleanSweep || service.healsCleanSweep {
            for (livePath, hiddenPath) in sweepPairs {
              systemVolumeSteps.append(
                .restoreLaunchPlist(sourcePath: hiddenPath, destinationPath: livePath)
              )
            }
          }
          if service.healsLaunchctl {
            launchctlEnableSteps.append(launchctlStep)
          }
        }

      case .securityFeature(let feature):
        if feature.featureID == "download-whitelist" {
          if feature.action == .enable {
            systemVolumeSteps.append(
              .installSystemDequarantineDaemon(downloadsPath: downloadsPath)
            )
          } else {
            systemVolumeSteps.append(.removeSystemDequarantineDaemon)
          }
        } else {
          securitySteps.append(
            .setSecurityFeature(id: feature.featureID, enabled: feature.action == .enable)
          )
        }

      case .systemComponent(let component):
        componentSteps.append(
          .removeSystemComponent(id: component.componentID, title: component.title)
        )
      }
    }

    let requiresSIPCheck =
      !componentSteps.isEmpty
      || !launchctlDisableSteps.isEmpty
      || securitySteps.contains { step in
        guard case .setSecurityFeature(let id, let enabled) = step, !enabled else {
          return false
        }
        return SecurityProtectionCatalog.protection(withID: id)?.requiresSIPDisabledToDisable
          ?? true
      }

    var steps: [ExecutionStep] = []
    if !systemVolumeSteps.isEmpty {
      steps.append(.verifySystemRequirements)
    } else if requiresSIPCheck {
      steps.append(.verifySystemIntegrityProtection)
    }
    steps.append(contentsOf: launchctlDisableSteps)
    steps.append(contentsOf: securitySteps)
    steps.append(contentsOf: componentSteps)

    if !systemVolumeSteps.isEmpty {
      steps.append(.mountSystemVolume)
      steps.append(.relocateDisabledApplications)
      steps.append(contentsOf: systemVolumeSteps)
      steps.append(.createSystemSnapshot)
      steps.append(.unmountSystemVolume)
    }
    steps.append(contentsOf: launchctlEnableSteps)

    return ExecutionPlan(changes: changes, steps: steps)
  }
}
