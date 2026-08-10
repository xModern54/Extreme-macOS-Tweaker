import Foundation

enum OptimizationInterpreter {
  static func compile(_ changes: [OptimizationChange]) -> ExecutionPlan {
    guard !changes.isEmpty else {
      return ExecutionPlan(changes: [], steps: [])
    }

    var applicationSteps: [ExecutionStep] = []
    var launchServiceSteps: [ExecutionStep] = []
    var securitySteps: [ExecutionStep] = []

    for change in changes {
      switch change {
      case .systemApplication(let application):
        let fileName = URL(fileURLWithPath: application.sourcePath).lastPathComponent

        switch application.action {
        case .disable:
          applicationSteps.append(
            .disableSystemApplication(
              sourcePath: application.sourcePath,
              destinationPath: SystemApplicationsScanner.disabledApplicationsDirectory
                .appendingPathComponent(fileName).path
            )
          )
        case .restore:
          applicationSteps.append(
            .restoreSystemApplication(
              sourcePath: application.sourcePath,
              destinationPath: SystemApplicationsScanner.applicationsDirectory
                .appendingPathComponent(fileName).path
            )
          )
        case .delete:
          applicationSteps.append(.deleteSystemApplication(path: application.sourcePath))
        }

      case .launchService(let service):
        launchServiceSteps.append(
          .setLaunchService(
            id: service.serviceID,
            label: service.label,
            domain: service.domain,
            enabled: service.action == .enable
          )
        )

      case .securityFeature(let feature):
        securitySteps.append(
          .setSecurityFeature(id: feature.featureID, enabled: feature.action == .enable)
        )
      }
    }

    var steps: [ExecutionStep] = []
    if !applicationSteps.isEmpty {
      steps.append(.verifySystemRequirements)
    }
    steps.append(contentsOf: launchServiceSteps)
    steps.append(contentsOf: securitySteps)

    if !applicationSteps.isEmpty {
      steps.append(.mountSystemVolume)
      steps.append(contentsOf: applicationSteps)
      steps.append(.createSystemSnapshot)
      steps.append(.unmountSystemVolume)
    }

    return ExecutionPlan(changes: changes, steps: steps)
  }
}
