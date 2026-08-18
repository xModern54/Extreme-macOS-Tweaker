import SwiftUI

@main
struct ExtremeMacTweakerApp: App {
  @StateObject private var optimizationStore = OptimizationStore()
  @StateObject private var catalogStore = TweakCatalogStore()

  var body: some Scene {
    WindowGroup {
      RootView()
        .environmentObject(optimizationStore)
        .environmentObject(catalogStore)
        .frame(minWidth: 880, minHeight: 540)
        .background(
          InitialWindowConfiguration(width: 920, height: 592)
        )
        .onAppear {
          PostRestartOpenAgent.consumeIfPresent()
          Task {
            let applications = try? await Task.detached(priority: .utility) {
              try SystemApplicationsScanner.discoverApplications()
            }.value
            if let applications {
              HiddenApplicationLaunchCleanup.retract(applications: applications)
            }
          }
        }
    }
    .defaultSize(width: 920, height: 592)
    .windowResizability(.contentMinSize)
    .windowStyle(.hiddenTitleBar)
  }
}

private enum PostRestartOpenAgent {
  static let label = "com.extrememactweaker.open-after-restart"

  static func consumeIfPresent() {
    let plist = FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent("Library/LaunchAgents/\(label).plist")
    guard FileManager.default.fileExists(atPath: plist.path) else { return }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
    process.arguments = ["bootout", "gui/\(getuid())/\(label)"]
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    try? process.run()
    process.waitUntilExit()
    try? FileManager.default.removeItem(at: plist)
  }
}
