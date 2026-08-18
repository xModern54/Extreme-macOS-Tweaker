import Combine
import Foundation

@MainActor
final class SystemAppsViewModel: ObservableObject {
  @Published private(set) var applications: [SystemApplication] = []
  @Published private(set) var isLoading = true
  @Published private(set) var isCalculatingSizes = false
  @Published private(set) var errorMessage: String?

  private var hasLoaded = false

  func load() async {
    guard !hasLoaded else { return }
    hasLoaded = true

    do {
      let discoveredApplications = try await Task.detached(priority: .userInitiated) {
        try SystemApplicationsScanner.discoverApplications()
      }.value

      await IconCache.shared.preloadApplicationIcons(
        forPaths: discoveredApplications.map(\.url.path)
      )
      guard !Task.isCancelled else { return }

      applications = discoveredApplications
      isLoading = false
      HiddenApplicationLaunchCleanup.retract(applications: discoveredApplications)

      await calculateSizes()
    } catch {
      errorMessage = error.localizedDescription
      isLoading = false
    }
  }

  private func calculateSizes() async {
    guard !applications.isEmpty else { return }
    isCalculatingSizes = true

    for application in applications {
      guard !Task.isCancelled else { break }

      let applicationID = application.id
      let applicationURL = application.url
      let size = await Task.detached(priority: .utility) {
        SystemApplicationsScanner.allocatedSize(of: applicationURL)
      }.value

      if let index = applications.firstIndex(where: { $0.id == applicationID }) {
        applications[index].sizeInBytes = size
      }
    }

    isCalculatingSizes = false
  }
}
