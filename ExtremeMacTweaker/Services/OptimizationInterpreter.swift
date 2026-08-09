import Foundation

enum OptimizationInterpreter {
  static func compile(_ changes: [OptimizationChange]) -> ExecutionPlan {
    guard !changes.isEmpty else {
      return ExecutionPlan(changes: [], steps: [])
    }

    var operationSteps: [ExecutionStep] = []
    var modifiesSystemVolume = false

    for change in changes {
      switch change {
      case .systemApplication(let application):
        modifiesSystemVolume = true
        let fileName = URL(fileURLWithPath: application.sourcePath).lastPathComponent

        switch application.action {
        case .disable:
          operationSteps.append(
            .disableSystemApplication(
              sourcePath: application.sourcePath,
              destinationPath: SystemApplicationsScanner.disabledApplicationsDirectory
                .appendingPathComponent(fileName).path
            )
          )
        case .restore:
          operationSteps.append(
            .restoreSystemApplication(
              sourcePath: application.sourcePath,
              destinationPath: SystemApplicationsScanner.applicationsDirectory
                .appendingPathComponent(fileName).path
            )
          )
        case .delete:
          operationSteps.append(.deleteSystemApplication(path: application.sourcePath))
        }

      case .launchService(let service):
        operationSteps.append(
          .setLaunchService(id: service.serviceID, enabled: service.action == .enable)
        )

      case .securityFeature(let feature):
        operationSteps.append(
          .setSecurityFeature(id: feature.featureID, enabled: feature.action == .enable)
        )
      }
    }

    var steps: [ExecutionStep] = [.verifySystemRequirements]
    if modifiesSystemVolume {
      steps.append(.mountSystemVolume)
    }
    steps.append(contentsOf: operationSteps)
    if modifiesSystemVolume {
      steps.append(.createSystemSnapshot)
    }

    return ExecutionPlan(changes: changes, steps: steps)
  }
}
